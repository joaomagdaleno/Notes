import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// A helper class for showing a context menu for a note.
class ContextMenuHelper {
  /// Shows the context menu.
  static Future<void> showContextMenu({
    required BuildContext context,
    required Offset position,
    required Note note,
    required void Function(Note) onSave,
    required void Function(Note) onDelete,
  }) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      return;
    }

    await showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: note.isInTrash
          ? _buildTrashContextMenu(context, note, onSave, onDelete)
          : _buildDefaultContextMenu(context, note, onSave),
    );
  }

  static List<PopupMenuEntry<void>> _buildDefaultContextMenu(
    BuildContext context,
    Note note,
    void Function(Note) onSave,
  ) {
    return [
      PopupMenuItem(
        onTap: () {
          note.isFavorite = !note.isFavorite;
          onSave(note);
        },
        child: Row(
          children: [
            Icon(
              note.isFavorite ? Icons.star : Icons.star_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(note.isFavorite ? 'Desfavoritar' : 'Favoritar')),
          ],
        ),
      ),
      PopupMenuItem(
        onTap: () {
          note.isInTrash = true;
          onSave(note);
        },
        child: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Mover para a lixeira')),
          ],
        ),
      ),
    ];
  }

  static List<PopupMenuEntry<void>> _buildTrashContextMenu(
    BuildContext context,
    Note note,
    void Function(Note) onSave,
    void Function(Note) onDelete,
  ) {
    return [
      PopupMenuItem(
        onTap: () {
          note.isInTrash = false;
          onSave(note);
        },
        child: Row(
          children: [
            Icon(
              Icons.restore_from_trash,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Restaurar')),
          ],
        ),
      ),
      PopupMenuItem(
        onTap: () {
          onDelete(note);
        },
        child: Row(
          children: [
            Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Excluir permanentemente')),
          ],
        ),
      ),
    ];
  }
}
