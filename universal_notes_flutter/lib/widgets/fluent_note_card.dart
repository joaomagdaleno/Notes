import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';

/// A widget that displays a note as a card with a fluent design.
class FluentNoteCard extends StatelessWidget {
  /// The note to display.
  final Note note;
  /// The function to call when the note is saved.
  final Future<Note> Function(Note) onSave;

  /// The function to call when the note is deleted.
  final void Function(Note) onDelete;

  /// Creates a new instance of [FluentNoteCard].
  const FluentNoteCard({
    required this.note,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          fluent.FluentPageRoute<void>(
            builder: (context) => NoteEditorScreen(note: note, onSave: onSave),
          ),
        );
      },
      child: fluent.Card(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: fluent.FluentTheme.of(context).typography.bodyLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                _getPreviewText(note.content),
                style: fluent.FluentTheme.of(context).typography.body,
                overflow: TextOverflow.ellipsis,
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 8),
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
    final delta = jsonDecode(jsonContent) as List<dynamic>;
    final text = delta
        .where(
          (dynamic op) => op is Map && op.containsKey('insert'),
        )
        .map((dynamic op) => op['insert'].toString())
        .join();
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (e) {
    return '...';
  }
}
