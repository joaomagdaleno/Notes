import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';

void main() {
  final mockNote = Note(
    id: '1',
    title: 'Test',
    content: 'Test content',
    date: DateTime.now(),
  );

  testWidgets('NoteEditorScreen builds without crashing',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: NoteEditorScreen(
        note: mockNote,
        onSave: (note) async => note,
      ),
    ));

    // Verify that our screen is rendered.
    expect(find.byType(NoteEditorScreen), findsOneWidget);
  });
}
