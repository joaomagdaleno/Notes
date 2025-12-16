import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/tag.dart';

/// A dialog that shows a read-only preview of a note.
class NotePreviewDialog extends StatelessWidget {
  /// Creates a new instance of [NotePreviewDialog].
  const NotePreviewDialog({
    required this.note,
    required this.tags,
    super.key,
  });

  /// The note to display.
  final Note note;

  /// The list of tags associated with the note.
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final document = DocumentAdapter.fromJson(note.content);
    final formattedDate = DateFormat.yMMMd().add_Hms().format(note.date);

    return AlertDialog(
      title: Text(note.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedDate,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      tags.map((tag) => Chip(label: Text(tag.name))).toList(),
                ),
              ),
            const SizedBox(height: 16),
            RichText(text: document.toTextSpan()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
