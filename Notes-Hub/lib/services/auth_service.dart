import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes_hub/config/auth_config.dart';
import 'package:notes_hub/repositories/firestore_repository.dart';

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
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(clientId: AuthConfig.googleClientId);

  final FirebaseAuth _firebaseAuth;
  final FirestoreRepository _firestoreRepository;
  final GoogleSignIn _googleSignIn;

  /// Returns a stream of the authentication state.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Private helper to sync user profile to Firestore.
  Future<void> _syncUserProfile(User user) async {
    try {
      await _firestoreRepository.createUser(user);
    } on Exception {
      // 🛡️ Sentinel: Rethrow the exception to ensure the caller can handle
      // the failure. Swallowing this exception leads to an inconsistent user
      // state where an authenticated user has no corresponding profile data.
      rethrow;
    }
  }

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
        await _syncUserProfile(credential.user!);
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
    // 🛡️ Sentinel: This try-catch block is a critical security measure.
    // If creating the user profile fails, we MUST roll back the Firebase
    // authentication by signing the user out. This prevents the app from
    // getting into an inconsistent state where a user is authenticated but
    // has no profile data, which is a recipe for crashes and bugs.
    if (userCredential.user != null) {
      try {
        await _syncUserProfile(userCredential.user!);
      } on Exception {
        // 🛡️ Sentinel: If profile sync fails, sign out the user to prevent
        // an inconsistent state. This is a critical rollback mechanism.
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
