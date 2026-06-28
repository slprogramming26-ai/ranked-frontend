import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium/sodium.dart';

import 'api_client.dart';

// Ergebnis eines Rekey-Versuchs (POST /keys/group/{id}/rekey).
// conflict = 409 (Mitgliederliste passt nicht ODER gleichzeitiges Rekey)
//            -> Aufrufer laedt Mitglieder neu und versucht es erneut.
enum RekeyStatus { success, conflict, error }

class RekeyResult {
  final RekeyStatus status;
  final int? keyVersion; //  die neue Epoche (succes)
  final int? httpCode; // nur bei error
  const RekeyResult._(this.status, {this.keyVersion, this.httpCode});

  factory RekeyResult.success(int version) =>
      RekeyResult._(RekeyStatus.success, keyVersion: version);
  factory RekeyResult.conflict() => const RekeyResult._(RekeyStatus.conflict);
  factory RekeyResult.error(int code) =>
      RekeyResult._(RekeyStatus.error, httpCode: code);
}

class KeyService {
  static const _storage = FlutterSecureStorage();
  static const _baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static String _privStorageKey(String userId) => 'e2ee_priv_$userId';
  static String _pubStorageKey(String userId) => 'e2ee_pub_$userId';

  // Ein Eintrag pro (Gruppe, Epoche): der symmetrische Schluessel dieser Epoche.
  static String _groupKeyStorageKey(int groupId, int version) =>
      'e2ee_gkey_${groupId}_$version';
  // Zeiger auf die hoechste Epoche, die wir fuer eine Gruppe kennen
  // -> mit dieser Version senden wir.
  static String _groupCurVersionKey(int groupId) => 'e2ee_gkey_cur_$groupId';

  // Stellt sicher dass ein Keypair für [userId] existiert.
  // Generiert einen neuen falls noch keiner vorhanden ist.
  static Future<(String, SecureKey)> ensureKeypair(String userId) async {
    final storedPriv = await _storage.read(key: _privStorageKey(userId));
    final storedPub = await _storage.read(key: _pubStorageKey(userId));

    if (storedPriv != null && storedPub != null) {
      // Bereits vorhanden: laden
      final sodium = await SodiumInit.init();
      final secretKey = sodium.secureCopy(base64.decode(storedPriv));
      return (storedPub, secretKey);
    }

    // Noch kein Key: neu generieren
    final sodium = await SodiumInit.init();
    final keyPair = sodium.crypto.box.keyPair();

    final privBase64 = base64.encode(keyPair.secretKey.extractBytes());
    final pubBase64 = base64.encode(keyPair.publicKey);

    await _storage.write(key: _privStorageKey(userId), value: privBase64);
    await _storage.write(key: _pubStorageKey(userId), value: pubBase64);

    return (pubBase64, keyPair.secretKey);
  }

  static Future<SecureKey?> getSecretKey(String userId) async {
    final stored = await _storage.read(key: _privStorageKey(userId));
    if (stored == null) return null;
    final sodium = await SodiumInit.init();
    return sodium.secureCopy(base64.decode(stored));
  }

  static Future<void> deleteKeypair(String userId) async {
    await _storage.delete(key: _privStorageKey(userId));
    await _storage.delete(key: _pubStorageKey(userId));
  }

  // Lädt  eigenen Public Key auf den Server hoch
  static Future<bool> uploadPublicKey(String publicKeyBase64) async {
    final response = await ApiClient.put(
      Uri.parse('$_baseUrl/keys/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'public_key': publicKeyBase64}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
  
  // Holt den Public Key eines anderen Nutzers vom Server.
  // Gibt null zurück wenn kein Key vorhanden (404 → noch kein E2EE-Gerät).
  static Future<String?> fetchPartnerPublicKey(int userId) async {
    final response = await ApiClient.get(Uri.parse('$_baseUrl/keys/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['public_key'] as String?;
    }
    return null;
  }


  //  Gruppen-E2EE: lokale Speicherung der Epochen-Schlüssel

  // Speichert den symmetrischen Schlüssel einer Epoche, schiebt den
  // "aktuelle Version"-Zeiger nur nach oben (eine alte Epoche, die wir
  // nachladen, darf den Zeiger nicht zuruecksetzen).
  static Future<void> saveGroupKey(
    int groupId,
    int version,
    SecureKey key,
  ) async {
    await _storage.write(
      key: _groupKeyStorageKey(groupId, version),
      value: base64.encode(key.extractBytes()),
    );
    final cur = await getCurrentGroupKeyVersion(groupId);
    if (cur == null || version > cur) {
      await _storage.write(
        key: _groupCurVersionKey(groupId),
        value: version.toString(),
      );
    }
  }

  // Lädt den Schlüssel einer bestimmten Epoche, oder null falls nicht lokal
  // vorhanden (dann muss der Aufrufer ihn vom Server holen).
  static Future<SecureKey?> getGroupKey(int groupId, int version) async {
    final stored = await _storage.read(
      key: _groupKeyStorageKey(groupId, version),
    );
    if (stored == null) return null;
    final sodium = await SodiumInit.init();
    return sodium.secureCopy(base64.decode(stored));
  }

  // Höchste Epoche, die wir für diese Gruppe kennen (= womit wir senden).
  // null = wir haben noch gar keinen Schlüssel für die Gruppe.
  static Future<int?> getCurrentGroupKeyVersion(int groupId) async {
    final v = await _storage.read(key: _groupCurVersionKey(groupId));
    return v == null ? null : int.tryParse(v);
  }


  //  Gruppen-E2EE: Krypto-Helfer für den Schlüssel selbst


  // Frischer zufälliger Gruppenschlüssel (eine neue Epoche).
  static Future<SecureKey> generateGroupKey() async {
    final sodium = await SodiumInit.init();
    return sodium.crypto.secretBox.keygen();
  }

  // Verpackt den Gruppenschlüssel für EIN Mitglied: Sealed Box, anonym.
  // Nur der Public Key des Empfängers nötig;
  static Future<String> sealGroupKeyFor(
    SecureKey groupKey,
    String recipientPubKeyB64,
  ) async {
    final sodium = await SodiumInit.init();
    final sealed = sodium.crypto.box.seal(
      message: groupKey.extractBytes(),
      publicKey: base64.decode(recipientPubKeyB64),
    );
    return base64.encode(sealed);
  }

  // Entpackt einen für MICH versiegelten Gruppenschlüssel (mit meinem Keypair).
  // null = mein Keypair fehlt oder der Ciphertext ist nicht für mich.
  static Future<SecureKey?> openSealedGroupKey(
    String encryptedKeyB64,
    String myUserId,
  ) async {
    final mySecret = await getSecretKey(myUserId);
    final myPubB64 = await _storage.read(key: _pubStorageKey(myUserId));
    if (mySecret == null || myPubB64 == null) return null;
    try {
      final sodium = await SodiumInit.init();
      final opened = sodium.crypto.box.sealOpen(
        cipherText: base64.decode(encryptedKeyB64),
        publicKey: base64.decode(myPubB64),
        secretKey: mySecret,
      );
      return sodium.secureCopy(opened);
    } catch (_) {
      return null;
    }
  }

  //  Gruppen-E2EE: REST-Endpoints (/keys)


  // POST /keys/group/{id}/rekey — verteilt einen neuen Gruppenschlüssel.
  // [keys] muss exakt ein Eintrag pro aktuellem Mitglied sein, je
  // { "recipient_id": int, "encrypted_key": String }.
  static Future<RekeyResult> rekeyGroup(
    int groupId,
    List<Map<String, dynamic>> keys,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('$_baseUrl/keys/group/$groupId/rekey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'keys': keys}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RekeyResult.success(data['key_version'] as int);
    }
    if (response.statusCode == 409) return RekeyResult.conflict();
    return RekeyResult.error(response.statusCode);
  }

  // GET /keys/group/{id}/key — aktuelle Epoche abholen.
  // Rückgabe: (key_version, encrypted_key) oder null (404/403).
  static Future<(int, String)?> fetchCurrentGroupKey(int groupId) async {
    final response = await ApiClient.get(
      Uri.parse('$_baseUrl/keys/group/$groupId/key'),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['key_version'] as int, data['encrypted_key'] as String);
  }

  // GET /keys/group/{id}/keys — alle meine Epochen-Schlüssel (sortiert).
  // Für History-Lesen / Neuinstallation.
  static Future<List<(int, String)>> fetchAllGroupKeys(int groupId) async {
    final response = await ApiClient.get(
      Uri.parse('$_baseUrl/keys/group/$groupId/keys'),
    );
    if (response.statusCode != 200) return const [];
    final raw = jsonDecode(response.body) as List;
    return raw
        .cast<Map<String, dynamic>>()
        .map((e) => (e['key_version'] as int, e['encrypted_key'] as String))
        .toList();
  }
}