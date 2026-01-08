import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/services/export_service.dart';

/// A helper class for showing a context menu for a note.
class FluentContextMenuHelper {
  /// Shows the context menu.
  static Future<void> showContextMenu({
    required BuildContext context,
    required fluent.FlyoutController controller,
    required Note note,
    required void Function(Note) onSave,
    required void Function(Note) onDelete,
  }) async {
    await controller.showFlyout<void>(
      builder: (flyoutContext) {
        return fluent.MenuFlyout(
          items: note.isInTrash
              ? _buildTrashContextMenu(note, onSave, onDelete)
              : _buildDefaultContextMenu(context, note, onSave),
        );
      },
    );
  }

  static List<fluent.MenuFlyoutItemBase> _buildDefaultContextMenu(
    BuildContext context,
    Note note,
    void Function(Note) onSave,
  ) {
    final exportService = ExportService();
    return [
      fluent.MenuFlyoutItem(
        leading: fluent.Icon(
          note.isFavorite
              ? fluent.FluentIcons.favorite_star_fill
              : fluent.FluentIcons.favorite_star,
        ),
        text: Text(note.isFavorite ? 'Unfavorite' : 'Favorite'),
        onPressed: () {
          final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
          onSave(updatedNote);
        },
      ),
      const fluent.MenuFlyoutSeparator(),
      fluent.MenuFlyoutItem(
        leading: const fluent.Icon(fluent.FluentIcons.delete),
        text: const Text('Move to trash'),
        onPressed: () {
          final updatedNote = note.copyWith(isInTrash: true);
          onSave(updatedNote);
        },
      ),
      const fluent.MenuFlyoutSeparator(),
      fluent.MenuFlyoutItem(
        leading: const fluent.Icon(fluent.FluentIcons.save_as),
        text: const Text('Export to TXT'),
        onPressed: () async {
          material.ScaffoldMessenger.of(context).showSnackBar(
            const material.SnackBar(content: Text('Exporting to TXT...')),
          );
          final noteWithContent =
              await NoteRepository.instance.getNoteWithContent(note.id);
          await exportService.exportToTxt(noteWithContent);
        },
      ),
      fluent.MenuFlyoutItem(
        leading: const fluent.Icon(fluent.FluentIcons.pdf),
        text: const Text('Export to PDF'),
        onPressed: () async {
          material.ScaffoldMessenger.of(context).showSnackBar(
            const material.SnackBar(content: Text('Exporting to PDF...')),
          );
          final noteWithContent =
              await NoteRepository.instance.getNoteWithContent(note.id);
          await exportService.exportToPdf(noteWithContent);
        },
      ),
    ];
  }

  static List<fluent.MenuFlyoutItemBase> _buildTrashContextMenu(
    Note note,
    void Function(Note) onSave,
    void Function(Note) onDelete,
  ) {
    return [
      fluent.MenuFlyoutItem(
        leading: const fluent.Icon(fluent.FluentIcons.undo),
        text: const Text('Restore'),
        onPressed: () {
          final updatedNote = note.copyWith(isInTrash: false);
          onSave(updatedNote);
        },
      ),
      const fluent.MenuFlyoutSeparator(),
      fluent.MenuFlyoutItem(
        leading: const fluent.Icon(fluent.FluentIcons.delete),
        text: const Text('Delete permanently'),
        onPressed: () {
          onDelete(note);
        },
      ),
    ];
  }
}
