import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';

class ContextMenuHelper {
  static void showContextMenu({
    required BuildContext context,
    required Offset position,
    required Note note,
    required Function(Note) onSave,
    required Function(Note) onDelete,
  }) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
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

  static List<PopupMenuEntry> _buildDefaultContextMenu(
      BuildContext context, Note note, Function(Note) onSave) {
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
            Text(note.isFavorite ? 'Desfavoritar' : 'Favoritar'),
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
            const Text('Mover para a lixeira'),
          ],
        ),
      ),
    ];
  }

  static List<PopupMenuEntry> _buildTrashContextMenu(BuildContext context,
      Note note, Function(Note) onSave, Function(Note) onDelete) {
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
            const Text('Restaurar'),
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
            const Text('Excluir permanentemente'),
          ],
        ),
      ),
    ];
  }
}
