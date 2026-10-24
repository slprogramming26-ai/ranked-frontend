// =============================================================================
//  KeySetup — sorgt beim Login/Registrierung dafuer, dass das E2EE-Keypair da ist
// =============================================================================
//  Einzige Stelle, an der Keypairs ERZEUGT oder aus dem Backup WIEDERHERGESTELLT
//  werden — weil nur hier das Passwort vorliegt. Der MessengerController laedt
//  nur noch und vergleicht, erzeugt nie (beim Session-Restore fehlt das
//  Passwort).
//
//  Grundregel: Der eigene Pubkey auf dem Server ist die aktuelle Schluessel-
//  Generation. Ein vorhandener Server-Pubkey wird NIE still ueberschrieben —
//  nur beim allerersten Key (Server 404) oder per startFresh nach
//  Bestaetigung durch den User.
//
//  KeyService = Krypto + REST, KeySetup = der Ablauf drumherum.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:sodium/sodium.dart';

import 'key_backup.dart';
import 'key_service.dart';

// ready         = Keys lokal da, weiter in die App.
// needsPassword = Backup da, aber das Passwort passt nicht (Passwort woanders
//                 geaendert, oder eigenes Backup-Passwort) -> Dialog fragen.
// noRecovery    = alte Chats sind nicht wiederherstellbar (Backup kaputt,
//                 passt nicht zum Server-Pubkey, oder gar keins da, obwohl der
//                 Server schon einen Pubkey hat) -> nur noch startFresh.
// error         = Server nicht erreichbar / 429 -> Login abbrechen,
//                 KEIN neues Keypair.
enum KeySetupStatus { ready, needsPassword, noRecovery, error }

class KeySetupResult {
  final KeySetupStatus status;
  final KeyBackup? backup; // nur bei needsPassword (fuer den Retry)
  const KeySetupResult._(this.status, {this.backup});

  factory KeySetupResult.ready() => const KeySetupResult._(KeySetupStatus.ready);
  factory KeySetupResult.needsPassword(KeyBackup backup) =>
      KeySetupResult._(KeySetupStatus.needsPassword, backup: backup);
  factory KeySetupResult.noRecovery() =>
      const KeySetupResult._(KeySetupStatus.noRecovery);
  factory KeySetupResult.error() => const KeySetupResult._(KeySetupStatus.error);
}

class KeySetup {
  // Hinweis fuer den Login-Screen nach einem Logout, den der Nutzer nicht
  // selbst ausgeloest hat (z.B. Key auf anderem Geraet zurueckgesetzt).
  // take... liest und loescht in einem Schritt, damit er nur einmal erscheint.
  static String? _logoutNotice;
  static void setLogoutNotice(String notice) => _logoutNotice = notice;
  static String? takeLogoutNotice() {
    final notice = _logoutNotice;
    _logoutNotice = null;
    return notice;
  }

  // Nach erfolgreichem Login, VOR onLoginSuccess/_startMessenger.
  // passwordChanged: Login direkt nach "Passwort vergessen" -> das Backup ist
  // evtl. noch mit dem alten Passwort verpackt (siehe _syncBackup).
  static Future<KeySetupResult> afterLogin(
    int userId,
    String password, {
    bool passwordChanged = false,
  }) async {
    final uid = userId.toString();
    try {
      // Ohne echte Server-Antwort koennen wir nichts sicher entscheiden.
      final server = await KeyService.fetchOwnPublicKey(userId);
      if (!server.ok) return KeySetupResult.error();
      final serverPub = server.publicKey;

      // Keys ueberleben den Logout -> gleiches Geraet ist der Normalfall.
      if (await KeyService.hasLocalKeypair(uid)) {
        final localPub = await KeyService.loadLocalPublicKey(uid);
        if (serverPub == null || serverPub == localPub) {
          // Aktuell. Nur das Backup nachholen (fehlt / altes Passwort).
          await _syncBackup(uid, password, passwordChanged: passwordChanged);
          return KeySetupResult.ready();
        }
        // Server hat eine NEUERE Generation (startFresh auf anderem Geraet)
        // -> lokaler Key ist veraltet, weg damit und aus dem Backup holen.
        await KeyService.deleteKeypair(uid);
      }

      final fetched = await KeyService.fetchBackup();
      switch (fetched.status) {
        case FetchBackupStatus.found:
          return _restore(uid, fetched.backup!, password, password, serverPub);
        case FetchBackupStatus.none:
          // Kein Backup, aber der Server kennt schon einen Pubkey: dessen
          // Private Key ist fuer uns verloren. Nicht still ueberschreiben,
          // der User soll bewusst "Chats zuruecksetzen" waehlen.
          if (serverPub != null) return KeySetupResult.noRecovery();
          // Weder Pubkey noch Backup -> wirklich das erste Geraet.
          await _createFresh(uid, password);
          return KeySetupResult.ready();
        case FetchBackupStatus.rateLimited:
        case FetchBackupStatus.error:
          // Wir WISSEN nicht, ob es ein Backup gibt -> auf keinen Fall neu
          // erzeugen, sonst ueberschreibt der neue Pubkey den alten.
          return KeySetupResult.error();
      }
    } catch (e) {
      debugPrint('[E2EE] KeySetup.afterLogin fehlgeschlagen: $e');
      return KeySetupResult.error();
    }
  }

  // Nach der Registrierung: neuer Account hat garantiert weder Pubkey noch
  // Backup, also kein Fetch. Wirft bei Fehlern — der Aufrufer behandelt das
  // best-effort (Pubkey laedt der MessengerController hoch, das Backup holt
  // _syncBackup beim naechsten Login nach).
  static Future<void> afterRegistration(int userId, String password) =>
      _createFresh(userId.toString(), password);

  // Aus dem Dialog: anderes Passwort (altes Login- oder Backup-Passwort).
  static Future<KeySetupResult> retryWithPassword(
    int userId,
    KeyBackup backup,
    String enteredPassword,
    String loginPassword,
  ) async {
    try {
      final server = await KeyService.fetchOwnPublicKey(userId);
      if (!server.ok) return KeySetupResult.error();
      return await _restore(
        userId.toString(),
        backup,
        enteredPassword,
        loginPassword,
        server.publicKey,
      );
    } catch (e) {
      debugPrint('[E2EE] KeySetup.retryWithPassword fehlgeschlagen: $e');
      return KeySetupResult.error();
    }
  }

  // Notausgang "Chats zuruecksetzen": neues Keypair + neues Backup + neuer
  // Pubkey. Alte Nachrichten sind danach unlesbar — nur nach Bestaetigung!
  // Andere Geraete merken das am Pubkey-Vergleich und melden sich neu an.
  static Future<KeySetupResult> startFresh(int userId, String password) async {
    final uid = userId.toString();
    try {
      // Wirklich frisch: ensureKeypair wuerde sonst ein altes lokales
      // Keypair zurueckgeben statt ein neues zu erzeugen.
      await KeyService.deleteKeypair(uid);
      await _createFresh(uid, password);
      return KeySetupResult.ready();
    } catch (e) {
      debugPrint('[E2EE] KeySetup.startFresh fehlgeschlagen: $e');
      return KeySetupResult.error();
    }
  }

  // --- intern ---------------------------------------------------------------

  static Future<KeySetupResult> _restore(
    String uid,
    KeyBackup backup,
    String unwrapPassword,
    String loginPassword,
    String? serverPub,
  ) async {
    final r = await KeyService.unwrapKeyBackup(
      password: unwrapPassword,
      backup: backup,
    );
    switch (r.status) {
      case UnwrapStatus.success:
        // Backup gehoert zu einer ALTEN Generation (z.B. startFresh, dessen
        // Backup-Upload scheiterte)? Dann nicht speichern — der Controller
        // wuerde den Key sofort als veraltet erkennen -> Logout-Schleife.
        if (serverPub != null && r.pubKeyB64 != serverPub) {
          r.privKey!.dispose();
          return KeySetupResult.noRecovery();
        }
        await KeyService.storeKeypair(uid, r.privKey!, r.pubKeyB64!);
        // Mit einem ALTEN Login-Passwort geoeffnet -> gleich mit dem aktuellen
        // neu verpacken, sonst kommt der Dialog beim naechsten Geraet wieder.
        // Ein eigenes Backup-Passwort (custom) bleibt dagegen wie es ist.
        // Best-effort: scheitert es, ist das alte Backup ja noch da.
        if (backup.secretType == BackupSecretType.loginPassword &&
            unwrapPassword != loginPassword) {
          final rewrapped = await KeyService.wrapKeyBackup(
            password: loginPassword,
            secretType: BackupSecretType.loginPassword,
            privKey: r.privKey!,
            pubKeyB64: r.pubKeyB64!,
          );
          await KeyService.uploadBackup(rewrapped);
        }
        // Fehlt der Server-Pubkey (serverPub null), laedt ihn
        // MessengerController.init hoch.
        return KeySetupResult.ready();
      case UnwrapStatus.wrongPassword:
        return KeySetupResult.needsPassword(backup);
      case UnwrapStatus.corrupt:
        return KeySetupResult.noRecovery();
    }
  }

  // Reihenfolge ist Absicht: ERST das Backup, DANN der Pubkey. Scheitert das
  // Backup, bleibt der alte Server-Pubkey unangetastet und kein anderes Geraet
  // wird ausgesperrt. Andersrum koennte ein neuer Pubkey ohne passendes
  // Backup auf dem Server stehen.
  static Future<void> _createFresh(String uid, String password) async {
    final (pubKey, privKey) = await KeyService.ensureKeypair(uid);
    final backup = await KeyService.wrapKeyBackup(
      password: password,
      secretType: BackupSecretType.loginPassword,
      privKey: privKey,
      pubKeyB64: pubKey,
    );
    if (!await KeyService.uploadBackup(backup)) {
      throw Exception('Backup-Upload fehlgeschlagen');
    }
    if (!await KeyService.uploadPublicKey(pubKey)) {
      throw Exception('Pubkey-Upload fehlgeschlagen');
    }
  }

  // Lokaler Key ist aktuell -> Backup mit dem aktuellen Login-Passwort
  // hochladen, wenn
  //   - gar keins da ist (Bestandsnutzer ohne Backup), oder
  //   - das Passwort gerade zurueckgesetzt wurde: das Backup ist dann noch
  //     mit dem ALTEN verpackt, und das kennt der Nutzer nicht mehr. Ohne
  //     Neu-Verpacken fragte das naechste Geraet genau danach -> Chats weg.
  //     Entschluesseln muessen wir das alte Backup dafuer nicht: wir
  //     verpacken einfach den lokalen Key neu (passt ja zum Server-Pubkey).
  // Ein eigenes Backup-Passwort (custom) haengt nicht am Login -> bleibt.
  //
  // Best-effort. Bekannte Luecke: scheitert der Upload direkt nach einem
  // Reset, holt das niemand nach (spaetere Logins kommen ohne
  // passwordChanged). Sicher erkennen ginge nur per Probe-Entpacken bei
  // JEDEM Login (~1 s Argon2) -> bewusst nicht.
  static Future<void> _syncBackup(
    String uid,
    String password, {
    required bool passwordChanged,
  }) async {
    final fetched = await KeyService.fetchBackup();
    // Kein default: kommt ein neuer Status dazu, meckert der Compiler.
    final needsUpload = switch (fetched.status) {
      FetchBackupStatus.none => true,
      FetchBackupStatus.found =>
        passwordChanged &&
            fetched.backup!.secretType == BackupSecretType.loginPassword,
      // Wir wissen nicht, was auf dem Server liegt -> nichts anfassen.
      FetchBackupStatus.rateLimited || FetchBackupStatus.error => false,
    };
    if (!needsUpload) return;
    final SecureKey? privKey = await KeyService.getSecretKey(uid);
    final pubKey = await KeyService.loadLocalPublicKey(uid);
    if (privKey == null || pubKey == null) return;
    final backup = await KeyService.wrapKeyBackup(
      password: password,
      secretType: BackupSecretType.loginPassword,
      privKey: privKey,
      pubKeyB64: pubKey,
    );
    if (!await KeyService.uploadBackup(backup)) {
      debugPrint('[E2EE] Backup-Sync fehlgeschlagen (User $uid)');
    }
  }
}
