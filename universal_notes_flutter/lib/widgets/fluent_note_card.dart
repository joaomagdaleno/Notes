import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/utils/text_helpers.dart';

/// A widget that displays a note as a card with a fluent design.
class FluentNoteCard extends StatelessWidget {
  /// Creates a new instance of [FluentNoteCard].
  const FluentNoteCard({
    required this.note,
    required this.onSave,
    required this.onDelete,
    required this.onTap,
    super.key,
  });
  /// The note to display.
  final Note note;
  /// The function to call when the note is saved.
  final Future<Note> Function(Note) onSave;
  /// The function to call when the note is deleted.
  final void Function(Note) onDelete;
  /// The function to call when the widget is tapped.
  /// If null, it will navigate to the [NoteEditorScreen].
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: fluent.Card(
        child: Padding(
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
                getPreviewText(note.content),
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
    ));
  }
}
