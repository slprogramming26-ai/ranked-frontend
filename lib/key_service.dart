import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium/sodium.dart';

import 'api_client.dart';

class KeyService {
  static const _storage = FlutterSecureStorage();
  static const _baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static String _privStorageKey(String userId) => 'e2ee_priv_$userId';
  static String _pubStorageKey(String userId) => 'e2ee_pub_$userId';

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
}