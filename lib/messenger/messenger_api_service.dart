// =============================================================================
//  MessengerApiService — Wurzel der Library
// =============================================================================
//  Diese Klasse ist absichtlich ueber mehrere Dateien verteilt (per `part`).
//  Hier liegen nur: der Zustand (Felder), der Konstruktor und die statischen
//  Gruppen-REST-Endpunkte. Das Verhalten steckt in den Part-Dateien:
//
//    * messenger_api_service.connection.dart  -> Verbinden/Heartbeat/Reconnect
//    * messenger_api_service.crypto.dart      -> Ver-/Entschluesseln + Keys
//    * messenger_api_service.send.dart        -> Nachrichten senden
//    * messenger_api_service.sync.dart        -> REST-Nachsync + Speichern
//
//  Alle Part-Dateien teilen sich die Imports von hier und duerfen auf die
//  privaten Felder unten zugreifen (Privatheit gilt pro Library, nicht pro Datei).
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:sodium/sodium.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:ranked/e2ee/key_service.dart';
import '../core/token_storage.dart';
import '../core/api_client.dart';
import '../core/api_config.dart';
import '../local_data/database.dart';
import '../core/user_api_service.dart';

// ChatEvent & Co. wieder mit exportieren, damit Importer dieser Datei (UI,
// conversation.dart) die Typen weiterhin ohne extra Import sehen.
export 'chat_event.dart';
import 'chat_event.dart';

part 'messenger_api_service.connection.dart';
part 'messenger_api_service.crypto.dart';
part 'messenger_api_service.send.dart';
part 'messenger_api_service.sync.dart';

const _baseWsUrl = ApiConfig.wsUrl;
const _baseUrl = ApiConfig.baseUrl;

// Rolle eines Gruppenmitglieds, wie GET /group_chat/{id}/members sie liefert.
// Die echten Rechte prueft immer das Backend — die UI blendet damit nur
// Buttons ein/aus.
enum GroupRole {
  creator,
  admin,
  member;

  // Server schickt einen String ("creator"/"admin"/"member"). Unbekannt oder
  // fehlend -> member: im Zweifel lieber zu wenige Buttons zeigen als zu viele.
  static GroupRole parse(Object? raw) {
    for (final t in values) {
      if (t.name == raw) return t;
    }
    return member;
  }

  bool get canManage => this == creator || this == admin;
}

// Ein Eintrag der Mitgliederliste. Als typedef, damit der Record-Typ nicht an
// jeder Stelle ausgeschrieben werden muss (und nicht auseinanderlaeuft).
typedef GroupMember = ({
  int id,
  String username,
  String? avatarUrl,
  GroupRole role,
});

class MessengerApiService {
  final AppDatabase _db;
  final int _myUserId;

  MessengerApiService(this._db, this._myUserId) {
    // Die Persistenz haengt sich EINMALIG ans dauerhafte _events-Band.
    // (_persistIncoming liegt in der sync-Part-Datei.)
    _events.stream.listen(_persistIncoming);
  }

  // Cache fuer Public Keys der Chat-Partner (Server-Abruf nur einmal pro Partner).
  final Map<int, String> _partnerPubKeyCache = {};

  // Das dauerhafte "Foerderband": lebt so lange wie der Service selbst. Jede
  // einzelne WebSocket-Verbindung kippt ihre Nachrichten hier hinein, alle
  // Listener (Persistenz, UI, _awaitGroupResponse) abonnieren genau dieses Band.
  final _events = StreamController<ChatEvent>.broadcast();

  WebSocketChannel? _channel;
  // Unser Griff auf die AKTUELLE Verbindung — zum Zumachen beim disconnect().
  StreamSubscription<dynamic>? _channelSub;

  // Single-Flight fuer connect(): Solange ein Verbindungsaufbau laeuft, steht
  // hier sein Future. Jeder weitere connect()-Aufruf haengt sich an dieses
  // Future, statt einen zweiten, parallelen Aufbau zu starten. null = kein
  // Aufbau unterwegs. (Gleiches Muster wie ApiClient._refreshOnce.)
  Future<void>? _connectFuture;

  // Reconnect-Zustand (Details siehe connection-Part):
  bool _manuallyClosed =
      false; // true = absichtlich geschlossen, kein Reconnect
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // ---------------------------------------------------------------------------
  //  Statische Gruppen-REST-Endpunkte
  //  Brauchen keinen Service-Zustand, daher static. Aufruf von aussen z.B.
  //  MessengerApiService.createGroup().
  // -------------------------------------------------------------
  //
  // --------------

  // POST /group_chat/create — optional gleich mit Namen (ein Request statt
  // create + rename). Ohne Namen geht kein Body raus, wie bisher.
  static Future<int?> createGroup({String? name}) async {
    final trimmed = name?.trim();
    final hasName = trimmed != null && trimmed.isNotEmpty;
    final response = await ApiClient.post(
      Uri.parse("$_baseUrl/group_chat/create"),
      headers: hasName ? {'Content-Type': 'application/json'} : null,
      body: hasName ? jsonEncode({'group_name': trimmed}) : null,
    );
    if (response.statusCode != 201) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['group_chat_id'] as int;
  }

  // POST /group_chat/group_chat_join_code/{id} — erzeugt einen frischen,
  // zeitlich begrenzten Einladungs-Code (nur als Mitglied moeglich).
  // null = fehlgeschlagen (keine Gruppe / kein Mitglied / Netzfehler).
  static Future<int?> createGroupJoinCode(int groupChatId) async {
    final response = await ApiClient.post(
      Uri.parse("$_baseUrl/group_chat/group_chat_join_code/$groupChatId"),
    );
    if (response.statusCode != 201) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['code'] as int;
  }

  // POST /group_chat/join/{code} — tritt der Gruppe hinter dem Code bei.
  // Der Server verraet uns erst in der Antwort, WELCHE Gruppe das war —
  // die ID brauchen wir, um den Chat lokal (OpenChats) anzulegen.
  // null = Code unbekannt/abgelaufen, schon Mitglied oder Netzfehler.
  static Future<int?> joinGroupByCode(int code) async {
    final response = await ApiClient.post(
      Uri.parse("$_baseUrl/group_chat/join/$code"),
    );
    if (response.statusCode != 201) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['group_chat_id'] as int;
  }

  static Future<bool> deleteGroup(int groupChatId) async {
    final response = await ApiClient.delete(
      Uri.parse("$_baseUrl/group_chat/$groupChatId"),
    );
    return response.statusCode == 200;
  }

  // Gibt den Statuscode zurueck statt bool: 403 heisst hier "du bist der
  // Gruender, erst uebergeben" — die UI zeigt dafuer einen eigenen Hinweis.
  static Future<int> leaveGroup(int groupChatId) async {
    final response = await ApiClient.delete(
      Uri.parse("$_baseUrl/group_chat/leave/$groupChatId"),
    );
    return response.statusCode;
  }

  // PATCH /group_chat/{id} — Gruppe umbenennen (Gruender + Admins).
  // 200 ok, 403 keine Rechte, 400 leerer Name.
  static Future<int> renameGroup(int groupChatId, String name) async {
    final response = await ApiClient.patch(
      Uri.parse("$_baseUrl/group_chat/$groupChatId"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'group_name': name.trim()}),
    );
    return response.statusCode;
  }

  // PATCH /group_chat/{id}/members/{user}/role — befoerdern (admin) oder
  // degradieren (member). Ist die Rolle schon gesetzt, kommt trotzdem 200.
  // 403 = keine Rechte / Ziel ist Gruender / Admin will degradieren.
  // GroupRole.creator ist hier verboten (Server: 422) — dafuer transferGroup.
  static Future<int> setMemberRole(
    int groupChatId,
    int userId,
    GroupRole role,
  ) async {
    assert(role != GroupRole.creator, 'Gruender wechselt nur per transferGroup');
    final response = await ApiClient.patch(
      Uri.parse("$_baseUrl/group_chat/$groupChatId/members/$userId/role"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role.name}),
    );
    return response.statusCode;
  }

  // POST /group_chat/{id}/transfer/{user} — Gruppe uebergeben (nur Gruender).
  // Danach ist das Ziel Gruender und wir selbst Admin (koennen also leaven).
  static Future<int> transferGroup(int groupChatId, int userId) async {
    final response = await ApiClient.post(
      Uri.parse("$_baseUrl/group_chat/$groupChatId/transfer/$userId"),
    );
    return response.statusCode;
  }

  // DELETE /group_chat/kick/{id}/{user} — Mitglied entfernen.
  // 403 = Regelverstoss (Admin kickt Admin/Gruender ...), 404 = kein Mitglied.
  static Future<int> kickMember(int groupChatId, int userId) async {
    final response = await ApiClient.delete(
      Uri.parse("$_baseUrl/group_chat/kick/$groupChatId/$userId"),
    );
    return response.statusCode;
  }

  // POST /group_chat/{id}/picture — neues Gruppenbild hochladen. Die Datei muss
  // VORHER durch sanitizeImageFile (EXIF raus), das macht der Aufrufer.
  // Antwort ist die komplette Gruppen-Info ({group_chat_id, group_name,
  // profile_picture}), wir brauchen nur die neue URL.
  // Rueckgabe als Record, weil die UI 403 (nur Gruender/Admins duerfen) anders
  // anzeigen will als einen normalen Fehler.
  static Future<({String? url, int statusCode})> uploadGroupChatPicture(
    int groupChatId,
    File imageFile,
  ) async {
    final response = await ApiClient.uploadFile(
      Uri.parse("$_baseUrl/group_chat/$groupChatId/picture"),
      imageFile,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (url: data['profile_picture'] as String?, statusCode: 200);
    }
    debugPrint(
      'Gruppenbild-Upload fehlgeschlagen: ${response.statusCode} – ${response.body}',
    );
    return (url: null, statusCode: response.statusCode);
  }

  // GET /group_chat/{id}/members — aktuelle Mitglieder inkl. Username/Avatar
  // (der Server joint die users-Tabelle schon mit). Zwei Abnehmer:
  //  * Rekey-Flow: braucht nur die IDs (je eine Schluesselkopie pro Mitglied)
  //  * Chat-Info-Sheet: zeigt die Mitgliederliste mit Namen + Rolle an
  // Rollen kommen NICHT per WebSocket — wer die aktuelle Rolle braucht, laedt
  // diese Liste neu (z.B. beim Oeffnen des Info-Sheets).
  static Future<List<GroupMember>> fetchGroupMembers(int groupChatId) async {
    final response = await ApiClient.get(
      Uri.parse("$_baseUrl/group_chat/$groupChatId/members"),
    );
    if (response.statusCode != 200) return const [];
    final raw = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return raw.cast<Map<String, dynamic>>().map((e) {
      final id = e['user_id'] as int;
      return (
        id: id,
        username: (e['username'] as String?) ?? 'User $id',
        avatarUrl: e['profile_picture_url'] as String?,
        role: GroupRole.parse(e['role']),
      );
    }).toList();
  }

  // GET /group_chat/my — alle Gruppen, denen ICH angehoere (id + Name + Avatar).
  // Das ist das Gruppen-Gegenstueck zum globalen DM-Endpoint /messages/:
  // ohne diesen Aufruf weiss der Client nach einem frischen Login (leere DB)
  // nicht, welche Gruppen er nachsyncen soll.
  static Future<List<({int id, String? name, String? avatarUrl})>>
  fetchMyGroups() async {
    final response = await ApiClient.get(Uri.parse("$_baseUrl/group_chat/my"));
    if (response.statusCode != 200) return const [];
    final raw = jsonDecode(response.body) as List;
    return raw.cast<Map<String, dynamic>>().map((e) {
      return (
        id: e['group_chat_id'] as int,
        name: e['group_name'] as String?,
        avatarUrl: e['profile_picture'] as String?,
      );
    }).toList();
  }
}
