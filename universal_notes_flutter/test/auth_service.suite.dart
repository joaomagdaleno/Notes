@Tags(['unit'])
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => const Stream.empty();
}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockFirestoreRepository extends Mock implements FirestoreRepository {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirestoreRepository mockFirestoreRepository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestoreRepository = MockFirestoreRepository();
    authService = AuthService(
      firebaseAuth: mockFirebaseAuth,
      firestoreRepository: mockFirestoreRepository,
    );

    registerFallbackValue(MockUser());
  });

  group('AuthService', () {
    test('signInWithEmailAndPassword calls firebaseAuth', () async {
      const email = 'test@example.com';
      const password = 'password';
      final mockCredential = MockUserCredential();

      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => mockCredential);

      final result = await authService.signInWithEmailAndPassword(
        email,
        password,
      );

      expect(result, mockCredential);
    });

    test(
      'createUserWithEmailAndPassword calls firestoreRepository on success',
      () async {
        const email = 'test@example.com';
        const password = 'password';
        final mockCredential = MockUserCredential();
        final mockUser = MockUser();

        when(() => mockCredential.user).thenReturn(mockUser);
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => mockCredential);

        when(
          () => mockFirestoreRepository.createUser(any()),
        ).thenAnswer((_) async => {});

        final result = await authService.createUserWithEmailAndPassword(
          email,
          password,
        );

        expect(result, mockCredential);
        verify(() => mockFirestoreRepository.createUser(mockUser)).called(1);
      },
    );

    test('signOut calls firebaseAuth.signOut', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

      await authService.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });
}
