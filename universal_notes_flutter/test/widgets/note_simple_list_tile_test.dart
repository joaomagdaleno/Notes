import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';

void main() {
  final note = Note(
    id: '1',
    title: 'Test Note',
    content: 'This is a test note.',
    date: DateTime.now(),
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

  testWidgets('tapping NoteSimpleListTile calls onTap',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteSimpleListTile(
            note: note,
            onDelete: (note) {},
            onSave: (note) async => note,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('long-pressing NoteSimpleListTile shows context menu',
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

    await tester.longPress(find.byType(NoteSimpleListTile));
    await tester.pump(); // pump to build the menu

    expect(find.text('Favoritar'), findsOneWidget);
    expect(find.text('Mover para a lixeira'), findsOneWidget);
  });

  testWidgets('tapping delete on context menu calls onDelete',
      (WidgetTester tester) async {
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
}
