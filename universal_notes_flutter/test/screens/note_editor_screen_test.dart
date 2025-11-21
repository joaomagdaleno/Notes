import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/models/note_model.dart';

void main() {
  testWidgets('NoteEditorScreen builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: NoteEditorScreen(note: Note(title: 'Test', content: 'Test content')),
    ));

    // Verify that our screen is rendered.
    expect(find.byType(NoteEditorScreen), findsOneWidget);
  });
}
