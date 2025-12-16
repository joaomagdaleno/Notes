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
    final bool hasImage = widget.note.imageUrl?.isNotEmpty ?? false;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias, // Important for the image background
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
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                widget.note.imageUrl!,
                fit: BoxFit.cover,
              ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.note.title.isNotEmpty
                        ? widget.note.title
                        : 'Sem Título',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NoteCard._dateFormat.format(widget.note.lastModified),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
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
