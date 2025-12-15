import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/models/note.dart';
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

  // ⚡ Bolt: Memoize DateFormat for performance.
  // Re-creating DateFormat on every build is inefficient.
  // This avoids repeated object creation.
  static final _dateFormat = DateFormat('d MMM. yyyy');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          DocumentAdapter.fromJson(note.content).toPlainText(),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  if (note.content.isNotEmpty) const SizedBox(height: 8),
                  Text(
                    note.title.isNotEmpty ? note.title : 'Sem Título',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateFormat.format(note.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (note.isDraft)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.flash_on,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    ContextMenuHelper.showContextMenu(
      context: context,
      position: globalPosition,
      note: note,
      onSave: onSave,
      onDelete: onDelete,
    );
  }
}
