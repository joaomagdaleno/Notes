import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// A service for encrypting and decrypting note content using AES-256-GCM.
///
/// This service provides secure encryption with password-based key derivation
/// using PBKDF2, and supports a recovery key mechanism for password recovery.
class EncryptionService {
  EncryptionService._();

  static final _algorithm = AesGcm.with256bits();
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;
  static const _pbkdf2Iterations = 100000;

  // === Criptografia Principal ===

  /// Derives an AES-256 key from a password using PBKDF2.
  static Future<SecretKey> deriveKey(String password, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// Encrypts plaintext content using AES-256-GCM.
  ///
  /// Returns a base64-encoded string containing:
  /// salt (16 bytes) + nonce (12 bytes) + ciphertext + mac (16 bytes)
  static Future<String> encrypt(String plaintext, String password) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(_saltLength, (_) => random.nextInt(256)),
    );
    final nonce = List.generate(_nonceLength, (_) => random.nextInt(256));

    final key = await deriveKey(password, salt);

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    // Concatenate: salt + nonce + ciphertext + mac
    final result = Uint8List.fromList([
      ...salt,
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64Encode(result);
  }

  /// Decrypts ciphertext that was encrypted with [encrypt].
  ///
  /// Throws an exception if the password is incorrect or data is corrupted.
  static Future<String> decrypt(String ciphertext, String password) async {
    final bytes = base64Decode(ciphertext);

    if (bytes.length < _saltLength + _nonceLength + _macLength) {
      throw const FormatException('Invalid ciphertext: too short');
    }

    final salt = Uint8List.fromList(bytes.sublist(0, _saltLength));
    final nonce = bytes.sublist(_saltLength, _saltLength + _nonceLength);
    final cipherBytes = bytes.sublist(
      _saltLength + _nonceLength,
      bytes.length - _macLength,
    );
    final macBytes = bytes.sublist(bytes.length - _macLength);

    final key = await deriveKey(password, salt);

    final secretBox = SecretBox(
      cipherBytes,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    try {
      final decrypted = await _algorithm.decrypt(secretBox, secretKey: key);
      return utf8.decode(decrypted);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Incorrect password or corrupted data');
    }
  }

  /// Verifies if a password can decrypt the given ciphertext.
  static Future<bool> verifyPassword(
    String ciphertext,
    String password,
  ) async {
    try {
      await decrypt(ciphertext, password);
      return true;
    } on FormatException {
      return false;
    }
  }

  // === Sistema de Recuperação ===

  /// Generates a random 32-byte recovery key encoded as base64.
  static String generateRecoveryKey() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    return base64Encode(bytes);
  }

  /// Encrypts the recovery key with the user's password.
  ///
  /// This encrypted recovery key should be stored in Firestore.
  static Future<String> encryptRecoveryKey(
    String recoveryKey,
    String password,
  ) => encrypt(recoveryKey, password);

  /// Decrypts the recovery key using the user's password.
  static Future<String> decryptRecoveryKey(
    String encryptedRecoveryKey,
    String password,
  ) => decrypt(encryptedRecoveryKey, password);

  /// Re-encrypts content with a new password.
  ///
  /// Used during password recovery to update encrypted notes.
  static Future<String> reEncrypt(
    String currentCiphertext,
    String oldPassword,
    String newPassword,
  ) async {
    final plaintext = await decrypt(currentCiphertext, oldPassword);
    return encrypt(plaintext, newPassword);
  }
}
