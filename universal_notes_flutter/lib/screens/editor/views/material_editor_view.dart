import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/screens/editor/widgets/collaborator_avatars.dart';
import 'package:universal_notes_flutter/screens/editor/widgets/editable_title.dart';

class MaterialEditorView extends StatelessWidget {
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

  final Widget editor;
  final bool isFocusMode;
  final String noteTitle;
  final ValueChanged<String> onTitleChanged;
  final bool isCollaborative;
  final Map<String, Map<String, dynamic>> remoteCursors;
  final VoidCallback onToggleFindBar;
  final VoidCallback onShowHistory;
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
