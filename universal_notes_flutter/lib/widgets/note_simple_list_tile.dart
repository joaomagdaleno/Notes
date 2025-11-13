import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';

/// A widget that displays a note as a simple list tile.
class NoteSimpleListTile extends StatelessWidget {
  /// Creates a new instance of [NoteSimpleListTile].
  const NoteSimpleListTile({
    required this.note,
    required this.onSave,
    required this.onDelete,
    super.key,
  });
  /// The note to display.
  final Note note;
  /// The function to call when the note is saved.
  final Future<Note> Function(Note) onSave;
  /// The function to call when the note is deleted.
  final void Function(Note) onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => NoteEditorScreen(
              note: note,
              onSave: onSave,
            ),
          ),
        );
      },
      onLongPressDown: (details) {
        ContextMenuHelper.showContextMenu(
          context: context,
          position: details.globalPosition,
          note: note,
          onSave: onSave,
          onDelete: onDelete,
        );
      },
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          color: Colors.grey[300],
          child: const Icon(Icons.image_outlined, color: Colors.grey),
        ),
        title: Text(note.title),
        trailing: Text(DateFormat('d MMM').format(note.date)),
      ),
    );
  }
}
