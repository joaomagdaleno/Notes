import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';

class NoteSimpleListTile extends StatelessWidget {
  final Note note;
  final Future<Note> Function(Note) onSave;
  final Function(Note) onDelete;

  const NoteSimpleListTile({
    super.key,
    required this.note,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
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
