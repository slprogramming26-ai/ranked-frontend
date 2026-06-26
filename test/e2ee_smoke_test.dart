import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sodium/sodium.dart';

void main() {
  late Sodium sodium;

  setUpAll(() {
    sodium = SodiumInit.init();
  });

  test('crypto_box: Bob kann Alice-Nachricht entschlüsseln', () {
    final box = sodium.crypto.box;

    final aliceKp = box.keyPair();
    final bobKp = box.keyPair();

    final message = utf8.encode('Hallo Bob, das ist E2EE!');
    final nonce = sodium.randombytes.buf(box.nonceBytes);

    // Alice verschlüsselt für Bob: (alicePriv + bobPub)
    final cipher = box.easy(
      message: message,
      nonce: nonce,
      publicKey: bobKp.publicKey,
      secretKey: aliceKp.secretKey,
    );

    // Bob entschlüsselt: (bobPriv + alicePub)
    final decrypted = box.openEasy(
      cipherText: cipher,
      nonce: nonce,
      publicKey: aliceKp.publicKey,
      secretKey: bobKp.secretKey,
    );

    expect(utf8.decode(decrypted), 'Hallo Bob, das ist E2EE!');
    print('✓ Bob liest: ${utf8.decode(decrypted)}');
  });

  test('crypto_box SYMMETRIE: Alice liest eigene gesendete Nachricht (Sync-Beweis)', () {
    final box = sodium.crypto.box;

    final aliceKp = box.keyPair();
    final bobKp = box.keyPair();

    final message = utf8.encode('Eigene Nachricht nach Sync');
    final nonce = sodium.randombytes.buf(box.nonceBytes);

    // Alice verschlüsselt für Bob
    final cipher = box.easy(
      message: message,
      nonce: nonce,
      publicKey: bobKp.publicKey,
      secretKey: aliceKp.secretKey,
    );

    // Alice öffnet ihre EIGENE Nachricht: gleiche Keys wie beim Verschlüsseln
    // ECDH(alicePriv, bobPub) == ECDH(bobPriv, alicePub) → gleicher Shared Key
    final selfDecrypted = box.openEasy(
      cipherText: cipher,
      nonce: nonce,
      publicKey: bobKp.publicKey,   // bobPub (wie beim Verschlüsseln)
      secretKey: aliceKp.secretKey, // alicePriv (wie beim Verschlüsseln)
    );

    expect(utf8.decode(selfDecrypted), 'Eigene Nachricht nach Sync');
    print('✓ Alice liest eigene Nachricht → REST-Sync funktioniert nach Reinstall');
  });

  test('Wire-Format v1: Prefix + base64(nonce||cipher) hin und zurück', () {
    final box = sodium.crypto.box;

    final aliceKp = box.keyPair();
    final bobKp = box.keyPair();

    const plaintext = 'Testnachricht für Wire-Format';
    final message = utf8.encode(plaintext);
    final nonce = sodium.randombytes.buf(box.nonceBytes);

    final cipher = box.easy(
      message: message,
      nonce: nonce,
      publicKey: bobKp.publicKey,
      secretKey: aliceKp.secretKey,
    );

    // Wire-Format: "v1:" + base64(nonce || ciphertext)
    final payload = Uint8List(nonce.length + cipher.length)
      ..setRange(0, nonce.length, nonce)
      ..setRange(nonce.length, nonce.length + cipher.length, cipher);
    final wire = 'v1:${base64.encode(payload)}';

    expect(wire.startsWith('v1:'), isTrue);

    // Empfang: v1-Prefix erkennen, dekodieren, entschlüsseln
    final raw = base64.decode(wire.substring(3));
    final rxNonce = raw.sublist(0, box.nonceBytes);
    final rxCipher = raw.sublist(box.nonceBytes);

    final decrypted = box.openEasy(
      cipherText: rxCipher,
      nonce: rxNonce,
      publicKey: aliceKp.publicKey,
      secretKey: bobKp.secretKey,
    );

    expect(utf8.decode(decrypted), plaintext);
    print('✓ Wire: "$wire"');
    print('✓ Entschlüsselt: ${utf8.decode(decrypted)}');
  });
}

