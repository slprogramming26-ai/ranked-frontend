// Passwort-verschluesseltes Backup des eigenen E2EE-Keypairs.
// Der Server speichert nur diesen Blob — ohne das Passwort ist er wertlos.

import 'package:sodium/sodium.dart';

// Womit das Backup verschluesselt ist. Enum statt String, damit ein Tippfehler
// im Wire-Wert ('login_password' / 'custom') nicht erst als 422 vom Backend
// auffaellt.
enum BackupSecretType {
  loginPassword('login_password'),
  custom('custom');

  final String wireValue;
  const BackupSecretType(this.wireValue);

  static BackupSecretType fromWire(String value) =>
      values.firstWhere((t) => t.wireValue == value);
}

// 1:1 das JSON von GET/PUT /keys/backup (snake_case wie im Backend).
// salt, nonce, ciphertext sind Base64-Strings.
class KeyBackup {
  final BackupSecretType secretType;
  final String salt;
  final String nonce;
  final String ciphertext;
  final int opslimit;
  final int memlimit;

  const KeyBackup({
    required this.secretType,
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.opslimit,
    required this.memlimit,
  });

  // updated_at kommt nur beim GET mit und wird hier nicht gebraucht.
  factory KeyBackup.fromJson(Map<String, dynamic> json) => KeyBackup(
    secretType: BackupSecretType.fromWire(json['secret_type'] as String),
    salt: json['salt'] as String,
    nonce: json['nonce'] as String,
    ciphertext: json['ciphertext'] as String,
    opslimit: json['opslimit'] as int,
    memlimit: json['memlimit'] as int,
  );

  Map<String, dynamic> toJson() => {
    'secret_type': secretType.wireValue,
    'salt': salt,
    'nonce': nonce,
    'ciphertext': ciphertext,
    'opslimit': opslimit,
    'memlimit': memlimit,
  };
}

// Ergebnis von KeyService.unwrapKeyBackup.
// wrongPassword = MAC passt nicht (falsches Passwort ODER manipulierter Blob).
// corrupt       = Blob kaputt/unplausibel (Base64, Laengen, Parameter,
//                 Keys passen nicht zusammen) — erneutes Tippen hilft nicht.
enum UnwrapStatus { success, wrongPassword, corrupt }

class UnwrapResult {
  final UnwrapStatus status;
  final SecureKey? privKey; // nur bei success
  final String? pubKeyB64; // nur bei success
  const UnwrapResult._(this.status, {this.privKey, this.pubKeyB64});

  factory UnwrapResult.success(SecureKey privKey, String pubKeyB64) =>
      UnwrapResult._(
        UnwrapStatus.success,
        privKey: privKey,
        pubKeyB64: pubKeyB64,
      );
  factory UnwrapResult.wrongPassword() =>
      const UnwrapResult._(UnwrapStatus.wrongPassword);
  factory UnwrapResult.corrupt() => const UnwrapResult._(UnwrapStatus.corrupt);
}

// Ergebnis von KeyService.fetchBackup (GET /keys/backup).
// found       = Backup da -> Passwort abfragen + unwrap.
// none        = 404, sicher kein Backup -> Erstgeraet, neues Keypair ok.
// rateLimited = 429 (10/min) -> Wartehinweis.
// error       = Netz weg / 5xx / Unerwartetes. Hier auf KEINEN FALL ein neues
//               Keypair erzeugen — sonst ueberschreibt PUT /keys den Pubkey
//               und die History ist weg (genau der Bug, den das Backup loest).
enum FetchBackupStatus { found, none, rateLimited, error }

class FetchBackupResult {
  final FetchBackupStatus status;
  final KeyBackup? backup; // nur bei found
  const FetchBackupResult._(this.status, {this.backup});

  factory FetchBackupResult.found(KeyBackup backup) =>
      FetchBackupResult._(FetchBackupStatus.found, backup: backup);
  factory FetchBackupResult.none() =>
      const FetchBackupResult._(FetchBackupStatus.none);
  factory FetchBackupResult.rateLimited() =>
      const FetchBackupResult._(FetchBackupStatus.rateLimited);
  factory FetchBackupResult.error() =>
      const FetchBackupResult._(FetchBackupStatus.error);
}
