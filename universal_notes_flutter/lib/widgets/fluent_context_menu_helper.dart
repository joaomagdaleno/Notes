import 'package:fluent_ui/fluent_ui.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// A helper class for showing a context menu for a note.
class FluentContextMenuHelper {
  /// Shows the context menu.
  static Future<void> showContextMenu({
    required BuildContext context,
    required FlyoutController controller,
    required Note note,
    required void Function(Note) onSave,
    required void Function(Note) onDelete,
  }) async {
    await controller.showFlyout(
      dismissOnPointerMoveAway: true,
      builder: (context) {
        return MenuFlyout(
          items: note.isInTrash
              ? _buildTrashContextMenu(note, onSave, onDelete)
              : _buildDefaultContextMenu(note, onSave),
        );
      },
    );
  }

  static List<MenuFlyoutItemBase> _buildDefaultContextMenu(
    Note note,
    void Function(Note) onSave,
  ) {
    return [
      MenuFlyoutItem(
        leading: Icon(
          note.isFavorite
              ? FluentIcons.favorite_star_fill
              : FluentIcons.favorite_star,
        ),
        text: Text(note.isFavorite ? 'Unfavorite' : 'Favorite'),
        onPressed: () {
          note.isFavorite = !note.isFavorite;
          onSave(note);
        },
      ),
      const MenuFlyoutSeparator(),
      MenuFlyoutItem(
        leading: const Icon(FluentIcons.delete),
        text: const Text('Move to trash'),
        onPressed: () {
          note.isInTrash = true;
          onSave(note);
        },
      ),
    ];
  }

  static List<MenuFlyoutItemBase> _buildTrashContextMenu(
    Note note,
    void Function(Note) onSave,
    void Function(Note) onDelete,
  ) {
    return [
      MenuFlyoutItem(
        leading: const Icon(FluentIcons.undo),
        text: const Text('Restore'),
        onPressed: () {
          note.isInTrash = false;
          onSave(note);
        },
      ),
      const MenuFlyoutSeparator(),
      MenuFlyoutItem(
        leading: const Icon(FluentIcons.delete),
        text: const Text('Delete permanently'),
        onPressed: () {
          onDelete(note);
        },
      ),
    ];
  }
}
