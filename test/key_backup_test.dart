import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ranked/key_backup.dart';
import 'package:ranked/key_service.dart';
import 'package:sodium/sodium.dart';

void main() {
  late Sodium sodium;
  late KeyPair kp;
  late KeyBackup backup;
  const password = 'mein-sicheres-passwort';

  setUpAll(() async {
    sodium = await SodiumInit.init();
    kp = sodium.crypto.box.keyPair();
    backup = await KeyService.wrapKeyBackup(
      password: password,
      secretType: BackupSecretType.loginPassword,
      privKey: kp.secretKey,
      pubKeyB64: base64.encode(kp.publicKey),
    );
  });

  // Kopie des Backups mit einzelnen geaenderten Feldern.
  KeyBackup modified({String? salt, String? ciphertext, int? memlimit}) =>
      KeyBackup(
        secretType: backup.secretType,
        salt: salt ?? backup.salt,
        nonce: backup.nonce,
        ciphertext: ciphertext ?? backup.ciphertext,
        opslimit: backup.opslimit,
        memlimit: memlimit ?? backup.memlimit,
      );

  test('wrap -> unwrap liefert dasselbe Keypair', () async {
    final r = await KeyService.unwrapKeyBackup(
      password: password,
      backup: backup,
    );
    expect(r.status, UnwrapStatus.success);
    expect(r.privKey!.extractBytes(), kp.secretKey.extractBytes());
    expect(r.pubKeyB64, base64.encode(kp.publicKey));
  });

  test('falsches Passwort -> wrongPassword', () async {
    final r = await KeyService.unwrapKeyBackup(
      password: 'falsches-passwort',
      backup: backup,
    );
    expect(r.status, UnwrapStatus.wrongPassword);
  });

  test('ein gekipptes Ciphertext-Byte -> wrongPassword (MAC)', () async {
    final bytes = base64.decode(backup.ciphertext);
    bytes[0] ^= 0x01;
    final r = await KeyService.unwrapKeyBackup(
      password: password,
      backup: modified(ciphertext: base64.encode(bytes)),
    );
    expect(r.status, UnwrapStatus.wrongPassword);
  });

  test('falsche Salt-Laenge -> corrupt', () async {
    final r = await KeyService.unwrapKeyBackup(
      password: password,
      backup: modified(salt: base64.encode(List.filled(8, 0))),
    );
    expect(r.status, UnwrapStatus.corrupt);
  });

  test('kaputtes Base64 -> corrupt', () async {
    final r = await KeyService.unwrapKeyBackup(
      password: password,
      backup: modified(salt: '###kein-base64###'),
    );
    expect(r.status, UnwrapStatus.corrupt);
  });

  test('memlimit ueber dem Deckel -> corrupt (kein OOM)', () async {
    final r = await KeyService.unwrapKeyBackup(
      password: password,
      backup: modified(memlimit: 2000000000),
    );
    expect(r.status, UnwrapStatus.corrupt);
  });

  test('priv + fremder pub -> corrupt (Selbsttest)', () async {
    final other = sodium.crypto.box.keyPair();
    final mismatched = await KeyService.wrapKeyBackup(
      password: password,
      secretType: BackupSecretType.custom,
      privKey: kp.secretKey,
      pubKeyB64: base64.encode(other.publicKey),
    );
    final r = await KeyService.unwrapKeyBackup(
      password: password,
      backup: mismatched,
    );
    expect(r.status, UnwrapStatus.corrupt);
  });

  test('JSON-Roundtrip mit Backend-Feldnamen', () {
    final json = backup.toJson();
    expect(json['secret_type'], 'login_password');
    final back = KeyBackup.fromJson({...json, 'updated_at': '2026-09-26'});
    expect(back.toJson(), json);
  });
}
