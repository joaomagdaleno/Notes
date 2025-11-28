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
          ),
        ),
      ),
    );

    // Verify that the note's title and date are displayed.
    expect(find.text('Test Note'), findsOneWidget);
    expect(find.textContaining(note.date.day.toString()), findsOneWidget);
    expect(find.text('This is a test note.'), findsOneWidget);
  });

  testWidgets('tapping NoteCard navigates to editor',
      (WidgetTester tester) async {
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
          ),
        ),
      ),
    );

    await tester.tap(find.byType(NoteCard));
    await tester.pumpAndSettle();

    expect(find.text('Test Note'), findsOneWidget);
  });

  testWidgets('long-pressing NoteCard shows context menu',
      (WidgetTester tester) async {
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
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(NoteCard));
    await tester.pump();

    expect(find.text('Favoritar'), findsOneWidget);
  });

  group('getPreviewText', () {
    test('extracts text from valid JSON', () {
      const json = '[{"insert":"Hello World"},{"insert":"\\n"}]';
      expect(getPreviewText(json), 'Hello World');
    });

    test('returns ellipsis for invalid JSON', () {
      const json = 'invalid-json';
      expect(getPreviewText(json), '...');
    });
  });
}
