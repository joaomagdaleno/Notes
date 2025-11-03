import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';

class FluentNoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onSave;
  final Function(Note) onDelete;

  const FluentNoteCard({
    super.key,
    required this.note,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return fluent.Card(
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
              note.contentPreview,
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
    );
  }
}
