import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';

void main() {
  group('ContextMenuHelper', () {
    testWidgets('buildDefaultContextMenu', (WidgetTester tester) async {
      late Note savedNote;
      final note = Note(id: '1', title: 'Test', content: '');

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Builder(builder: (context) {
            final items = ContextMenuHelper.buildDefaultContextMenu(
              context,
              note,
              (n) => savedNote = n,
            );

            // Test "Favoritar"
            final favoriteItem = items[0] as PopupMenuItem;
            favoriteItem.onTap!();
            expect(savedNote.isFavorite, isTrue);

            // Test "Mover para a lixeira"
            final trashItem = items[1] as PopupMenuItem;
            trashItem.onTap!();
            expect(savedNote.isInTrash, isTrue);

            return Container();
          }),
        ),
      ));
    });

    testWidgets('buildTrashContextMenu', (WidgetTester tester) async {
      late Note savedNote;
      Note? deletedNote;
      final note = Note(id: '1', title: 'Test', content: '', isInTrash: true);

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Builder(builder: (context) {
            final items = ContextMenuHelper.buildTrashContextMenu(
              context,
              note,
              (n) => savedNote = n,
              (n) => deletedNote = n,
            );

            // Test "Restaurar"
            final restoreItem = items[0] as PopupMenuItem;
            restoreItem.onTap!();
            expect(savedNote.isInTrash, isFalse);

            // Test "Excluir permanentemente"
            final deleteItem = items[1] as PopupMenuItem;
            deleteItem.onTap!();
            expect(deletedNote, equals(note));

            return Container();
          }),
        ),
      ));
    });
  });
}
