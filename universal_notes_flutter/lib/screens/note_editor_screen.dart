import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// The screen where the user can edit a note.
class NoteEditorScreen extends StatelessWidget {
  /// Creates a new instance of [NoteEditorScreen].
  const NoteEditorScreen({required this.onSave, super.key, this.note});

  /// The note to edit. If null, a new note will be created.
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
        child: Text('The editor will be built here.'),
      ),
    );
  }
}
