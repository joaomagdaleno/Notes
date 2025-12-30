import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';
import 'package:universal_notes_flutter/widgets/note_preview_dialog.dart';

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

  static final _dateFormat = DateFormat('d MMM. yyyy');

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovered = false;
  late String _plainTextContent;
  final _flyoutController = fluent.FlyoutController();

  static final _gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.black.withAlpha(153),
        Colors.transparent,
        Colors.black.withAlpha(204),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static final _favoriteBackgroundDecoration = BoxDecoration(
    color: Colors.amber,
    borderRadius: BorderRadius.circular(12),
  );

  static final _deleteBackgroundDecoration = BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(12),
  );

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

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  String _computePlainText(String jsonContent) {
    if (jsonContent.isEmpty) {
      return '';
    }
    try {
      return DocumentAdapter.fromJson(jsonContent).toPlainText();
    } on Exception {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentCard(context);
    } else {
      return _buildMaterialCard(context);
    }
  }

  // ==================== FLUENT UI (Windows) ====================
  Widget _buildFluentCard(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return fluent.FlyoutTarget(
      controller: _flyoutController,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) {
          _showFluentContextMenu(details.globalPosition);
        },
        onLongPressStart: (details) {
          _showFluentContextMenu(details.globalPosition);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: fluent.Card(
            backgroundColor: _isHovered
                ? theme.selectionColor.withValues(alpha: 0.1)
                : theme.cardColor,
            child: Stack(
              children: [
                if (widget.note.isFavorite)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Semantics(
                      label: 'Favorite',
                      child: fluent.Icon(
                        fluent.FluentIcons.favorite_star_fill,
                        color: theme.accentColor,
                        size: 16,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.note.title,
                        style: theme.typography.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          _plainTextContent,
                          style: theme.typography.body,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NoteCard._dateFormat.format(widget.note.date),
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: fluent.Tooltip(
                    message: 'Preview',
                    child: fluent.IconButton(
                      icon: const fluent.Icon(fluent.FluentIcons.view),
                      onPressed: () => unawaited(_showFluentPreview(context)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFluentContextMenu(Offset globalPosition) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.globalToLocal(globalPosition);

    unawaited(
      _flyoutController.showFlyout<void>(
        placementMode: fluent.FlyoutPlacementMode.topLeft,
        additionalOffset: offset.dy,
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
          if (context.mounted) {
            fluent.Navigator.of(context).pop();
          }
        },
      ),
      fluent.MenuFlyoutItem(
        text: const Text('Mover para a lixeira'),
        leading: const fluent.Icon(fluent.FluentIcons.delete),
        onPressed: () async {
          final updatedNote = widget.note.copyWith(isInTrash: true);
          await widget.onSave(updatedNote);
          if (context.mounted) {
            fluent.Navigator.of(context).pop();
          }
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
          if (context.mounted) {
            fluent.Navigator.of(context).pop();
          }
        },
      ),
      fluent.MenuFlyoutItem(
        text: const Text('Excluir permanentemente'),
        leading: const fluent.Icon(fluent.FluentIcons.delete),
        onPressed: () {
          widget.onDelete(widget.note);
          if (context.mounted) {
            fluent.Navigator.of(context).pop();
          }
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

  // ==================== MATERIAL (Android/iOS) ====================
  Widget _buildMaterialCard(BuildContext context) {
    final hasImage = widget.note.imageUrl?.isNotEmpty ?? false;

    final card = Card(
      elevation: _isHovered ? 8 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
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
                Container(
                  decoration: _gradientDecoration,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.note.isFavorite)
                        const Align(
                          alignment: Alignment.topRight,
                          child: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      Text(
                        widget.note.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (_plainTextContent.isNotEmpty)
                        Flexible(
                          child: Text(
                            _plainTextContent,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        NoteCard._dateFormat.format(widget.note.lastModified),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.onFavorite == null && widget.onTrash == null) {
      return card;
    }

    return Dismissible(
      key: Key(widget.note.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onFavorite?.call(widget.note);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          widget.onTrash?.call(widget.note);
          return false;
        }
        return false;
      },
      background: Container(
        decoration: _favoriteBackgroundDecoration,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          widget.note.isFavorite ? Icons.star_border : Icons.star,
          color: Colors.white,
          size: 32,
        ),
      ),
      secondaryBackground: Container(
        decoration: _deleteBackgroundDecoration,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: card,
    );
  }

  void _showMaterialContextMenu(BuildContext context, Offset globalPosition) {
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
