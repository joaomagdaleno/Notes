import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/screens/editor/widgets/collaborator_avatars.dart';
import 'package:universal_notes_flutter/screens/editor/widgets/editable_title.dart';

class FluentEditorView extends StatelessWidget {
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
    return fluent.ScaffoldPage(
      header: isFocusMode
          ? null
          : fluent.PageHeader(
              title: EditableTitle(
                initialTitle: noteTitle,
                onChanged: onTitleChanged,
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
                      isFocusMode ? Icons.fullscreen_exit : Icons.fullscreen,
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
