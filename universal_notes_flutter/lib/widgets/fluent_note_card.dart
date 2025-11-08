import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';

class FluentNoteCard extends StatelessWidget {
  final Note note;
  final Future<Note> Function(Note) onSave;
  final Function(Note) onDelete;

  const FluentNoteCard({
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
          fluent.FluentPageRoute(
            builder: (context) => NoteEditorScreen(note: note, onSave: onSave),
          ),
        );
      },
      child: fluent.Card(
        padding: const EdgeInsets.all(12.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            style: fluent.FluentTheme.of(context).typography.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Text(
              _getPreviewText(note.content),
              style: fluent.FluentTheme.of(context).typography.body,
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            DateFormat('d MMM. yyyy').format(note.date),
            style: fluent.FluentTheme.of(context).typography.caption,
          ),
        ],
      ),
      ),
    );
  }
}

String _getPreviewText(String jsonContent) {
  try {
    final List<dynamic> delta = jsonDecode(jsonContent);
    final text = delta
        .where((op) => op is Map && op.containsKey('insert'))
        .map((op) => op['insert'].toString())
        .join('');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (e) {
    return '...';
  }
}
