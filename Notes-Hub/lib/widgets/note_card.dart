import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:notes_hub/editor/document_adapter.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/widgets/context_menu_helper.dart';
import 'package:notes_hub/widgets/note_card/views/fluent_note_card_view.dart';
import 'package:notes_hub/widgets/note_card/views/material_note_card_view.dart';
import 'package:notes_hub/widgets/note_preview_dialog.dart';

// ⚡ Bolt: This is a top-level function required for the `compute` function.
// Running this parsing logic in a separate isolate prevents UI jank when
// scrolling through a list of notes with complex content.
String _computePlainTextInBackground(String jsonContent) {
  if (jsonContent.isEmpty) {
    return '';
  }
  try {
    // This is the expensive operation we want to move off the main thread.
    return DocumentAdapter.fromJson(jsonContent).toPlainText();
  } on Exception {
    // If parsing fails, return an empty string.
    return '';
  }
}

/// A widget that displays a note as a card, adaptive for Windows and Mobile.
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

  // Optimization: DateFormat is expensive to instantiate.
  // By creating it once as a static final variable, we avoid re-creating it
  // on every build, improving performance, especially in lists.
  static final _dateFormat = DateFormat('d MMM. yyyy');

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovered = false;
  // ⚡ Bolt: Initialize with an empty string. The actual content will be
  // loaded asynchronously in a background isolate to prevent UI jank.
  String _plainTextContent = '';
  final _flyoutController = fluent.FlyoutController();

  @override
  void initState() {
    super.initState();
    // ⚡ Bolt: Offload the expensive text computation to a background isolate.
    unawaited(_updatePlainText());
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note.content != oldWidget.note.content) {
      // ⚡ Bolt: Re-compute the text content if the note has changed.
      unawaited(_updatePlainText());
    }
  }

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  // ⚡ Bolt: Asynchronously compute the plain text content in an isolate.
  Future<void> _updatePlainText() async {
    // The `compute` function runs `_computePlainTextInBackground` in a
    // separate isolate.
    final plainText =
        await compute(_computePlainTextInBackground, widget.note.content);

    // Check if the widget is still in the tree before updating the state.
    if (mounted) {
      setState(() {
        _plainTextContent = plainText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentNoteCardView(
        note: widget.note,
        plainTextContent: _plainTextContent,
        isHovered: _isHovered,
        flyoutController: _flyoutController,
        dateFormat: NoteCard._dateFormat,
        onTap: widget.onTap,
        onSecondaryTapUp: (details) =>
            _showFluentContextMenu(details.globalPosition),
        onLongPressStart: (details) =>
            _showFluentContextMenu(details.globalPosition),
        onHoverChanged: ({required isHovered}) =>
            setState(() => _isHovered = isHovered),
        onShowPreview: () => unawaited(_showFluentPreview(context)),
      );
    } else {
      return MaterialNoteCardView(
        note: widget.note,
        plainTextContent: _plainTextContent,
        isHovered: _isHovered,
        dateFormat: NoteCard._dateFormat,
        onTap: widget.onTap,
        onLongPress: () {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.localToGlobal(
              renderBox.size.center(Offset.zero),
            );
            _showMaterialContextMenu(context, offset);
          }
        },
        onHoverChanged: ({required isHovered}) =>
            setState(() => _isHovered = isHovered),
        onFavorite: widget.onFavorite,
        onTrash: widget.onTrash,
      );
    }
  }

  void _showFluentContextMenu(Offset globalPosition) {
    if (!mounted) return;

    unawaited(
      _flyoutController.showFlyout<void>(
        autoModeConfiguration: fluent.FlyoutAutoConfiguration(
          preferredMode: fluent.FlyoutPlacementMode.bottomRight,
        ),
        builder: (context) {
          return fluent.MenuFlyout(
            items: widget.note.isInTrash
                ? _buildFluentTrashMenuItems(context)
                : _buildFluentDefaultMenuItems(context),
          );
        },
      ),
    );
  }

  List<fluent.MenuFlyoutItemBase> _buildFluentDefaultMenuItems(
    BuildContext context,
  ) {
    return [
      fluent.MenuFlyoutItem(
        text: Text(widget.note.isFavorite ? 'Desfavoritar' : 'Favoritar'),
        leading: fluent.Icon(
          widget.note.isFavorite
              ? fluent.FluentIcons.favorite_star
              : fluent.FluentIcons.favorite_star_fill,
        ),
        onPressed: () async {
          final updatedNote =
              widget.note.copyWith(isFavorite: !widget.note.isFavorite);
          await widget.onSave(updatedNote);
        },
      ),
      fluent.MenuFlyoutItem(
        text: const Text('Mover para a lixeira'),
        leading: const fluent.Icon(fluent.FluentIcons.delete),
        onPressed: () async {
          final updatedNote = widget.note.copyWith(isInTrash: true);
          await widget.onSave(updatedNote);
        },
      ),
    ];
  }

  List<fluent.MenuFlyoutItemBase> _buildFluentTrashMenuItems(
    BuildContext context,
  ) {
    return [
      fluent.MenuFlyoutItem(
        text: const Text('Restaurar'),
        leading: const fluent.Icon(fluent.FluentIcons.redo),
        onPressed: () async {
          final updatedNote = widget.note.copyWith(isInTrash: false);
          await widget.onSave(updatedNote);
        },
      ),
      fluent.MenuFlyoutItem(
        text: const Text('Excluir permanentemente'),
        leading: const fluent.Icon(fluent.FluentIcons.delete),
        onPressed: () {
          widget.onDelete(widget.note);
        },
      ),
    ];
  }

  Future<void> _showFluentPreview(BuildContext context) async {
    final noteWithContent = await NoteRepository.instance.getNoteWithContent(
      widget.note.id,
    );
    final tags = await NoteRepository.instance.getTagsForNote(widget.note.id);
    if (!context.mounted) return;
    unawaited(
      NotePreviewDialog.show(context, note: noteWithContent, tags: tags),
    );
  }

  void _showMaterialContextMenu(BuildContext context, Offset globalPosition) {
    unawaited(
      ContextMenuHelper.showContextMenu(
        context: context,
        position: globalPosition,
        note: widget.note,
        onSave: (note) async => widget.onSave(note),
        onDelete: widget.onDelete,
      ),
    );
  }
}
