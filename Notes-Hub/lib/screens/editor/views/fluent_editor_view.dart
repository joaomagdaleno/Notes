import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:notes_hub/screens/editor/widgets/collaborator_avatars.dart';
import 'package:notes_hub/screens/editor/widgets/editable_title.dart';

/// A Windows-specific view for the note editor.
class FluentEditorView extends StatelessWidget {
  /// Creates a [FluentEditorView].
  const FluentEditorView({
    required this.editor,
    required this.isFocusMode,
    required this.noteTitle,
    required this.onTitleChanged,
    required this.isCollaborative,
    required this.remoteCursors,
    required this.onToggleFindBar,
    required this.onShowHistory,
    required this.onToggleFocusMode,
    super.key,
  });

  /// The editor widget to display.
  final Widget editor;

  /// Whether focus mode is currently active.
  final bool isFocusMode;

  /// The current title of the note.
  final String noteTitle;

  /// Callback when the note title is changed.
  final ValueChanged<String> onTitleChanged;

  /// Whether the session is collaborative.
  final bool isCollaborative;

  /// A map of remote cursors to display.
  final Map<String, Map<String, dynamic>> remoteCursors;

  /// Callback to toggle the find/replace bar.
  final VoidCallback onToggleFindBar;

  /// Callback to show the note history.
  final VoidCallback onShowHistory;

  /// Callback to toggle focus mode.
  final VoidCallback onToggleFocusMode;

  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: isFocusMode
          ? null
          : fluent.PageHeader(
              title: EditableTitle(
                initialTitle: noteTitle,
                onChanged: onTitleChanged,
              ),
              leading: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              commandBar: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCollaborative)
                    CollaboratorAvatars(remoteCursors: remoteCursors),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.search),
                    onPressed: onToggleFindBar,
                  ),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.history),
                    onPressed: onShowHistory,
                  ),
                  fluent.IconButton(
                    icon: Icon(
                      isFocusMode
                          ? fluent.FluentIcons.back_to_window
                          : fluent.FluentIcons.full_screen,
                      size: 16,
                    ),
                    onPressed: onToggleFocusMode,
                  ),
                ],
              ),
            ),
      content: editor,
    );
  }
}
