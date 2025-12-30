import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide IconButton, Tooltip;

/// A Windows-specific view for the notes list screen.
class FluentNotesView extends StatelessWidget {
  /// Creates a [FluentNotesView].
  const FluentNotesView({
    required this.sidebar,
    required this.title,
    required this.viewModeNotifier,
    required this.onCycleViewMode,
    required this.nextViewModePropsGetter,
    required this.onToggleTheme,
    required this.onCheckUpdate,
    required this.onOpenSettings,
    required this.searchController,
    required this.content,
    required this.isTrashView,
    required this.onCreateNote,
    required this.onOpenQuickEditor,
    super.key,
  });

  /// Sidebar widget to display on the left.
  final Widget sidebar;

  /// The title of the current view (e.g., 'All Notes').
  final String title;

  /// Notifier for the current view mode (grid/list).
  final ValueListenable<String> viewModeNotifier;

  /// Callback to cycle through different view modes.
  final VoidCallback onCycleViewMode;

  /// Function to get the properties (icon, tooltip) for the next view mode.
  final ({IconData icon, String tooltip}) Function(String)
      nextViewModePropsGetter;

  /// Callback to toggle the application theme.
  final VoidCallback onToggleTheme;

  /// Callback to check for application updates.
  final VoidCallback onCheckUpdate;

  /// Callback to open the settings screen.
  final VoidCallback onOpenSettings;

  /// Controller for the search input field.
  final TextEditingController searchController;

  /// The main content widget (the list of notes).
  final Widget content;

  /// Whether the current view is the trash.
  final bool isTrashView;

  /// Callback to create a new note.
  final VoidCallback onCreateNote;

  /// Callback to open the quick note editor.
  final VoidCallback onOpenQuickEditor;

  @override
  Widget build(BuildContext context) {
    return fluent.FluentTheme(
      data: fluent.FluentThemeData.light(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidebar,
          Expanded(
            child: fluent.ScaffoldPage(
              header: fluent.PageHeader(
                padding: 12,
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                commandBar: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: viewModeNotifier,
                      builder: (context, currentMode, child) {
                        final props = nextViewModePropsGetter(currentMode);
                        return fluent.Tooltip(
                          message: 'Persona: ${props.tooltip}',
                          child: fluent.IconButton(
                            icon: Icon(props.icon, size: 16),
                            onPressed: onCycleViewMode,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    fluent.Tooltip(
                      message: 'Toggle Theme',
                      child: fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.brightness, size: 16),
                        onPressed: onToggleTheme,
                      ),
                    ),
                    const SizedBox(width: 4),
                    fluent.Tooltip(
                      message: 'Check for Updates',
                      child: fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.update_restore, size: 16),
                        onPressed: onCheckUpdate,
                      ),
                    ),
                    const SizedBox(width: 4),
                    fluent.Tooltip(
                      message: 'Settings',
                      child: fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.settings, size: 16),
                        onPressed: onOpenSettings,
                      ),
                    ),
                  ],
                ),
              ),
              content: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: fluent.TextBox(
                      controller: searchController,
                      placeholder: 'Search notes...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(fluent.FluentIcons.search, size: 14),
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
              bottomBar: isTrashView
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          fluent.FilledButton(
                            onPressed: onCreateNote,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(fluent.FluentIcons.add),
                                SizedBox(width: 8),
                                Text('New Note'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          fluent.Button(
                            onPressed: onOpenQuickEditor,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(fluent.FluentIcons.quick_note),
                                SizedBox(width: 8),
                                Text('Quick Note'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
