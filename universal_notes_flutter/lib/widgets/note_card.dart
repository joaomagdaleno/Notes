import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/utils/text_helpers.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';

/// A widget that displays a note as a card.
class NoteCard extends StatelessWidget {
  /// Creates a new instance of [NoteCard].
  const NoteCard({
    required this.note,
    required this.onSave,
    required this.onDelete,
    this.onTap,
    super.key,
  });
  /// The note to display.
  final Note note;
  /// The function to call when the note is saved.
  final Future<Note> Function(Note) onSave;
  /// The function to call when the note is deleted.
  final void Function(Note) onDelete;
  /// The function to call when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressDown: (details) async {
        await ContextMenuHelper.showContextMenu(
          context: context,
          position: details.globalPosition,
          note: note,
          onSave: onSave,
          onDelete: onDelete,
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap ??
              () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        NoteEditorScreen(note: note, onSave: onSave),
                  ),
                );
              },
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.content.isNotEmpty)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPreviewText(note.content),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (note.content.isNotEmpty) const SizedBox(height: 8),
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM. yyyy').format(note.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

