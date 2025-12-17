import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/export_service.dart';

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
    await controller.showFlyout<void>(
      dismissOnPointerMoveAway: true,
      builder: (flyoutContext) {
        return MenuFlyout(
          items: note.isInTrash
              ? _buildTrashContextMenu(note, onSave, onDelete)
              : _buildDefaultContextMenu(context, note, onSave),
        );
      },
    );
  }

  static List<MenuFlyoutItemBase> _buildDefaultContextMenu(
    BuildContext context,
    Note note,
    void Function(Note) onSave,
  ) {
    final exportService = ExportService();
    return [
      MenuFlyoutItem(
        leading: Icon(
          note.isFavorite
              ? FluentIcons.favorite_star_fill
              : FluentIcons.favorite_star,
        ),
        text: Text(note.isFavorite ? 'Unfavorite' : 'Favorite'),
        onPressed: () {
          final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
          onSave(updatedNote);
        },
      ),
      const MenuFlyoutSeparator(),
      MenuFlyoutItem(
        leading: const Icon(FluentIcons.delete),
        text: const Text('Move to trash'),
        onPressed: () {
          final updatedNote = note.copyWith(isInTrash: true);
          onSave(updatedNote);
        },
      ),
      const MenuFlyoutSeparator(),
      MenuFlyoutItem(
        leading: const Icon(FluentIcons.save_as),
        text: const Text('Export to TXT'),
        onPressed: () async {
          material.ScaffoldMessenger.of(context).showSnackBar(
            const material.SnackBar(content: Text('Exporting to TXT...')),
          );
          final noteWithContent = await NoteRepository.instance
              .getNoteWithContent(note.id);
          await exportService.exportToTxt(noteWithContent);
        },
      ),
      MenuFlyoutItem(
        leading: const Icon(FluentIcons.pdf),
        text: const Text('Export to PDF'),
        onPressed: () async {
          material.ScaffoldMessenger.of(context).showSnackBar(
            const material.SnackBar(content: Text('Exporting to PDF...')),
          );
          final noteWithContent = await NoteRepository.instance
              .getNoteWithContent(note.id);
          await exportService.exportToPdf(noteWithContent);
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
          final updatedNote = note.copyWith(isInTrash: false);
          onSave(updatedNote);
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
