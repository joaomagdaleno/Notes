import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/widgets/note_preview_dialog.dart';

/// A widget that displays a note as a card with a fluent design.
class FluentNoteCard extends StatefulWidget {
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

  // ⚡ Bolt: Memoize DateFormat for performance.
  // Re-creating DateFormat on every build is inefficient.
  // This avoids repeated object creation.
  static final _dateFormat = DateFormat('d MMM. yyyy');

  @override
  State<FluentNoteCard> createState() => _FluentNoteCardState();
}

class _FluentNoteCardState extends State<FluentNoteCard> {
  final _flyoutController = fluent.FlyoutController();
  String _plainTextContent = '';

  @override
  void initState() {
    super.initState();
    // ⚡ Bolt: Caching the plain text content of a note.
    // Parsing JSON and converting to plain text on every build is expensive.
    // This computes it once when the widget is created or when the note
    // content changes, making the build method much more efficient.
    _plainTextContent = _computePlainText(widget.note.content);
  }

  @override
  void didUpdateWidget(covariant FluentNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note.content != oldWidget.note.content) {
      setState(() {
        _plainTextContent = _computePlainText(widget.note.content);
      });
    }
  }

  String _computePlainText(String jsonContent) {
    if (jsonContent.isEmpty) return '';
    try {
      return DocumentAdapter.fromJson(jsonContent).toPlainText();
    } catch (e) {
      // Handle potential malformed JSON gracefully.
      return 'Error parsing content';
    }
  }

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  void _showContextMenu(Offset globalPosition) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.globalToLocal(globalPosition);

    unawaited(
      _flyoutController.showFlyout<void>(
        placementMode: fluent.FlyoutPlacementMode.topLeft,
        additionalOffset: offset.dy,
        builder: (context) {
          return fluent.MenuFlyout(
            items: [
              fluent.MenuFlyoutItem(
                text: const Text('Move to Trash'),
                leading: const fluent.Icon(fluent.FluentIcons.delete),
                onPressed: () async {
                  final updatedNote = widget.note.copyWith(isInTrash: true);
                  await widget.onSave(updatedNote);
                  if (context.mounted) {
                    fluent.Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPreview(BuildContext context) async {
    final noteWithContent = await NoteRepository.instance.getNoteWithContent(
      widget.note.id,
    );
    final tags = await NoteRepository.instance.getTagsForNote(widget.note.id);
    if (context.mounted) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) =>
              NotePreviewDialog(note: noteWithContent, tags: tags),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return fluent.FlyoutTarget(
      controller: _flyoutController,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) {
          _showContextMenu(details.globalPosition);
        },
        onLongPressStart: (details) {
          _showContextMenu(details.globalPosition);
        },
        child: fluent.Card(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.note.title,
                      style: fluent.FluentTheme.of(
                        context,
                      ).typography.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        _plainTextContent,
                        style: fluent.FluentTheme.of(context).typography.body,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FluentNoteCard._dateFormat.format(widget.note.date),
                      style: fluent.FluentTheme.of(context).typography.caption,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: fluent.IconButton(
                  icon: const fluent.Icon(fluent.FluentIcons.view),
                  onPressed: () => unawaited(_showPreview(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
