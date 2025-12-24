@Tags(['widget'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupTestEnvironment());
  setUp(() async => await setupTest());
  tearDown(() async => await tearDownTest());

  group('NotesScreen Navigation', () {
    testWidgets('FAB navigates to note editor', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await pumpNotesScreen(tester);
      final newNoteBtn = find.text('New Note');
      expect(newNoteBtn, findsOneWidget);
      await tester.tap(newNoteBtn);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows correct title for default index', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await pumpNotesScreen(tester);
      expect(find.text('All Notes'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping Favorites in drawer changes view', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final favoriteNote = Note(
        id: '1',
        title: 'Favorite Note',
        content: 'Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'user1',
        isFavorite: true,
      );
      SyncService.instance.firestoreRepository = createDefaultMockRepository([
        favoriteNote,
      ]);
      await SyncService.instance.init();

      await pumpNotesScreen(tester);
      await tester.tap(find.text('Favorites'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Favorites'), findsAtLeastNWidgets(1));
      expect(find.text('Favorite Note'), findsOneWidget);
    });
  });
}
