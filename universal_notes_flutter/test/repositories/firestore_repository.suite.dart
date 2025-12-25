@Tags(['unit'])
library;

// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/models/note.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late FirestoreRepository repository;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);

    repository = FirestoreRepository(
      firestore: mockFirestore,
      auth: mockAuth,
    );
  });

  group('FirestoreRepository', () {
    test('addNote successfully adds a note', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('user123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      when(() => mockCollection.add(any())).thenAnswer((_) async => mockDoc);

      final mockContentCollection = MockCollectionReference();
      final mockContentDoc = MockDocumentReference();
      when(
        () => mockDoc.collection('content'),
      ).thenReturn(mockContentCollection);
      when(() => mockContentCollection.doc('main')).thenReturn(mockContentDoc);
      when(() => mockContentDoc.set(any(), any())).thenAnswer((_) async => {});

      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.id).thenReturn('new-note-id');
      when(() => mockSnapshot.data()).thenReturn({
        'title': 'Test Title',
        'content': 'Test Content',
        'createdAt': Timestamp.now(),
        'lastModified': Timestamp.now(),
        'ownerId': 'user123',
        'memberIds': ['user123'],
      });
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);

      final note = await repository.addNote(
        title: 'Test Title',
        content: 'Test Content',
      );

      expect(note.id, 'new-note-id');
      expect(note.title, 'Test Title');
      verify(() => mockCollection.add(any())).called(1);
    });

    test('updateNote calls Firestore update methods', () async {
      final testNote = Note(
        id: 'note123',
        title: 'Updated Title',
        content: 'Updated Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'user123',
      );

      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.update(any())).thenAnswer((_) async => {});

      final mockContentCollection = MockCollectionReference();
      final mockContentDoc = MockDocumentReference();
      when(
        () => mockDoc.collection('content'),
      ).thenReturn(mockContentCollection);
      when(() => mockContentCollection.doc('main')).thenReturn(mockContentDoc);
      when(() => mockContentDoc.set(any(), any())).thenAnswer((_) async => {});

      await repository.updateNote(testNote);

      verify(() => mockDoc.update(any())).called(1);
      verify(() => mockContentDoc.set(any(), any())).called(1);
    });

    test('deleteNote deletes note and content', () async {
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      final mockContentCollection = MockCollectionReference();
      final mockContentDoc = MockDocumentReference();
      when(
        () => mockDoc.collection('content'),
      ).thenReturn(mockContentCollection);
      when(() => mockContentCollection.doc('main')).thenReturn(mockContentDoc);

      when(() => mockContentDoc.delete()).thenAnswer((_) async => {});
      when(() => mockDoc.delete()).thenAnswer((_) async => {});

      await repository.deleteNote('note123');

      verify(() => mockDoc.delete()).called(1);
      verify(() => mockContentDoc.delete()).called(1);
    });

    test('currentUser returns auth.currentUser', () {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(repository.currentUser, mockUser);
    });
  });
}
