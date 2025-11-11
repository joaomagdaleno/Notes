import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteEditorScreen extends StatelessWidget {
  final Note? note;
  final Future<Note> Function(Note) onSave;

  const NoteEditorScreen({super.key, this.note, required this.onSave});

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
