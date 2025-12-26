@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';
import '../test_helper.dart';

void main() {
  setUp(() async {
    await setupNotesTest();
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
    await tester.pump();

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
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Excluir permanentemente'));
    await tester.pump();

    expect(deleted, isTrue);
  });
}
