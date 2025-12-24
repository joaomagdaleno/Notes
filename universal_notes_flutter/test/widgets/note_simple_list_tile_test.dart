@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'note_simple_list_tile_test.mocks.dart';

@GenerateMocks([StorageService, NoteRepository, FirestoreRepository])
void main() {
  late MockStorageService mockStorageService;
  late MockNoteRepository mockNoteRepository;
  late MockFirestoreRepository mockFirestoreRepository;

  setUp(() {
    mockStorageService = MockStorageService();
    mockNoteRepository = MockNoteRepository();
    mockFirestoreRepository = MockFirestoreRepository();
    StorageService.instance = mockStorageService;
    NoteRepository.instance = mockNoteRepository;
    FirestoreRepository.instance = mockFirestoreRepository;

    // Default stubs
    when(mockNoteRepository.getAllSnippets()).thenAnswer((_) async => []);
  });

  final note = Note(
    id: '1',
    title: 'Test Note',
    content: '[{"type":"text","spans":[{"text":"This is a test note."}]}]',
    createdAt: DateTime.now(),
    lastModified: DateTime.now(),
    ownerId: 'user1',
  );

  testWidgets('NoteSimpleListTile displays title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteSimpleListTile(
            note: note,
            onDelete: (note) {},
            onSave: (note) async => note,
          ),
        ),
      ),
    );

    expect(find.text('Test Note'), findsOneWidget);
  });

  testWidgets('tapping NoteSimpleListTile calls onTap', (tester) async {
    var tapped = false;
    final tile = NoteSimpleListTile(
      key: const ValueKey('tile_under_test'),
      note: note,
      onDelete: (_) {},
      onSave: (n) async => n,
      onTap: () => tapped = true,
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: tile)));

    // Find the ListTile and tap on it
    final listTileFinder = find.descendant(
      of: find.byKey(const ValueKey('tile_under_test')),
      matching: find.byType(ListTile),
    );
    await tester.tap(listTileFinder);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('long-pressing NoteSimpleListTile shows context menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteSimpleListTile(
            note: note,
            onDelete: (note) {},
            onSave: (note) async => note,
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(NoteSimpleListTile));
    await tester.pump(); // pump to build the menu

    expect(find.text('Favoritar'), findsOneWidget);
    expect(find.text('Mover para a lixeira'), findsOneWidget);
  });

  testWidgets('tapping delete on context menu calls onDelete', (
    WidgetTester tester,
  ) async {
    var deleted = false;
    final noteInTrash = note.copyWith(isInTrash: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteSimpleListTile(
            note: noteInTrash,
            onDelete: (note) {
              deleted = true;
            },
            onSave: (note) async => note,
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(NoteSimpleListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir permanentemente'));
    await tester.pump();

    expect(deleted, isTrue);
  });

  testWidgets(
    'tapping NoteSimpleListTile navigates to editor when onTap is null',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteSimpleListTile(
              note: note,
              onDelete: (note) {},
              onSave: (note) async => note,
            ),
          ),
        ),
      );

      // Find the ListTile and tap on it
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder);

      // Wait for navigation to complete
      await tester.pumpAndSettle();

      // Check if we've navigated to the NoteEditorScreen
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      // Check for the note title in the AppBar
      expect(find.text('Edit Note'), findsOneWidget);
    },
  );
}
