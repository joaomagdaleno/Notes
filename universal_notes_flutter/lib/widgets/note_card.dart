import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onSave;

  const NoteCard({super.key, required this.note, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(note: note, onSave: onSave),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    note.contentPreview,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM. yyyy').format(note.date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
