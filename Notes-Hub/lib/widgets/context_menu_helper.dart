import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/services/export_service.dart';
import 'package:notes_hub/widgets/fluent_context_menu_helper.dart'
    as fluent_context;

/// A helper class for showing a context menu for a note.
class ContextMenuHelper {
  /// Shows the context menu.
  static Future<void> showContextMenu({
    required BuildContext context,
    required Offset position,
    required Note note,
    required void Function(Note) onSave,
    required void Function(Note) onDelete,
    dynamic controller,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await _showFluentContextMenu(
        context: context,
        position: position,
        note: note,
        onSave: onSave,
        onDelete: onDelete,
        controller: controller,
      );
    } else {
      await _showMaterialContextMenu(
        context: context,
        position: position,
        note: note,
        onSave: onSave,
        onDelete: onDelete,
      );
    }
  }

  /// Shows Fluent-style context menu (Windows)
  static Future<void> _showFluentContextMenu({
    required BuildContext context,
    required Offset position,
    required Note note,
    required void Function(Note) onSave,
    required void Function(Note) onDelete,
    dynamic controller,
  }) async {
    if (controller != null) {
      await fluent_context.FluentContextMenuHelper.showContextMenu(
        context: context,
        controller: controller as fluent.FlyoutController,
        note: note,
        onSave: onSave,
        onDelete: onDelete,
      );
    }
  }

  /// Shows Material-style context menu (Android/iOS)
  static Future<void> _showMaterialContextMenu({
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
          ? buildTrashContextMenu(context, note, onSave, onDelete)
          : buildDefaultContextMenu(context, note, onSave),
    );
  }

  /// Builds the context menu for a note that is not in the trash.
  @visibleForTesting
  static List<PopupMenuEntry<void>> buildDefaultContextMenu(
    BuildContext context,
    Note note,
    void Function(Note) onSave,
  ) {
    final exportService = ExportService();
    return [
      PopupMenuItem(
        onTap: () {
          final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
          onSave(updatedNote);
        },
        child: Row(
          children: [
            Icon(
              note.isFavorite ? Icons.star : Icons.star_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(note.isFavorite ? 'Desfavoritar' : 'Favoritar'),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        onTap: () {
          final updatedNote = note.copyWith(isInTrash: true);
          onSave(updatedNote);
        },
        child: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Mover para a lixeira'),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        onTap: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exportando para TXT...')),
          );
          final noteWithContent =
              await NoteRepository.instance.getNoteWithContent(note.id);
          await exportService.exportToTxt(noteWithContent);
        },
        child: const Text('Exportar para TXT'),
      ),
      PopupMenuItem(
        onTap: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exportando para PDF...')),
          );
          final noteWithContent =
              await NoteRepository.instance.getNoteWithContent(note.id);
          await exportService.exportToPdf(noteWithContent);
        },
        child: const Text('Exportar para PDF'),
      ),
    ];
  }

  /// Builds the context menu for a note that is in the trash.
  @visibleForTesting
  static List<PopupMenuEntry<void>> buildTrashContextMenu(
    BuildContext context,
    Note note,
    void Function(Note) onSave,
    void Function(Note) onDelete,
  ) {
    return [
      PopupMenuItem(
        onTap: () {
          final updatedNote = note.copyWith(isInTrash: false);
          onSave(updatedNote);
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
            const Expanded(
              child: Text('Excluir permanentemente'),
            ),
          ],
        ),
      ),
    ];
  }
}
