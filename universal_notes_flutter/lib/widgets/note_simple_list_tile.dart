import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';
import 'package:universal_notes_flutter/widgets/fluent_context_menu_helper.dart';

/// A widget that displays a note as a simple list tile.
class NoteSimpleListTile extends StatelessWidget {
  /// Creates a new instance of [NoteSimpleListTile].
  const NoteSimpleListTile({
    required this.note,
    required this.onSave,
    required this.onDelete,
    this.onTap,
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
  final VoidCallback? onTap;

  static final _dateFormat = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentTile(context);
    } else {
      return _buildMaterialTile(context);
    }
  }

  Widget _buildFluentTile(BuildContext context) {
    return fluent.ListTile.selectable(
      title: Text(note.title),
      trailing: Text(_dateFormat.format(note.date)),
      leading: Container(
        width: 40,
        height: 40,
        color: Colors.grey[300],
        child: const Icon(fluent.FluentIcons.image_search, color: Colors.grey),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildMaterialTile(BuildContext context) {
    return ListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        width: 40,
        height: 40,
        color: Colors.grey[300],
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      ),
      title: Text(note.title),
      trailing: Text(_dateFormat.format(note.date)),
      onTap: onTap,
      onLongPress: () async {
        final renderBox = context.findRenderObject();
        if (renderBox is RenderBox) {
          final position = renderBox.localToGlobal(Offset.zero);

          await ContextMenuHelper.showContextMenu(
            context: context,
            position: position,
            note: note,
            onSave: onSave,
            onDelete: onDelete,
          );
        }
      },
    );
  }
}
