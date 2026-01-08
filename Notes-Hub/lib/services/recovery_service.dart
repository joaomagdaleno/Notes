import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The result of a password recovery attempt.
enum RecoveryResult {
  /// Recovery was successful.
  success,

  /// The verification code was invalid.
  invalidCode,

  /// The verification code has expired.
  codeExpired,

  /// User is not logged in.
  notLoggedIn,

  /// No recovery key was found for this user.
  noRecoverySetup,
}

/// A service for managing 2FA password recovery.
///
/// This service handles:
/// - Sending verification codes via email
/// - Validating verification codes
/// - Storing/retrieving encrypted recovery keys from Firestore
class RecoveryService {
  /// Creates a new instance of [RecoveryService].
  RecoveryService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _recoveryCodesCollection = 'recovery_codes';
  static const _usersCollection = 'users';
  static const _codeExpirationMinutes = 10;

  /// Returns whether the current user can set up recovery.
  ///
  /// User must be logged in and have a verified email.
  bool get canSetupRecovery {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  /// Returns the current user's email, or null if not logged in.
  String? get userEmail => _auth.currentUser?.email;

  /// Sends a 6-digit verification code to the user's email.
  ///
  /// The code expires after [_codeExpirationMinutes] minutes.
  /// Returns the generated code (for testing purposes in debug mode).
  Future<String> sendVerificationCode() async {
    final user = _auth.currentUser;
    if (user?.email == null) {
      throw StateError('User is not logged in or has no email');
    }

    // Generate 6-digit code
    final random = Random.secure();
    final code = (100000 + random.nextInt(900000)).toString();
    final expiration = DateTime.now().add(
      const Duration(minutes: _codeExpirationMinutes),
    );

    // Store code hash in Firestore
    await _firestore.collection(_recoveryCodesCollection).doc(user!.uid).set({
      'codeHash': code.hashCode,
      'expiresAt': Timestamp.fromDate(expiration),
      'email': user.email,
      'attempts': 0,
    });

    // In production, use Cloud Functions to send custom email
    // For now, we'll use Firebase Auth's email verification as a workaround
    // The actual code would be sent via a Cloud Function
    await user.sendEmailVerification(
      ActionCodeSettings(
        url: 'https://universalnotes.app/recovery?code=$code',
        handleCodeInApp: true,
      ),
    );

    return code;
  }

  /// Validates the verification code entered by the user.
  ///
  /// Returns [RecoveryResult.success] if the code is valid.
  /// Increments attempt counter and deletes code after 5 failed attempts.
  Future<RecoveryResult> verifyCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) {
      return RecoveryResult.notLoggedIn;
    }

    final docRef = _firestore
        .collection(_recoveryCodesCollection)
        .doc(
          user.uid,
        );
    final doc = await docRef.get();

    if (!doc.exists) {
      return RecoveryResult.invalidCode;
    }

    final data = doc.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    final attempts = (data['attempts'] as int?) ?? 0;

    // Check if code has expired
    if (DateTime.now().isAfter(expiresAt)) {
      await docRef.delete();
      return RecoveryResult.codeExpired;
    }

    // Check if too many attempts
    if (attempts >= 5) {
      await docRef.delete();
      return RecoveryResult.invalidCode;
    }

    // Validate code
    final isValid = data['codeHash'] == code.hashCode;

    if (isValid) {
      // Delete code after successful verification
      await docRef.delete();
      return RecoveryResult.success;
    } else {
      // Increment attempt counter
      await docRef.update({'attempts': attempts + 1});
      return RecoveryResult.invalidCode;
    }
  }

  /// Saves the encrypted recovery key to Firestore.
  Future<void> saveEncryptedRecoveryKey(String encryptedKey) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not logged in');
    }

    await _firestore.collection(_usersCollection).doc(user.uid).set({
      'encryptedRecoveryKey': encryptedKey,
      'recoverySetupDate': FieldValue.serverTimestamp(),
      'hasEncryptedNotes': true,
    }, SetOptions(merge: true),);
  }

  /// Retrieves the encrypted recovery key from Firestore.
  Future<String?> getEncryptedRecoveryKey() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .get();
    return doc.data()?['encryptedRecoveryKey'] as String?;
  }

  /// Checks whether the user has set up recovery.
  Future<bool> hasRecoverySetup() async {
    final key = await getEncryptedRecoveryKey();
    return key != null && key.isNotEmpty;
  }

  /// Updates the encrypted recovery key after password change.
  Future<void> updateEncryptedRecoveryKey(String newEncryptedKey) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not logged in');
    }

    await _firestore.collection(_usersCollection).doc(user.uid).update({
      'encryptedRecoveryKey': newEncryptedKey,
      'recoveryKeyUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
