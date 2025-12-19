import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockFirestoreRepository extends Mock implements FirestoreRepository {
  @override
  Future<void> createUser(User user) {
    return super.noSuchMethod(
          Invocation.method(#createUser, [user]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirestoreRepository mockFirestoreRepository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestoreRepository = MockFirestoreRepository();
    authService = AuthService();
    authService.firebaseAuth = mockFirebaseAuth;
    authService.firestoreRepository = mockFirestoreRepository;
  });

  group('AuthService', () {
    test('signInWithEmailAndPassword calls firebaseAuth', () async {
      final email = 'test@example.com';
      final password = 'password';
      final mockCredential = MockUserCredential();

      when(
        mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) => Future.value(mockCredential));

      final result = await authService.signInWithEmailAndPassword(
        email,
        password,
      );

      expect(result, mockCredential);
    });

    test(
      'createUserWithEmailAndPassword calls firestoreRepository on success',
      () async {
        final email = 'test@example.com';
        final password = 'password';
        final mockCredential = MockUserCredential();
        final mockUser = MockUser();

        when(mockCredential.user).thenReturn(mockUser);
        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) => Future.value(mockCredential));

        final result = await authService.createUserWithEmailAndPassword(
          email,
          password,
        );

        expect(result, mockCredential);
        verify(mockFirestoreRepository.createUser(any)).called(1);
      },
    );

    test('signOut calls firebaseAuth.signOut', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) => Future.value());

      await authService.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });
}
