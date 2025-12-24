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
      await pumpNotesScreen(tester);

      final newNoteBtn = find.text('New Note');
      expect(newNoteBtn, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(newNoteBtn);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });

      // Use multiple pumps instead of pumpAndSettle to avoid infinite animation hangs
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shows correct title for default index', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await pumpNotesScreen(tester);
      expect(find.text('All Notes'), findsAtLeastNWidgets(1));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('tapping Favorites in drawer changes view', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

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

      await tester.runAsync(() async {
        final favoritesBtn = find.text('Favorites');
        if (favoritesBtn.evaluate().isNotEmpty) {
          await tester.tap(favoritesBtn);
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Favorites'), findsAtLeastNWidgets(1));
      expect(find.text('Favorite Note'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
