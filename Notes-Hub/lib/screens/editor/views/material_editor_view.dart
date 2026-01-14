import 'package:flutter/material.dart';
import 'package:notes_hub/models/persona_model.dart';
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
    required this.activePersona,
    required this.onPersonaChanged,
    super.key,
  });

  /// The editor widget to display.
  final Widget editor;

  /// The active persona.
  final EditorPersona activePersona;

  /// Callback when the persona is changed.
  final ValueChanged<EditorPersona> onPersonaChanged;

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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150,
                    child: EditableTitle(
                      initialTitle: noteTitle,
                      onChanged: onTitleChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPersonaSwitcher(context),
                ],
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

  Widget _buildPersonaSwitcher(BuildContext context) {
    final personas = [
      (EditorPersona.architect, Icons.architecture),
      (EditorPersona.writer, Icons.edit_note),
      (EditorPersona.brainstorm, Icons.lightbulb_outline),
      (EditorPersona.reading, Icons.menu_book),
    ];

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: personas.map((p) {
          final isActive = p.$1 == activePersona;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Tooltip(
              message: p.$1.toString().split('.').last,
              child: InkWell(
                onTap: () => onPersonaChanged(p.$1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    p.$2,
                    size: 12,
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
