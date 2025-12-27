import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';

/// Service for handling authentication.
class AuthService {

  /// Creates an [AuthService].
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreRepository? firestoreRepository,
  }) : firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       firestoreRepository =
           firestoreRepository ?? FirestoreRepository.instance;
  /// The FirebaseAuth instance.
  final FirebaseAuth firebaseAuth;

  /// The FirestoreRepository instance.
  final FirestoreRepository firestoreRepository;

  /// Returns a stream of the authentication state.
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// Signs in with email and password.
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
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
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user profile in Firestore
        try {
          await firestoreRepository.createUser(credential.user!);
        } on Exception {
          // 🛡️ Sentinel: CRITICAL - If Firestore user creation fails,
          // the auth user must be deleted to prevent an inconsistent state
          // where a user exists in auth but not in the application database.
          // This is a "Fail Closed" security pattern.
          await credential.user?.delete();
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
    await firebaseAuth.signOut();
  }
}
