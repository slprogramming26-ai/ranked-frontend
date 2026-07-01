// =============================================================================
//  Persistenz & REST-Nachsync
// =============================================================================
//  Zwei Wege, wie Nachrichten in die lokale DB kommen:
//   1. Live ueber den WebSocket  -> _persistIncoming (haengt am _events-Band).
//   2. Nachsync ueber REST        -> _syncAll / _syncDmHistory / _syncGroupHistory,
//      gesteuert ueber "SyncMarker" (letztes bekanntes created_at je Quelle).
// =============================================================================
part of 'messenger_api_service.dart';

extension MessengerSync on MessengerApiService {
  // Reagiert auf JEDES eingehende Live-Event. Nur DMs und Gruppen-Nachrichten
  // landen in der DB; Acks/Rekey/Outdated/Error sind nur Feedback fuer den
  // Sende-Flow und werden hier ignoriert.
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

  // Legt einen OpenChat-Eintrag fuer eine Gruppe an, falls noch keiner existiert.
  // name/avatarUrl kommen aus dem Discovery-Endpoint /group_chat/my; fehlen sie
  // (z.B. beim Live-Pfad ueber den WebSocket), greift der Fallback "Gruppe $id".
  Future<void> _ensureGroupOpenChat(
    int groupChatId, {
    String? name,
    String? avatarUrl,
  }) async {
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
            username: Value(name ?? 'Gruppe $groupChatId'),
            avatarUrl: Value(avatarUrl),
          ),
        );
  }

  // Holt fuer ALLE bekannten Chats das nach (DMs + jede Gruppe), ausgehend vom
  // jeweils gespeicherten SyncMarker. Wird beim (Re)connect aufgerufen.
  Future<void> _syncAll() async {
    final dmSyncMarker = await _db.getSyncMarker("dm");
    await _syncDmHistory(dmSyncMarker);

    // Discovery: ZUERST die Gruppen-Mitgliedschaften vom Server holen und je
    // Gruppe einen OpenChat sicherstellen. Ohne diesen Schritt waere die
    // Schleife unten nach einem frischen Login (clearDatabase beim Logout)
    // leer -> Gruppen wuerden nie nachgesynct. DMs entdecken ihre Partner
    // dagegen direkt aus dem globalen /messages/-Endpoint.
    final myGroups = await MessengerApiService.fetchMyGroups();
    for (final g in myGroups) {
      await _ensureGroupOpenChat(g.id, name: g.name, avatarUrl: g.avatarUrl);
    }

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
        ? Uri.parse('$_baseUrl/messages/')
        : Uri.parse(
            '$_baseUrl/messages/?since=${since.toUtc().toIso8601String()}',
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
        ? Uri.parse('$_baseUrl/messages/group/$groupId')
        : Uri.parse(
            '$_baseUrl/messages/group/$groupId?since=${since.toUtc().toIso8601String()}',
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