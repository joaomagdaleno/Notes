@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupTestEnvironment());
  setUp(() async => await setupTest());
  tearDown(() async => await SyncService.instance.reset());

  group('NotesScreen Data Operations', () {
    testWidgets('displays notes when available', (tester) async {
      final mockFirestore = createDefaultMockRepository([
        Note(
          id: '1',
          title: 'Test Note 1',
          content: 'Content 1',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          ownerId: 'user1',
        ),
      ]);
      SyncService.instance.firestoreRepository = mockFirestore;
      await SyncService.instance.init();

      await pumpNotesScreen(tester);
      await tester.pump();
      expect(find.text('Test Note 1'), findsOneWidget);
    });

    testWidgets('shows only non-trash notes by default', (tester) async {
      final mockFirestore = createDefaultMockRepository([
        Note(
          id: '1',
          title: 'Normal Note',
          content: 'Content',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          ownerId: 'user1',
        ),
        Note(
          id: '2',
          title: 'Trash Note',
          content: 'Content',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          ownerId: 'user1',
          isInTrash: true,
        ),
      ]);
      SyncService.instance.firestoreRepository = mockFirestore;
      await SyncService.instance.init();

      await pumpNotesScreen(tester);
      expect(find.text('Normal Note'), findsOneWidget);
      expect(find.text('Trash Note'), findsNothing);
    });
  });
}
