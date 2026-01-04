import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:universal_notes_flutter/config/auth_config.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';

/// Service for handling authentication.
class AuthService {
  /// Creates an [AuthService].
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreRepository? firestoreRepository,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestoreRepository =
            firestoreRepository ?? FirestoreRepository.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(clientId: AuthConfig.googleClientId);

  final FirebaseAuth _firebaseAuth;
  final FirestoreRepository _firestoreRepository;
  final GoogleSignIn _googleSignIn;

  /// Returns a stream of the authentication state.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();


  /// Signs in with email and password.
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Creates a new user with email and password.
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName(displayName);

      // Send verification email
      await credential.user!.sendEmailVerification();

      // Create user profile in Firestore
      try {
        await _firestoreRepository.createUser(credential.user!);
      } on Exception {
        await credential.user?.delete();
        rethrow;
      }
    }
    return credential;
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Signs in with Google.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    if (userCredential.user != null) {
      try {
        // 🛡️ Security: Ensure user profile is created. If this fails,
        // we must sign out to prevent an inconsistent state.
        await _firestoreRepository.createUser(userCredential.user!);
      } on Exception {
        // Fail securely by signing out the user if profile creation fails.
        await signOut();
        rethrow;
      }
    }
    return userCredential;
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
