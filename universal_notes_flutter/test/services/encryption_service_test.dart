import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    const password = 'test-password';
    const plaintext = 'Hello, this is a secret note content.';

    test('encrypt and decrypt roundtrip should work', () async {
      final encrypted = await EncryptionService.encrypt(plaintext, password);
      expect(encrypted, isNotNull);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(plaintext));

      final decrypted = await EncryptionService.decrypt(encrypted, password);
      expect(decrypted, plaintext);
    });

    test('decrypt with wrong password should throw FormatException', () async {
      final encrypted = await EncryptionService.encrypt(plaintext, password);
      expect(
        () => EncryptionService.decrypt(encrypted, 'wrong-password'),
        throwsA(isA<FormatException>()),
      );
    });

    test('verifyPassword should return true for correct password', () async {
      final encrypted = await EncryptionService.encrypt(plaintext, password);
      final isValid = await EncryptionService.verifyPassword(
        encrypted,
        password,
      );
      expect(isValid, isTrue);
    });

    test('verifyPassword should return false for wrong password', () async {
      final encrypted = await EncryptionService.encrypt(plaintext, password);
      final isValid = await EncryptionService.verifyPassword(
        encrypted,
        'wrong',
      );
      expect(isValid, isFalse);
    });

    test('generateRecoveryKey should produce unique keys', () {
      final key1 = EncryptionService.generateRecoveryKey();
      final key2 = EncryptionService.generateRecoveryKey();
      expect(key1, isNot(key2));
      expect(base64Decode(key1).length, 32);
    });

    test('reEncrypt should work with new password', () async {
      final encryptedOld = await EncryptionService.encrypt(plaintext, 'old');
      final encryptedNew = await EncryptionService.reEncrypt(
        encryptedOld,
        'old',
        'new',
      );

      final decrypted = await EncryptionService.decrypt(encryptedNew, 'new');
      expect(decrypted, plaintext);

      expect(
        () => EncryptionService.decrypt(encryptedNew, 'old'),
        throwsA(isA<FormatException>()),
      );
    });

    test('encryptRecoveryKey and decryptRecoveryKey roundtrip', () async {
      final recoveryKey = EncryptionService.generateRecoveryKey();
      final encrypted = await EncryptionService.encryptRecoveryKey(
        recoveryKey,
        password,
      );
      final decrypted = await EncryptionService.decryptRecoveryKey(
        encrypted,
        password,
      );
      expect(decrypted, recoveryKey);
    });

    test(
      'decrypt should throw FormatException for invalid ciphertext',
      () async {
        expect(
          () => EncryptionService.decrypt(
            'invalid-base64-or-too-short',
            password,
          ),
          throwsA(anything),
        );
      },
    );
  });
}
