import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium/sodium.dart';
// pwhash (Argon2) gibt es nur in der Sumo-API. Nativ ist das dieselbe
// libsodium — kein Build-Unterschied, nur ein anderer Einstiegspunkt.
import 'package:sodium/sodium_sumo.dart'
    show SodiumSumo, SodiumSumoInit, CryptoPwhashAlgorithm;

import 'api_client.dart';
import 'key_backup.dart';

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

  // Session-Cache: Ein Secure-Storage-Read geht durch Keychain/Keystore (IPC,
  // teuer) und fiel bisher pro entschluesselter Nachricht an. Einmal geladene
  // Schluessel bleiben deshalb fuer die App-Session im RAM. Die Map-Keys
  // enthalten userId bzw. Gruppe+Epoche — ein User-Wechsel kollidiert also
  // nicht mit alten Eintraegen.
  static final Map<String, SecureKey> _secretKeyCache = {};
  static final Map<String, SecureKey> _groupKeyCache = {};
  static String _groupCacheKey(int groupId, int version) =>
      '$groupId:$version';

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
  // ACHTUNG: Nur aus KeySetup aufrufen (Login/Registrierung), NACHDEM geklaert
  // ist, dass es kein Backup gibt — sonst ueberschreibt der neue Pubkey den
  // alten und die Chat-History ist unlesbar.
  static Future<(String, SecureKey)> ensureKeypair(String userId) async {
    final storedPriv = await _storage.read(key: _privStorageKey(userId));
    final storedPub = await _storage.read(key: _pubStorageKey(userId));

    if (storedPriv != null && storedPub != null) {
      // Bereits vorhanden: laden
      final sodium = await SodiumInit.init();
      final secretKey = sodium.secureCopy(base64.decode(storedPriv));
      _secretKeyCache[userId] = secretKey;
      return (storedPub, secretKey);
    }

    // Noch kein Key: neu generieren
    final sodium = await SodiumInit.init();
    final keyPair = sodium.crypto.box.keyPair();

    final privBase64 = base64.encode(keyPair.secretKey.extractBytes());
    final pubBase64 = base64.encode(keyPair.publicKey);

    await _storage.write(key: _privStorageKey(userId), value: privBase64);
    await _storage.write(key: _pubStorageKey(userId), value: pubBase64);

    _secretKeyCache[userId] = keyPair.secretKey;
    return (pubBase64, keyPair.secretKey);
  }

  static Future<SecureKey?> getSecretKey(String userId) async {
    final cached = _secretKeyCache[userId];
    if (cached != null) return cached;
    final stored = await _storage.read(key: _privStorageKey(userId));
    if (stored == null) return null;
    final sodium = await SodiumInit.init();
    return _secretKeyCache[userId] = sodium.secureCopy(base64.decode(stored));
  }

  // Liegt fuer diesen User schon ein Keypair auf dem Geraet? (Ueberlebt Logout.)
  static Future<bool> hasLocalKeypair(String userId) async {
    final priv = await _storage.read(key: _privStorageKey(userId));
    final pub = await _storage.read(key: _pubStorageKey(userId));
    return priv != null && pub != null;
  }

  // Nur lesen, nie erzeugen — null wenn kein lokales Keypair.
  static Future<String?> loadLocalPublicKey(String userId) =>
      _storage.read(key: _pubStorageKey(userId));

  // Schreibt ein wiederhergestelltes Keypair (aus dem Backup) unter dieselben
  // Storage-Keys wie ensureKeypair und waermt den Cache vor.
  static Future<void> storeKeypair(
    String userId,
    SecureKey privKey,
    String pubKeyB64,
  ) async {
    await _storage.write(
      key: _privStorageKey(userId),
      value: base64.encode(privKey.extractBytes()),
    );
    await _storage.write(key: _pubStorageKey(userId), value: pubKeyB64);
    _secretKeyCache[userId] = privKey;
  }

  static Future<void> deleteKeypair(String userId) async {
    _secretKeyCache.remove(userId);
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
  
  // Eigener Pubkey auf dem Server = die aktuell gueltige Schluessel-
  // Generation ("Epoch"). Anders als fetchPartnerPublicKey trennt das
  // 404 (ok, noch keiner da -> publicKey null) von Fehlern (ok false),
  // denn nur auf eine ECHTE Antwort duerfen wir Keys loeschen/hochladen.
  static Future<({bool ok, String? publicKey})> fetchOwnPublicKey(
    int userId,
  ) async {
    try {
      final response = await ApiClient.get(Uri.parse('$_baseUrl/keys/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (ok: true, publicKey: data['public_key'] as String);
      }
      if (response.statusCode == 404) return (ok: true, publicKey: null);
      return (ok: false, publicKey: null);
    } catch (_) {
      return (ok: false, publicKey: null);
    }
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


  //  Key-Backup: Keypair mit einem Passwort verschluesseln

  // Obergrenze fuer den memlimit aus einem Backup vom Server. Ohne Deckel
  // koennte ein kaputter/boeswilliger Server z.B. 2 GB schicken -> OOM-Crash
  // beim Restore. Wir selbst schreiben 64 MiB (memLimitInteractive).
  static const _maxBackupMemLimit = 256 * 1024 * 1024;

  // Argon2id(password, salt) -> 32-Byte-KEK. Das ist der einzige teure Teil
  // (~1 s, 64 MiB) und laeuft deshalb im Isolate, sonst friert die UI ein.
  // runIsolated kann einen SecureKey sicher zurueckgeben (native Kopie),
  // secretBox danach ist schnell und laeuft wieder im Main-Isolate.
  // Passwort unveraendert als UTF-8 (kein trim!) — wrap und unwrap muessen
  // exakt dieselben Bytes bekommen.
  static Future<SecureKey> _deriveKek(
    SodiumSumo sodium,
    String password,
    Uint8List salt,
    int opsLimit,
    int memLimit,
  ) {
    return sodium.runIsolated((_, _) async {
      // Eigene Instanz: das Sodium-Objekt vom Aufrufer lebt im Main-Isolate.
      final isoSodium = await SodiumSumoInit.init();
      return isoSodium.crypto.pwhash(
        outLen: isoSodium.crypto.secretBox.keyBytes,
        password: password.toCharArray(),
        salt: salt,
        opsLimit: opsLimit,
        memLimit: memLimit,
        alg: CryptoPwhashAlgorithm.argon2id13,
      );
    });
  }

  // Verpackt das eigene Keypair (priv 32 + pub 32 Bytes) passwortgeschuetzt:
  // KEK aus Passwort -> secretBox. Reine Funktion, kein Netzwerk/Storage.
  static Future<KeyBackup> wrapKeyBackup({
    required String password,
    required BackupSecretType secretType,
    required SecureKey privKey,
    required String pubKeyB64,
  }) async {
    final sodium = await SodiumSumoInit.init();
    final pwhash = sodium.crypto.pwhash;
    final secretBox = sodium.crypto.secretBox;

    // Salt bei JEDEM wrap neu: gleiches Passwort -> trotzdem anderer KEK.
    final salt = sodium.randombytes.buf(pwhash.saltBytes);
    final opsLimit = pwhash.opsLimitInteractive;
    final memLimit = pwhash.memLimitInteractive;
    final kek = await _deriveKek(sodium, password, salt, opsLimit, memLimit);

    final plaintext = Uint8List.fromList([
      ...privKey.extractBytes(),
      ...base64.decode(pubKeyB64),
    ]);
    final nonce = sodium.randombytes.buf(secretBox.nonceBytes);
    try {
      final ciphertext = secretBox.easy(
        message: plaintext,
        nonce: nonce,
        key: kek,
      );
      return KeyBackup(
        secretType: secretType,
        salt: base64.encode(salt),
        nonce: base64.encode(nonce),
        ciphertext: base64.encode(ciphertext),
        opslimit: opsLimit,
        memlimit: memLimit,
      );
    } finally {
      // Klartext-Private-Key und KEK nicht laenger im Speicher halten als noetig.
      plaintext.fillRange(0, plaintext.length, 0);
      kek.dispose();
    }
  }

  // Gegenstueck zu wrapKeyBackup. Reine Funktion, kein Netzwerk/Storage —
  // was mit den Keys passiert (speichern, Cache), entscheidet der Aufrufer.
  static Future<UnwrapResult> unwrapKeyBackup({
    required String password,
    required KeyBackup backup,
  }) async {
    final sodium = await SodiumSumoInit.init();
    final pwhash = sodium.crypto.pwhash;
    final secretBox = sodium.crypto.secretBox;
    final box = sodium.crypto.box;

    // 1) Decoden + Laengen pruefen, BEVOR wir eine Sekunde Argon2 verbrennen.
    final Uint8List salt, nonce, ciphertext;
    try {
      salt = base64.decode(backup.salt);
      nonce = base64.decode(backup.nonce);
      ciphertext = base64.decode(backup.ciphertext);
    } on FormatException {
      return UnwrapResult.corrupt();
    }
    final plainLength = box.secretKeyBytes + box.publicKeyBytes;
    if (salt.length != pwhash.saltBytes ||
        nonce.length != secretBox.nonceBytes ||
        ciphertext.length != plainLength + secretBox.macBytes) {
      return UnwrapResult.corrupt();
    }

    // 2) Parameter vom Server deckeln (siehe _maxBackupMemLimit).
    if (backup.opslimit < pwhash.opsLimitMin ||
        backup.opslimit > pwhash.opsLimitSensitive ||
        backup.memlimit < pwhash.memLimitMin ||
        backup.memlimit > _maxBackupMemLimit) {
      return UnwrapResult.corrupt();
    }

    // 3) KEK mit den GESPEICHERTEN Parametern, nicht den aktuellen
    //    Konstanten — sonst waeren alte Backups nach einer Erhoehung unlesbar.
    final kek = await _deriveKek(
      sodium,
      password,
      salt,
      backup.opslimit,
      backup.memlimit,
    );

    // 4) Entschluesseln. Falsches Passwort -> falscher KEK -> MAC passt nicht
    //    -> Sodium wirft. (Manipulierter Blob sieht genauso aus, der MAC kann
    //    beides nicht unterscheiden.)
    final Uint8List plaintext;
    try {
      plaintext = secretBox.openEasy(
        cipherText: ciphertext,
        nonce: nonce,
        key: kek,
      );
    } on SodiumException {
      return UnwrapResult.wrongPassword();
    } finally {
      kek.dispose();
    }

    try {
      // 5) Aufteilen. sublistView = Sicht ohne Kopie, damit das fillRange
      //    unten wirklich alle Klartext-Bytes erwischt.
      //    ACHTUNG: Beide Views zeigen nach dem finally nur noch Nullen!
      //    Nichts davon roh zurueckgeben — privKey wird per secureCopy
      //    kopiert, pubKey vor dem finally zu Base64 encodiert.
      final privKey = sodium.secureCopy(
        Uint8List.sublistView(plaintext, 0, box.secretKeyBytes),
      );
      final pubKey = Uint8List.sublistView(plaintext, box.secretKeyBytes);

      // 6) Gehoeren die beiden Keys zusammen?
      if (!_keypairMatches(sodium, privKey, pubKey)) {
        privKey.dispose();
        return UnwrapResult.corrupt();
      }
      return UnwrapResult.success(privKey, base64.encode(pubKey));
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
    }
  }

  // Selbsttest: Zufallswert an pubKey versiegeln, mit privKey oeffnen.
  // Klappt das nicht, stammt der Blob nicht von einem echten Keypair.
  static bool _keypairMatches(
    SodiumSumo sodium,
    SecureKey privKey,
    Uint8List pubKey,
  ) {
    final box = sodium.crypto.box;
    final probe = sodium.randombytes.buf(16);
    try {
      final opened = box.sealOpen(
        cipherText: box.seal(message: probe, publicKey: pubKey),
        publicKey: pubKey,
        secretKey: privKey,
      );
      return listEquals(opened, probe);
    } on SodiumException {
      return false;
    }
  }

  //  Key-Backup: REST-Endpoints (/keys/backup)

  // PUT /keys/backup — Upsert, Backend antwortet immer 200 (nie 201).
  // false bei Netzfehler/422/5xx; der Aufrufer darf dann spaeter erneut
  // versuchen, das Keypair lokal ist davon nicht betroffen.
  static Future<bool> uploadBackup(KeyBackup backup) async {
    try {
      final response = await ApiClient.put(
        Uri.parse('$_baseUrl/keys/backup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(backup.toJson()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // GET /keys/backup — nur das eigene Backup.
  // Nur ein echtes 404 heisst "kein Backup". Alles Unerwartete (auch Netz-
  // Exceptions, die ApiClient durchreicht, oder ein Body, der nicht parst)
  // wird zu error — im Zweifel lieber Restore abbrechen als neues Keypair.
  static Future<FetchBackupResult> fetchBackup() async {
    try {
      final response = await ApiClient.get(Uri.parse('$_baseUrl/keys/backup'));
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return FetchBackupResult.found(KeyBackup.fromJson(data));
        case 404:
          return FetchBackupResult.none();
        case 429:
          return FetchBackupResult.rateLimited();
        default:
          return FetchBackupResult.error();
      }
    } catch (_) {
      return FetchBackupResult.error();
    }
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
    _groupKeyCache[_groupCacheKey(groupId, version)] = key;
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
    final cached = _groupKeyCache[_groupCacheKey(groupId, version)];
    if (cached != null) return cached;
    final stored = await _storage.read(
      key: _groupKeyStorageKey(groupId, version),
    );
    if (stored == null) return null;
    final sodium = await SodiumInit.init();
    return _groupKeyCache[_groupCacheKey(groupId, version)] =
        sodium.secureCopy(base64.decode(stored));
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