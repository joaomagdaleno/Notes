@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/storage_service.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'note_card_test.mocks.dart';

@GenerateMocks([StorageService, FirestoreRepository, NoteRepository])
void main() {
  late MockStorageService mockStorageService;
  late MockFirestoreRepository mockFirestoreRepository;
  late MockNoteRepository mockNoteRepository;

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

  testWidgets('NoteCard displays note', (WidgetTester tester) async {
    final note = Note(
      id: '1',
      title: 'Test Note',
      content: '[{"type":"text","spans":[{"text":"This is a test note."}]}]',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onSave: (note) async => note,
            onDelete: (note) {},
            onTap: () {},
          ),
        ),
      ),
    );

    // Verify that the note's title and date are displayed.
    expect(find.text('Test Note'), findsOneWidget);
    expect(find.textContaining(note.date.day.toString()), findsOneWidget);
    expect(find.text('This is a test note.'), findsOneWidget);
  });

  testWidgets('tapping NoteCard calls onTap callback', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    final note = Note(
      id: '1',
      title: 'Test Note',
      content: '',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onSave: (note) async => note,
            onDelete: (note) {},
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    // Find the InkWell widget inside the Card and tap on it
    final inkWellFinder = find.descendant(
      of: find.byType(Card),
      matching: find.byType(InkWell),
    );
    await tester.tap(inkWellFinder);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets(
    'tapping NoteCard navigates to NoteEditorScreen when onTap null',
    (WidgetTester tester) async {
      final note = Note(
        id: '1',
        title: 'Test Note',
        content: r'[{"insert":"Content\n"}]',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'user1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: NoteCard(
                note: note,
                onSave: (note) async => note,
                onDelete: (note) {},
                // onTap is null - should trigger default navigation
              ),
            ),
          ),
        ),
      );

      // Tap on the card
      final inkWellFinder = find.descendant(
        of: find.byType(Card),
        matching: find.byType(InkWell),
      );
      await tester.tap(inkWellFinder);
      await tester.pumpAndSettle();

      // Should navigate to NoteEditorScreen
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      // Check for the note title in the AppBar
      expect(find.text('Edit Note'), findsOneWidget);
    },
  );

  testWidgets('long press on NoteCard shows context menu', (
    WidgetTester tester,
  ) async {
    final note = Note(
      id: '1',
      title: 'Test Note',
      content: r'[{"insert":"Content\n"}]',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: NoteCard(
              note: note,
              onSave: (note) async => note,
              onDelete: (note) {},
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // Long press on the card
    final inkWellFinder = find.descendant(
      of: find.byType(Card),
      matching: find.byType(InkWell),
    );
    await tester.longPress(inkWellFinder);
    await tester.pumpAndSettle();

    // Context menu should appear with delete option
    expect(find.text('Mover para a lixeira'), findsOneWidget);
  });
}
