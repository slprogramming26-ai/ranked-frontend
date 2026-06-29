// =============================================================================
//  Senden: Direktnachrichten und Gruppennachrichten
// =============================================================================
part of 'messenger_api_service.dart';

const _uuid = Uuid();

extension MessengerSend on MessengerApiService {
  /// Sendet eine Direktnachricht: Partner-Key holen, mit crypto_box
  /// verschluesseln ('v1:'-Wire), ueber den WebSocket schicken und den
  /// KLARTEXT lokal speichern (nie den Geheimtext). Die client_msg_id erlaubt
  /// dem spaeteren Server-Echo, sich selbst zu deduplizieren.
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

  /// Sendet eine Gruppennachricht. Zeigt den Klartext optimistisch sofort an
  /// und arbeitet sich dann in bis zu 4 Anlaeufen durch den Epochen-/Rekey-Flow:
  /// passenden Schluessel besorgen, verschluesseln, senden, auf die korrelierte
  /// Server-Antwort warten. Ein Ack beendet die Schleife.
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

  // Wartet auf die ERSTE Server-Antwort, die zu diesem Gruppen-Send gehoert
  // (Ack/Rekey/Outdated fuer diese Gruppe, oder ein Error). Timeout -> null.
  Future<ChatEvent?> _awaitGroupResponse(
    int groupId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      return await _events.stream
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
}