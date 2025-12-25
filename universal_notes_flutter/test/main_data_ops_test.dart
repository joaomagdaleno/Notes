@Tags(['widget'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupTestEnvironment());
  setUp(() async => setupTest());
  tearDown(() async => tearDownTest());

  group('NotesScreen Data Operations', () {
    testWidgets('displays notes when available', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final testNote = Note(
        id: '2',
        title: 'Test Note 2',
        content: 'Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'user1',
      );

      // Stub NoteRepository to return our test note
      when(
        () => NoteRepository.instance.getAllNotes(
          folderId: any(named: 'folderId'),
          tagId: any(named: 'tagId'),
          isFavorite: any(named: 'isFavorite'),
          isInTrash: any(named: 'isInTrash'),
        ),
      ).thenAnswer((_) async => [testNote]);

      // Refresh to pick up the new data
      await SyncService.instance.refreshLocalData();

      await pumpNotesScreen(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Note 2'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
