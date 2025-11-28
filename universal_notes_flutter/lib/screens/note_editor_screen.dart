import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';

class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({
    this.note,
    required this.onSave,
    super.key,
  });

  final Note? note;
  final Future<Note> Function(Note) onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note == null ? 'New Note' : 'Edit Note'),
      ),
      body: const Center(
        child: Text('This is a placeholder for the Note Editor screen.'),
      ),
    );
  }
}
