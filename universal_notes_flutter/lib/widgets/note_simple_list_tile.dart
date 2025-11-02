import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';

class NoteSimpleListTile extends StatelessWidget {
  final Note note;
  final Function(Note) onSave;

  const NoteSimpleListTile({
    super.key,
    required this.note,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
      leading: Container(
        width: 40,
        height: 40,
        color: Colors.grey[300],
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      ),
      title: Text(note.title),
      trailing: Text(DateFormat('d MMM').format(note.date)),
    );
  }
}
