import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:universal_notes_flutter/editor/document_adapter.dart';
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
    this.onFavorite,
    this.onTrash,
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

  /// Callback when swiped right (favorite toggle).
  final void Function(Note)? onFavorite;

  /// Callback when swiped left (move to trash).
  final void Function(Note)? onTrash;

  // ⚡ Bolt: Memoize DateFormat for better performance.
  static final _dateFormat = DateFormat('d MMM. yyyy');

  // static const _gradientDecoration = ... (Removed duplicate/unused)

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  // String _plainTextContent = '';
  // ⚡ Bolt: Hoisting the gradient decoration for performance.
  // This avoids re-creating the BoxDecoration on every build, which is
  // a common performance anti-pattern in Flutter.
  static final _gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.black.withAlpha(153), // 0.6 alpha
        Colors.transparent,
        Colors.black.withAlpha(204), // 0.8 alpha
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  @override
  void initState() {
    super.initState();
    // _plainTextContent = _computePlainText(widget.note.content);
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note.content != oldWidget.note.content) {
      // _plainTextContent = _computePlainText(widget.note.content);
    }
  }

  // ⚡ Bolt: Caching the plain text content of a note.
  // Parsing JSON on every build is expensive. This computes it once
  // when the widget is created or when the note content changes.
  // String _computePlainText(String jsonContent) {
  //   if (jsonContent.isEmpty) {
  //     return '';
  //   }
  //   return DocumentAdapter.fromJson(jsonContent).toPlainText();
  // }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.note.imageUrl?.isNotEmpty ?? false;

    final card = Card(
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
        child: Semantics(
          label: widget.note.title.isNotEmpty
              ? 'Nota: ${widget.note.title}'
              : 'Nota Sem Título',
          hint:
              'Modificado em '
              '${NoteCard._dateFormat.format(widget.note.lastModified)}',
          button: true,
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
                decoration: _gradientDecoration,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Favorite indicator
                    if (widget.note.isFavorite)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Icon(Icons.star, color: Colors.amber, size: 20),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      NoteCard._dateFormat.format(widget.note.lastModified),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // If no swipe callbacks, return plain card
    if (widget.onFavorite == null && widget.onTrash == null) {
      return card;
    }

    // Wrap with Dismissible for swipe gestures
    return Dismissible(
      key: Key(widget.note.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right → Toggle favorite
          widget.onFavorite?.call(widget.note);
          return false; // Don't dismiss, just toggle
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left → Move to trash
          widget.onTrash?.call(widget.note);
          return false; // Don't dismiss, let callback handle it
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          widget.note.isFavorite ? Icons.star_border : Icons.star,
          color: Colors.white,
          size: 32,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: card,
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
