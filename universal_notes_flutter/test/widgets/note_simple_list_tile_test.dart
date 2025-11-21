import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note_model.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';

void main() {
  final note = Note(
    id: 1,
    title: 'Test Note',
    content: 'This is a test note.',
    modifiedTime: DateTime.now(),
  );

  testWidgets('NoteSimpleListTile displays title and delete button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteSimpleListTile(
            note: note,
            onDelete: () {},
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Note'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });
}
