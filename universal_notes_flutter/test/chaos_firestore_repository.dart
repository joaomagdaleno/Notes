import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';

/// A test repository that can be configured to throw specific exceptions.
class ChaosFirestoreRepository extends Mock implements FirestoreRepository {
  bool failNextOperation = false;
  FirebaseException? forcedException;

  @override
  Future<void> updateNote(dynamic note) async {
    if (failNextOperation) {
      throw forcedException ??
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'Chaos Engineering: Firestore is unavailable',
          );
    }
    return super.noSuchMethod(
      Invocation.method(#updateNote, [note]),
      returnValue: Future<void>.value(),
    );
  }
}
