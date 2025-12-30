import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Tooltip, IconButton;

class FluentNotesView extends StatelessWidget {
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

  final Widget sidebar;
  final String title;
  final ValueListenable<String> viewModeNotifier;
  final VoidCallback onCycleViewMode;
  final ({IconData icon, String tooltip}) Function(String) nextViewModePropsGetter;
  final VoidCallback onToggleTheme;
  final VoidCallback onCheckUpdate;
  final VoidCallback onOpenSettings;
  final TextEditingController searchController;
  final Widget content;
  final bool isTrashView;
  final VoidCallback onCreateNote;
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
