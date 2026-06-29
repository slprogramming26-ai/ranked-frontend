// =============================================================================
//  E2EE: Ver-/Entschluesseln von Nachrichten + Schluessel-Verwaltung
// =============================================================================
//  DMs nutzen crypto_box (Public/Secret Key des Partners). Gruppen nutzen einen
//  symmetrischen Epochen-Schluessel (secretBox), der pro Mitglied versiegelt
//  verteilt wird. Prefixe: 'v1:' = DM-Chiffre, 'g1:' = Gruppen-Chiffre.
// =============================================================================
part of 'messenger_api_service.dart';

extension MessengerCrypto on MessengerApiService {
  /// Public Key eines Partners holen — erst aus dem Cache, sonst vom Server.
  Future<String?> _getPartnerPublicKey(int peerId) async {
    if (_partnerPubKeyCache.containsKey(peerId)) {
      return _partnerPubKeyCache[peerId];
    }
    final key = await KeyService.fetchPartnerPublicKey(peerId);
    if (key != null) _partnerPubKeyCache[peerId] = key;
    return key;
  }

  /// Entschluesselt eine DM. Kein 'v1:'-Prefix -> Klartext (Alt-Nachricht),
  /// unveraendert zurueck. Bei fehlenden Keys/Fehlern eine lesbare Platzhalter-
  /// Meldung statt eines Absturzes.
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

  /// Verschluesselt eine Gruppen-Nachricht mit dem lokalen Epochen-Schluessel.
  /// Liefert den 'g1:'-Wire-String oder null, wenn der Schluessel fehlt.
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

  // holt den aktuellen Gruppenschluessel vom Server, entsiegelt und speichert ihn
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

  /// Erzeugt eine neue Gruppen-Epoche: neuen Schluessel generieren, fuer JEDES
  /// Mitglied versiegeln und hochladen. Bei 409 (Mitglieder haben sich geaendert
  /// / paralleler Rekey) Mitglieder neu laden und erneut versuchen.
  Future<int?> _performRekey(int groupId) async {
    for (var i = 0; i < 3; i++) {
      final members = await MessengerApiService.fetchGroupMembers(groupId);
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
}