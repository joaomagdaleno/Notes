@Tags(['widget'])
library;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupTestEnvironment());
  setUp(() async => await setupTest());
  tearDown(() async => await SyncService.instance.reset());

  group('NotesScreen Navigation', () {
    testWidgets('FAB navigates to note editor', (tester) async {
      await pumpNotesScreen(tester);
      final fab = find.byType(fluent.FilledButton);
      expect(fab, findsWidgets); // Standard Fluent filled button
      await tester.tap(fab.first);
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('shows correct title for default index', (tester) async {
      await pumpNotesScreen(tester);
      expect(find.text('All Notes'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping Favorites in drawer changes view', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Favorites'), findsAtLeastNWidgets(1));
      expect(find.text('Favorite Note'), findsOneWidget);
    });
  });
}
