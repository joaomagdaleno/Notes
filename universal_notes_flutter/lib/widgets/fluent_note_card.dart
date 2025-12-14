import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/utils/text_helpers.dart';

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

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return fluent.FlyoutTarget(
      controller: _flyoutController,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (d) {
          _flyoutController.showFlyout(
            autoModeConfiguration: fluent.FlyoutAutoConfiguration(
              preferredMode: fluent.FlyoutPlacementMode.topCenter,
            ),
            barrierDismissible: true,
            dismissOnPointerMoveAway: false,
            builder: (context) {
              return fluent.MenuFlyout(
                items: [
                  fluent.MenuFlyoutItem(
                    text: const Text('Move to Trash'),
                    leading: const fluent.Icon(fluent.FluentIcons.delete),
                    onPressed: () {
                      final updatedNote = widget.note.copyWith(isInTrash: true);
                      widget.onSave(updatedNote);
                      fluent.Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: fluent.Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.note.title,
                  style: fluent.FluentTheme.of(context).typography.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    getPreviewText(widget.note.content),
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
        ),
      ),
    );
  }
}
