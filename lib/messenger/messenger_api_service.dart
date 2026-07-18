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
import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:sodium/sodium.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:ranked/key_service.dart';
import '../token_storage.dart';
import '../api_client.dart';
import '../local_data/database.dart';
import '../user_api_service.dart';

// ChatEvent & Co. wieder mit exportieren, damit Importer dieser Datei (UI,
// conversation.dart) die Typen weiterhin ohne extra Import sehen.
export 'chat_event.dart';
import 'chat_event.dart';

part 'messenger_api_service.connection.dart';
part 'messenger_api_service.crypto.dart';
part 'messenger_api_service.send.dart';
part 'messenger_api_service.sync.dart';

const _baseWsUrl = 'wss://web-production-1bb6f.up.railway.app';
const _baseUrl = 'https://web-production-1bb6f.up.railway.app';

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
  bool _manuallyClosed = false; // true = absichtlich geschlossen, kein Reconnect
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // ---------------------------------------------------------------------------
  //  Statische Gruppen-REST-Endpunkte
  //  Brauchen keinen Service-Zustand, daher static. Aufruf von aussen z.B.
  //  MessengerApiService.createGroup().
  // -------------------------------------------------------------
  //
  // --------------

  static Future<int?> createGroup() async {
    final response = await ApiClient.post(
      Uri.parse("$_baseUrl/group_chat/create"),
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

  static Future<bool> leaveGroup(int groupChatId) async {
    final response = await ApiClient.delete(
      Uri.parse("$_baseUrl/group_chat/leave/$groupChatId"),
    );
    return response.statusCode == 200;
  }

  // GET /group_chat/{id}/members — aktuelle Mitglieder inkl. Username/Avatar
  // (der Server joint die users-Tabelle schon mit). Zwei Abnehmer:
  //  * Rekey-Flow: braucht nur die IDs (je eine Schluesselkopie pro Mitglied)
  //  * Chat-Info-Sheet: zeigt die Mitgliederliste mit Namen an
  static Future<List<({int id, String username, String? avatarUrl})>>
  fetchGroupMembers(int groupChatId) async {
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