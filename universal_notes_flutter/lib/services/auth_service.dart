import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final FirestoreRepository _firestoreRepository;
  final GoogleSignIn _googleSignIn;

  // Configuration for Microsoft Auth
  // TODO: Replace with real values from Azure Portal
  static final Config _microsoftConfig = Config(
    tenant: 'common',
    clientId: 'YOUR_CLIENT_ID',
    scope: 'openid profile offline_access User.Read',
    redirectUri: 'msauth://com.example.universalNotesFlutter/auth',
    navigatorKey: GlobalKey<NavigatorState>(),
  );

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
      await _firestoreRepository.createUser(userCredential.user!);
    }
    return userCredential;
  }

  /// Signs in with Microsoft.
  Future<UserCredential?> signInWithMicrosoft() async {
    final oauth = AadOAuth(_microsoftConfig);
    await oauth.login();
    final accessToken = await oauth.getAccessToken();

    if (accessToken == null) return null;

    final credential = OAuthProvider('microsoft.com').credential(
      accessToken: accessToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _firestoreRepository.createUser(userCredential.user!);
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
