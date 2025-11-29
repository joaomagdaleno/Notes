import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
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

  testWidgets('tapping NoteCard calls onTap callback',
      (WidgetTester tester) async {
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

    // Find the Card widget and tap on its center
    final cardFinder = find.byType(Card);
    await tester.tap(cardFinder);
    await tester.pump();

    expect(tapped, isTrue);
  });
}
