@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';

import '../test_helper.dart';

// Remove GenerateMocks as we use test_helper mocks
// @GenerateMocks([StorageService, FirestoreRepository, NoteRepository])
void main() {
  setUp(() async {
    await setupNotesTest();
    // Additional stubs for this suite specific behavior if needed
    // NoteRepository.instance IS MockNoteRepository from test_helper
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
    await tester.pump(const Duration(milliseconds: 100));

    // Context menu should appear with delete option
    expect(find.text('Mover para a lixeira'), findsOneWidget);
  });
}
