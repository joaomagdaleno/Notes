import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';

/// A widget that displays a note as a card.
class NoteCard extends StatefulWidget {
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
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  String _plainTextContent = '';

  @override
  void initState() {
    super.initState();
    _plainTextContent = _computePlainText(widget.note.content);
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note.content != oldWidget.note.content) {
      _plainTextContent = _computePlainText(widget.note.content);
    }
  }

  // ⚡ Bolt: Caching the plain text content of a note.
  // Parsing JSON on every build is expensive. This computes it once
  // when the widget is created or when the note content changes.
  String _computePlainText(String jsonContent) {
    if (jsonContent.isEmpty) {
      return '';
    }
    return DocumentAdapter.fromJson(jsonContent).toPlainText();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: () {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.localToGlobal(
              renderBox.size.center(Offset.zero),
            );
            _showContextMenu(context, offset);
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_plainTextContent.isNotEmpty)
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
                          _plainTextContent,
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
                  if (_plainTextContent.isNotEmpty) const SizedBox(height: 8),
                  Text(
                    widget.note.title.isNotEmpty
                        ? widget.note.title
                        : 'Sem Título',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NoteCard._dateFormat.format(widget.note.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (widget.note.isDraft)
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
    unawaited(
      ContextMenuHelper.showContextMenu(
        context: context,
        position: globalPosition,
        note: widget.note,
        onSave: widget.onSave,
        onDelete: widget.onDelete,
      ),
    );
  }
}
