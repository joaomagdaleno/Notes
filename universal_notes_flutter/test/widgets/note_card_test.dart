import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';

void main() {
  testWidgets('NoteCard displays note', (WidgetTester tester) async {
    final note = Note(
      title: 'Test Note',
      content: r'[{"insert":"This is a test note.\n"}]',
      date: DateTime.now(),
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
      title: 'Test Note',
      content: '',
      date: DateTime.now(),
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
        title: 'Test Note',
        content: r'[{"insert":"Content\n"}]',
        date: DateTime.now(),
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
    },
  );

  testWidgets('long press on NoteCard shows context menu', (
    WidgetTester tester,
  ) async {
    final note = Note(
      title: 'Test Note',
      content: r'[{"insert":"Content\n"}]',
      date: DateTime.now(),
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
