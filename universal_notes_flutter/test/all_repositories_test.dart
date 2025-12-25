/// Consolidated repository tests for Notes
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';

import 'repositories/firestore_repository.suite.dart' as firestore;
import 'repositories/note_repository.suite.dart' as note_repo;

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  setUp(() async {
    SyncService.resetInstance();
    NoteRepository.resetInstance();
    FirestoreRepository.instance = MockFirestoreRepository();
  });

  firestore.main();
  note_repo.main();
}
