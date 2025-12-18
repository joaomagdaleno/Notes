import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';

/// Service for handling authentication.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Returns a stream of the authentication state.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Signs in with email and password.
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (_) {
      // Handle errors
      // print(e.message);
      return null;
    }
  }

  /// Creates a new user with email and password.
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user profile in Firestore
        try {
          final firestoreRepository = FirestoreRepository();
          await firestoreRepository.createUser(credential.user!);
        } on Exception {
          // Re-throwing the exception to allow the UI to handle the error,
          // for example, by showing a message to the user and preventing
          // them from proceeding in an inconsistent state.
          rethrow;
        }
      }
      return credential;
    } on FirebaseAuthException catch (_) {
      // Handle errors
      // print(e.message);
      return null;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
