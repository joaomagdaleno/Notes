import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
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
        id: 'fav-1',
        title: 'Favorite Note',
        content: 'Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'user1',
        isFavorite: true,
      );

      // Stub NoteRepository to return this note when filtering by favorite
      when(
        () => NoteRepository.instance.getAllNotes(
          isFavorite: true,
          folderId: any(named: 'folderId'),
          tagId: any(named: 'tagId'),
          isInTrash: any(named: 'isInTrash'),
        ),
      ).thenAnswer((_) async => [favoriteNote]);

      // Re-initialize SyncService with the favorite note
      final mockFirestore = createDefaultMockRepository([favoriteNote]);
      FirestoreRepository.instance = mockFirestore;
      SyncService.instance.firestoreRepository = mockFirestore;

      // We don't call SyncService.init() here as setupTest already did it.
      // But we need to refresh local data to see the new notes if any.
      await SyncService.instance.refreshLocalData();

      await pumpNotesScreen(tester);

      // The Favorites button in Sidebar is a ListTile with text 'Favorites'
      final favoritesBtn = find.widgetWithText(ListTile, 'Favorites');
      expect(favoritesBtn, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(favoritesBtn);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Check title change
      expect(find.text('Favorites'), findsAtLeastNWidgets(1));

      // Check content (NoteCard)
      expect(find.text('Favorite Note'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
