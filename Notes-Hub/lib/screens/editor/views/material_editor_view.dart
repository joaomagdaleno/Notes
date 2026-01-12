import 'package:flutter/material.dart';
import 'package:notes_hub/screens/editor/widgets/collaborator_avatars.dart';
import 'package:notes_hub/screens/editor/widgets/editable_title.dart';

/// A Material Design view for the note editor.
class MaterialEditorView extends StatelessWidget {
  /// Creates a [MaterialEditorView].
  const MaterialEditorView({
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
    return Scaffold(
      appBar: isFocusMode
          ? null
          : AppBar(
              title: EditableTitle(
                initialTitle: noteTitle,
                onChanged: onTitleChanged,
              ),
              actions: [
                if (isCollaborative)
                  CollaboratorAvatars(remoteCursors: remoteCursors),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: onToggleFindBar,
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: onShowHistory,
                ),
                IconButton(
                  icon: Icon(
                    isFocusMode ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                  onPressed: onToggleFocusMode,
                ),
              ],
            ),
      body: editor,
    );
  }
}
