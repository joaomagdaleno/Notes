import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    test('generateRecoveryKey returns a valid key', () {
      final key = EncryptionService.generateRecoveryKey();
      expect(key, isNotEmpty);
      expect(
        key.length,
        greaterThan(20),
      ); // Base64 encoded 32 bytes is approx 44 chars
    });

    test('encryptRecoveryKey and decryptRecoveryKey match', () async {
      final recoveryKey = EncryptionService.generateRecoveryKey();
      const password = 'securePassword123';

      final encrypted = await EncryptionService.encryptRecoveryKey(
        recoveryKey,
        password,
      );

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(recoveryKey)));

      final decrypted = await EncryptionService.decryptRecoveryKey(
        encrypted,
        password,
      );

      expect(decrypted, equals(recoveryKey));
    });

    test('decryptRecoveryKey fails with wrong password', () async {
      final recoveryKey = EncryptionService.generateRecoveryKey();
      const password = 'securePassword123';
      const wrongPassword = 'wrongPassword';

      final encrypted = await EncryptionService.encryptRecoveryKey(
        recoveryKey,
        password,
      );

      expect(
        () async => EncryptionService.decryptRecoveryKey(
          encrypted,
          wrongPassword,
        ),
        throwsException,
      );
    });

    test('encrypt and decrypt match for Strings', () async {
      const content = 'Secret Note Content';
      const password = 'userPassword';

      final encrypted = await EncryptionService.encrypt(content, password);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(contains(content)));

      final decrypted = await EncryptionService.decrypt(encrypted, password);

      expect(decrypted, equals(content));
    });

    test('reEncrypt works correctly', () async {
      const content = 'Another Secret';
      const oldPassword = 'oldPassword';
      const newPassword = 'newPassword';

      final encrypted = await EncryptionService.encrypt(content, oldPassword);
      final reEncrypted = await EncryptionService.reEncrypt(
        encrypted,
        oldPassword,
        newPassword,
      );

      final decrypted = await EncryptionService.decrypt(
        reEncrypted,
        newPassword,
      );
      expect(decrypted, equals(content));
    });
  });
}
