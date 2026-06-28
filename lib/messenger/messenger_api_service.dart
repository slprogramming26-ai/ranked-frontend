import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:ranked/key_service.dart';
import 'package:sodium/sodium.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../token_storage.dart';
import '../api_client.dart';
import '../local_data/database.dart';
import '../user_api_service.dart';
import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';

// Drei Sorten Nachrichten, die der Server uns schicken kann.
sealed class ChatEvent {
  const ChatEvent();
}

class IncomingDm extends ChatEvent {
  final int senderId;
  final String message;
  final DateTime createdAt;
  final String?
  clientMsgId; // null, solange das Backend den Key noch nicht zurueckgibt
  const IncomingDm({
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.clientMsgId,
  });
}

class InComingGroupChat extends ChatEvent {
  final int senderId;
  final int groupChatId;
  final String message;
  final DateTime createdAt;
  final String? clientMsgId;
  // null bei Alt-Nachrichten aus der Klartext-Zeit -> unverschluesselt behandeln.
  final int? keyVersion;
  const InComingGroupChat({
    required this.senderId,
    required this.groupChatId,
    required this.message,
    required this.createdAt,
    this.clientMsgId,
    this.keyVersion,
  });
}

class MessageAck extends ChatEvent {
  final int to;
  final int deliveredLive;
  const MessageAck({required this.to, required this.deliveredLive});
}

// Antwort auf einen Gruppen-Send: der Schlüssel muss erst NEU erzeugt werden
// (Gruppe ist "dirty" oder hat noch keine Epoche). -> Rekey-Flow, dann erneut senden.
class GroupRekeyRequired extends ChatEvent {
  final int groupChatId;
  const GroupRekeyRequired(this.groupChatId);
}

// Antwort auf einen Gruppen-Send: wir sind hinterher, der aktuelle Schlüssel
// existiert schon. -> abholen, dann erneut senden.
class GroupKeyOutdated extends ChatEvent {
  final int groupChatId;
  final int currentVersion;
  const GroupKeyOutdated({
    required this.groupChatId,
    required this.currentVersion,
  });
}

class ChatErrorEvent extends ChatEvent {
  final String detail;
  const ChatErrorEvent(this.detail);
}

class MessengerApiService {
  static const String _baseWsUrl = 'wss://web-production-1bb6f.up.railway.app';
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  final AppDatabase _db;
  final int _myUserId;

  MessengerApiService(this._db, this._myUserId);

  final Map<int, String> _partnerPubKeyCache = {};

  WebSocketChannel? _channel;
  Stream<ChatEvent>? _incoming;
  StreamSubscription<ChatEvent>? _subscription;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    if (_channel != null) {
      return; // wenn schon connected dann kein erneut connecten
    }

    await _syncAll();

    final token = await TokenStorage.getToken();
    final uri = Uri.parse('$_baseWsUrl/ws/chat?token=$token');
    _channel = WebSocketChannel.connect(uri); // mein channel connected einmal

    _incoming = _channel!
        .stream // wird einmal aufgerufe
        .map((raw) => jsonDecode(raw as String) as Map<String, dynamic>)
        .map(_parseEvent) //welche art ist es?
        .where((e) => e != null)
        .cast<ChatEvent>()
        .asBroadcastStream(); // mehere listener

    _subscription = _incoming!.listen(_persistIncoming);
  }

  Stream<ChatEvent>? get incoming =>
      _incoming; //referiert zu der funktion oben: nicht mehr als ein einziger aufruf

  ChatEvent? _parseEvent(Map<String, dynamic> json) {
    switch (json["kind"]) {
      case "error":
        return ChatErrorEvent(json['detail'].toString());

      case "ack":
        return MessageAck(
          to: json['to'] as int,
          deliveredLive: json['delivered_live'] as int,
        );
      case "dm":
        return IncomingDm(
          senderId: json['sender_id'] as int,
          message: json['message'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
          clientMsgId: json['client_msg_id'] as String?,
        );
      case "group":
        return InComingGroupChat(
          senderId: json['sender_id'] as int,
          groupChatId: json['group_chat_id'] as int,
          message: json['message'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
          clientMsgId: json['client_msg_id'] as String?,
          keyVersion: json['key_version'] as int?,
        );
      case "rekey_required":
        return GroupRekeyRequired(json['group_chat_id'] as int);
      case "key_outdated":
        return GroupKeyOutdated(
          groupChatId: json['group_chat_id'] as int,
          currentVersion: json['current_version'] as int,
        );
      default:
        return null;
    }
  }

  Future<String> _decryptDm(String raw, int senderId) async {
    if (!raw.startsWith('v1:')) return raw;
    try {
      final senderPubKeyB64 = await _getPartnerPublicKey(senderId);
      if (senderPubKeyB64 == null) return '[Nachricht nicht lesbar – kein Key]';
      final mySecretKey = await KeyService.getSecretKey(_myUserId.toString());
      if (mySecretKey == null) {
        return '[Nachricht nicht lesbar – eigener Key fehlt]';
      }
      final sodium = await SodiumInit.init();
      final combined = base64.decode(raw.substring(3));
      final nonceLen = sodium.crypto.box.nonceBytes;
      final nonce = combined.sublist(0, nonceLen);
      final cipher = combined.sublist(nonceLen);
      final plainBytes = sodium.crypto.box.openEasy(
        cipherText: cipher,
        nonce: nonce,
        publicKey: base64.decode(senderPubKeyB64),
        secretKey: mySecretKey,
      );
      return utf8.decode(plainBytes);
    } catch (_) {
      return '[Nachricht nicht lesbar]';
    }
  }

  // Stellt sicher, dass der Schlüssel der Epoche [version] lokal vorliegt.
  // Fehlt er, holen wir ALLE meine Epochen-Schlüssel vom Server, entsiegeln sie
  // mit meinem Private Key und speichern sie. null = auch danach nicht da
  // (z.B. Epoche vor meinem Beitritt -> Nachricht ist fuer mich nicht lesbar).
  Future<SecureKey?> _ensureGroupKey(int groupId, int version) async {
    final local = await KeyService.getGroupKey(groupId, version);
    if (local != null) return local;

    final all = await KeyService.fetchAllGroupKeys(groupId);
    for (final (v, encB64) in all) {
      final key = await KeyService.openSealedGroupKey(
        encB64,
        _myUserId.toString(),
      );
      if (key != null) await KeyService.saveGroupKey(groupId, v, key);
    }
    return KeyService.getGroupKey(groupId, version);
  }

  // Entschlüsselt eine Gruppen-Nachricht mit dem Schlüssel ihrer Epoche.
  // keyVersion == null oder kein "g1:"-Prefix -> Alt-/Klartext, unveraendert.
  Future<String> _decryptGroup(String raw, int groupId, int? keyVersion) async {
    if (keyVersion == null || !raw.startsWith('g1:')) return raw;
    final key = await _ensureGroupKey(groupId, keyVersion);
    if (key == null) return '[Nachricht nicht verfügbar]';
    try {
      final sodium = await SodiumInit.init();
      final combined = base64.decode(raw.substring(3));
      final nonceLen = sodium.crypto.secretBox.nonceBytes;
      final nonce = combined.sublist(0, nonceLen);
      final cipher = combined.sublist(nonceLen);
      final plainBytes = sodium.crypto.secretBox.openEasy(
        cipherText: cipher,
        nonce: nonce,
        key: key,
      );
      return utf8.decode(plainBytes);
    } catch (_) {
      return '[Nachricht nicht lesbar]';
    }
  }

  Future<void> _persistIncoming(ChatEvent event) async {
    switch (event) {
      case IncomingDm dm:
        await _ensureDmOpenChat(dm.senderId);
        final plaintext = await _decryptDm(dm.message, dm.senderId);
        await _db.saveDm(
          senderId: dm.senderId,
          recipientId: _myUserId,
          message: plaintext,
          createdAt: dm.createdAt,
          clientMsgId: dm.clientMsgId,
        );
        await _syncDmHistory(dm.createdAt);
      case InComingGroupChat g:
        await _ensureGroupOpenChat(g.groupChatId);
        final plaintext = await _decryptGroup(
          g.message,
          g.groupChatId,
          g.keyVersion,
        );
        await _db.saveGroupMessage(
          senderId: g.senderId,
          groupChatId: g.groupChatId,
          message: plaintext,
          createdAt: g.createdAt,
          clientMsgId: g.clientMsgId,
        );
        await _syncGroupHistory(g.groupChatId, g.createdAt);
      case MessageAck _:
      case GroupRekeyRequired _:
      case GroupKeyOutdated _:
      case ChatErrorEvent _:
        // Acks, Rekey-/Outdated-Aufträge und Errors gehen nicht in die DB —
        // die sind nur Feedback für den Sender / die UI im Moment.
        // Der Sende-Flow (Schritt 3) wertet sie aus.
        break;
    }
  }

  // Legt einen OpenChat-Eintrag für einen DM-Partner an, falls noch keiner existiert.
  // Holt Username/Avatar per API; bei Fehler bleibt der Fallback "User $id".
  Future<void> _ensureDmOpenChat(int peerId) async {
    final existing =
        await (_db.select(_db.openChats)
              ..where((t) => t.id.equals(peerId) & t.isGroupChat.equals(false)))
            .getSingleOrNull();
    if (existing != null) return;

    String username = 'User $peerId';
    String? avatarUrl;
    try {
      final user = await UserApiService.getUser(peerId);
      if (user['username'] is String) username = user['username'] as String;
      if (user['profile_picture_url'] is String) {
        avatarUrl = user['profile_picture_url'] as String;
      }
    } catch (_) {
      // Fallback bleibt
    }

    await _db
        .into(_db.openChats)
        .insert(
          OpenChatsCompanion.insert(
            id: peerId,
            isGroupChat: false,
            username: Value(username),
            avatarUrl: Value(avatarUrl),
          ),
        );
  }

  Future<void> _ensureGroupOpenChat(int groupChatId) async {
    final existing =
        await (_db.select(_db.openChats)..where(
              (t) => t.id.equals(groupChatId) & t.isGroupChat.equals(true),
            ))
            .getSingleOrNull();
    if (existing != null) return;

    await _db
        .into(_db.openChats)
        .insert(
          OpenChatsCompanion.insert(
            id: groupChatId,
            isGroupChat: true,
            username: Value('Gruppe $groupChatId'),
          ),
        );
  }

  static const _uuid = Uuid();

  void sendDirectMessage(int recipientId, String message) async {
    final clientMsgId = _uuid.v4();

    // Partner-Key holen (Cache → Server)
    final partnerPubKeyB64 = await _getPartnerPublicKey(recipientId);
    if (partnerPubKeyB64 == null) {
      debugPrint(
        '[E2EE] Kein Key für Partner $recipientId — Versand blockiert',
      );
      return;
    }

    // Eigenen Secret Key laden und verschlüsseln
    final mySecretKey = await KeyService.getSecretKey(_myUserId.toString());
    String wireMessage = message; // Fallback Klartext falls eigener Key fehlt
    if (mySecretKey != null) {
      final sodium = await SodiumInit.init();
      final nonce = sodium.randombytes.buf(sodium.crypto.box.nonceBytes);
      final cipher = sodium.crypto.box.easy(
        message: Uint8List.fromList(utf8.encode(message)),
        nonce: nonce,
        publicKey: base64.decode(partnerPubKeyB64),
        secretKey: mySecretKey,
      );
      final combined = Uint8List(nonce.length + cipher.length)
        ..setAll(0, nonce)
        ..setAll(nonce.length, cipher);
      wireMessage = 'v1:${base64.encode(combined)}';
    }

    _channel?.sink.add(
      jsonEncode({
        'kind': 'dm',
        'to': recipientId,
        'message': wireMessage,
        'client_msg_id': clientMsgId,
      }),
    );
    // Klartext lokal speichern — nicht den Geheimtext
    await _db.saveDm(
      senderId: _myUserId,
      recipientId: recipientId,
      message: message,
      createdAt: DateTime.now().toUtc(),
      clientMsgId: clientMsgId,
    );
  }

  Future<String?> _getPartnerPublicKey(int peerId) async {
    if (_partnerPubKeyCache.containsKey(peerId)) {
      return _partnerPubKeyCache[peerId];
    }
    final key = await KeyService.fetchPartnerPublicKey(peerId);
    if (key != null) _partnerPubKeyCache[peerId] = key;
    return key;
  }

  void sendGroupMessage(int groupChatId, String message) async {
    final clientMsgId = _uuid.v4();

    // Optimistisch: Klartext sofort lokal anzeigen. Das spaetere Server-Echo
    // (gleiche client_msg_id) wird per insertOrIgnore dedupliziert.
    await _db.saveGroupMessage(
      senderId: _myUserId,
      groupChatId: groupChatId,
      message: message,
      createdAt: DateTime.now().toUtc(),
      clientMsgId: clientMsgId,
    );

    // Bis zu ein paar Anlaeufe: senden -> Antwort -> ggf. Schluessel besorgen
    // -> mit gleicher client_msg_id erneut. ack beendet die Schleife.
    for (var attempt = 0; attempt < 4; attempt++) {
      // 1. Epoche bestimmen (lokal -> Server abholen -> notfalls selbst rekeyen)
      var version = await KeyService.getCurrentGroupKeyVersion(groupChatId);
      version ??= await _fetchAndStoreCurrentKey(groupChatId);
      version ??= await _performRekey(groupChatId);
      if (version == null) return; // kein Schluessel zu bekommen -> aufgeben

      // 2. verschluesseln
      final wire = await _encryptGroup(groupChatId, version, message);
      if (wire == null) return;

      // 3. Antwort-Listener VOR dem Senden scharf schalten (sonst Race),
      //    dann senden.
      final respFuture = _awaitGroupResponse(groupChatId);
      _channel?.sink.add(
        jsonEncode({
          'kind': 'group',
          'to': groupChatId,
          'message': wire,
          'key_version': version,
          'client_msg_id': clientMsgId,
        }),
      );

      // 4. auf die korrelierte Antwort reagieren
      final resp = await respFuture;
      switch (resp) {
        case MessageAck _:
          return; // zugestellt
        case GroupRekeyRequired _:
          if (await _performRekey(groupChatId) == null) return;
          continue; // mit neuer Epoche erneut
        case GroupKeyOutdated _:
          await _fetchAndStoreCurrentKey(groupChatId);
          continue; // mit aktueller Epoche erneut
        default:
          return; // Error oder Timeout -> aufgeben
      }
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _incoming = null;
  }

  // holt schlüssel speichert ihn
  Future<int?> _fetchAndStoreCurrentKey(int groupId) async {
    final fetched = await KeyService.fetchCurrentGroupKey(groupId);
    if (fetched == null) return null;
    final (version, encB64) = fetched;
    final key = await KeyService.openSealedGroupKey(
      encB64,
      _myUserId.toString(),
    );
    if (key == null) return null;
    await KeyService.saveGroupKey(groupId, version, key);
    return version;
  }

  Future<String?> _encryptGroup(
    int groupId,
    int version,
    String message,
  ) async {
    final key = await KeyService.getGroupKey(groupId, version);
    if (key == null) return null;
    final sodium = await SodiumInit.init();
    final nonce = sodium.randombytes.buf(sodium.crypto.secretBox.nonceBytes);
    final cipher = sodium.crypto.secretBox.easy(
      message: Uint8List.fromList(utf8.encode(message)),
      nonce: nonce,
      key: key,
    );
    final combined = Uint8List(nonce.length + cipher.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, cipher);
    return 'g1:${base64.encode(combined)}';
  }

  Future<ChatEvent?> _awaitGroupResponse(
    int groupId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stream = _incoming;
    if (stream == null) return null;
    try {
      return await stream
          .firstWhere(
            (e) =>
                (e is MessageAck && e.to == groupId) ||
                (e is GroupRekeyRequired && e.groupChatId == groupId) ||
                (e is GroupKeyOutdated && e.groupChatId == groupId) ||
                e is ChatErrorEvent,
          )
          .timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  Future<int?> _performRekey(int groupId) async {
    // Bei 409 (Mitglieder geaendert / gleichzeitiges Rekey) Mitglieder neu
    // laden und erneut versuchen.
    for (var i = 0; i < 3; i++) {
      final members = await fetchGroupMembers(groupId);
      if (members.isEmpty) return null;

      final groupKey = await KeyService.generateGroupKey();
      final keys = <Map<String, dynamic>>[];
      for (final memberId in members) {
        final pub = await _getPartnerPublicKey(memberId);
        if (pub == null) {
          // Ein Mitglied hat (noch) keinen Public Key -> wir koennen die
          // Pflicht "ein Eintrag pro Mitglied" nicht erfuellen.
          debugPrint(
            '[E2EE] Mitglied $memberId ohne Public Key — Rekey abgebrochen',
          );
          return null;
        }
        keys.add({
          'recipient_id': memberId,
          'encrypted_key': await KeyService.sealGroupKeyFor(groupKey, pub),
        });
      }

      final result = await KeyService.rekeyGroup(groupId, keys);
      switch (result.status) {
        case RekeyStatus.success:
          await KeyService.saveGroupKey(groupId, result.keyVersion!, groupKey);
          return result.keyVersion;
        case RekeyStatus.conflict:
          continue; // Mitglieder neu laden, erneut
        case RekeyStatus.error:
          return null;
      }
    }
    return null;
  }

  static Future<bool> deleteGroup(int groupChatId) async {
    final response = await ApiClient.delete(
      Uri.parse("$baseUrl/group_chat/$groupChatId"),
    );
    return response.statusCode == 200;
  }

  static Future<bool> leaveGroup(int groupChatId) async {
    final response = await ApiClient.delete(
      Uri.parse("$baseUrl/group_chat/leave/$groupChatId"),
    );
    return response.statusCode == 200;
  }

  static Future<int?> createGroup() async {
    final response = await ApiClient.post(
      Uri.parse("$baseUrl/group_chat/create"),
    );
    if (response.statusCode != 201) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['group_chat_id'] as int;
  }

  static Future<bool> joinGroup(int groupChatId) async {
    final response = await ApiClient.post(
      Uri.parse("$baseUrl/group_chat/join/$groupChatId"),
    );
    return response.statusCode == 201;
  }

  // GET /group_chat/{id}/members — aktuelle Mitglieder (nur deren user_id).
  // Basis fuer den Rekey-Flow: fuer jeden brauchen wir je eine Schluesselkopie.
  static Future<List<int>> fetchGroupMembers(int groupChatId) async {
    final response = await ApiClient.get(
      Uri.parse("$baseUrl/group_chat/$groupChatId/members"),
    );
    if (response.statusCode != 200) return const [];
    final raw = jsonDecode(response.body) as List;
    return raw
        .cast<Map<String, dynamic>>()
        .map((e) => e['user_id'] as int)
        .toList();
  }

  Future<void> _syncAll() async {
    final dmSyncMarker = await _db.getSyncMarker("dm");
    await _syncDmHistory(dmSyncMarker);

    final groups = await (_db.select(
      _db.openChats,
    )..where((t) => t.isGroupChat.equals(true))).get();
    for (final i in groups) {
      final groupId = i.id;
      final groupSyncMarker = await _db.getSyncMarker("group:$groupId");
      await _syncGroupHistory(groupId, groupSyncMarker);
    }
  }

  Future<void> _syncDmHistory(DateTime? since) async {
    final uri = since == null
        ? Uri.parse('$baseUrl/messages/')
        : Uri.parse(
            '$baseUrl/messages/?since=${since.toUtc().toIso8601String()}',
          );
    final response = await ApiClient.get(uri);
    if (response.statusCode != 200) return;
    final raw = jsonDecode(response.body) as List;
    if (raw.isEmpty) return;

    final messages = raw.cast<Map<String, dynamic>>();

    // Ein globaler Endpoint -> ein globaler Marker. Wir merken uns nur das
    // groesste created_at ueber ALLE Partner. Die Partner-IDs sammeln wir
    // separat (als Set), um jeden Chat in der Kontaktliste sicherzustellen.
    final partners = <int>{};
    DateTime? newest;

    for (final m in messages) {
      final senderId = m['sender_id'] as int;
      final recipientId = m['recipient_id'] as int;
      final createdAt = DateTime.parse(m['created_at'] as String).toUtc();
      final otherPartyId = senderId == _myUserId ? recipientId : senderId;
      final plaintext = await _decryptDm(m['message'] as String, otherPartyId);

      await _db.saveDm(
        senderId: senderId,
        recipientId: recipientId,
        message: plaintext,
        createdAt: createdAt,
        clientMsgId: m['client_msg_id'] as String?,
      );

      // Partner = die Seite, die nicht ich bin
      final partnerId = senderId == _myUserId ? recipientId : senderId;
      partners.add(partnerId);

      if (newest == null || createdAt.isAfter(newest)) newest = createdAt;
    }

    for (final partnerId in partners) {
      await _ensureDmOpenChat(partnerId);
    }
    if (newest != null) await _db.updateSyncMarker('dm', newest);
  }

  Future<void> _syncGroupHistory(int groupId, DateTime? since) async {
    final uri = since == null
        ? Uri.parse('$baseUrl/messages/group/$groupId')
        : Uri.parse(
            '$baseUrl/messages/group/$groupId?since=${since.toUtc().toIso8601String()}',
          );
    final response = await ApiClient.get(uri);
    if (response.statusCode != 200) return;

    final raw = jsonDecode(response.body) as List;

    if (raw.isEmpty) return; // nichts Neues -> einfach fertig, kein Fehler
    final messages = raw.cast<Map<String, dynamic>>();

    await _ensureGroupOpenChat(groupId);
    DateTime? newestMessageTime;

    for (var m in messages) {
      final createdAt = DateTime.parse(m['created_at'] as String).toUtc();
      final senderId = m['sender_id'] as int;
      final plaintext = await _decryptGroup(
        m['message'] as String,
        groupId,
        m['key_version'] as int?,
      );

      await _db.saveGroupMessage(
        senderId: senderId,
        groupChatId: m["group_chat_id"] as int,
        message: plaintext,
        createdAt: createdAt,
        clientMsgId: m['client_msg_id'] as String?,
      );

      if (newestMessageTime == null || createdAt.isAfter(newestMessageTime)) {
        newestMessageTime = createdAt;
      }
    }

    await _db.updateSyncMarker('group:$groupId', newestMessageTime!);
  }
}
