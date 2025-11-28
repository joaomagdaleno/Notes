import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// A placeholder screen for editing a note.
class NoteEditorScreen extends StatelessWidget {
  /// Creates a new instance of [NoteEditorScreen].
  const NoteEditorScreen({
    this.note,
    required this.onSave,
    super.key,
  });

  final Note? note;
  /// The function to call when the note is saved.
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
