import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:notes_hub/models/folder.dart';
import 'package:notes_hub/widgets/sidebar.dart';

/// A Windows-specific view for the notes list screen using NavigationView.
class FluentNotesView extends StatefulWidget {
  /// Creates a [FluentNotesView].
  const FluentNotesView({
    required this.selection,
    required this.onSelectionChanged,
    required this.foldersStream,
    required this.tagsStream,
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
    required this.onCreateFolder,
    required this.onDeleteFolder,
    super.key,
  });

  /// The current sidebar selection.
  final SidebarSelection selection;

  /// Callback when the sidebar selection is changed.
  final ValueChanged<SidebarSelection> onSelectionChanged;

  /// Stream of available folders.
  final Stream<List<Folder>> foldersStream;

  /// Stream of available tags.
  final Stream<List<String>> tagsStream;

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

  /// Callback to create a new folder.
  final VoidCallback onCreateFolder;

  /// Callback to delete a folder.
  final ValueChanged<String> onDeleteFolder;

  @override
  State<FluentNotesView> createState() => _FluentNotesViewState();
}

class _FluentNotesViewState extends State<FluentNotesView> {
  final _folderFlyoutControllers = <String, FlyoutController>{};

  @override
  void dispose() {
    for (final controller in _folderFlyoutControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _calculateSelectedIndex(List<Folder> folders, List<String> tags) {
    if (widget.selection.type == SidebarItemType.all) return 0;
    if (widget.selection.type == SidebarItemType.favorites) return 1;
    if (widget.selection.type == SidebarItemType.trash) return 2;

    if (widget.selection.type == SidebarItemType.folder) {
      final index = folders.indexWhere(
        (f) => f.id == widget.selection.folder?.id,
      );
      if (index != -1) return 3 + index;
    }

    if (widget.selection.type == SidebarItemType.tag) {
      final index = tags.indexWhere((t) => t == widget.selection.tag);
      if (index != -1) return 3 + folders.length + index;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Folder>>(
      stream: widget.foldersStream,
      builder: (context, folderSnapshot) {
        return StreamBuilder<List<String>>(
          stream: widget.tagsStream,
          builder: (context, tagSnapshot) {
            final folders = folderSnapshot.data ?? [];
            final tags = tagSnapshot.data ?? [];

            return NavigationView(
              appBar: NavigationAppBar(
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                actions: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: widget.viewModeNotifier,
                      builder: (context, currentMode, child) {
                        final props =
                            widget.nextViewModePropsGetter(currentMode);
                        return Tooltip(
                          message: props.tooltip,
                          child: IconButton(
                            icon: Icon(props.icon, size: 16),
                            onPressed: widget.onCycleViewMode,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Toggle Theme',
                      child: IconButton(
                        icon: const Icon(FluentIcons.brightness, size: 16),
                        onPressed: widget.onToggleTheme,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Check for Updates',
                      child: IconButton(
                        icon: const Icon(FluentIcons.update_restore, size: 16),
                        onPressed: widget.onCheckUpdate,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              pane: NavigationPane(
                selected: _calculateSelectedIndex(folders, tags),
                items: [
                  PaneItem(
                    icon: const Icon(FluentIcons.all_apps),
                    title: const Text('All Notes'),
                    body: const SizedBox.shrink(),
                    onTap: () => widget.onSelectionChanged(
                      const SidebarSelection(SidebarItemType.all),
                    ),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.favorite_star),
                    title: const Text('Favorites'),
                    body: const SizedBox.shrink(),
                    onTap: () => widget.onSelectionChanged(
                      const SidebarSelection(SidebarItemType.favorites),
                    ),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.delete),
                    title: const Text('Trash'),
                    body: const SizedBox.shrink(),
                    onTap: () => widget.onSelectionChanged(
                      const SidebarSelection(SidebarItemType.trash),
                    ),
                  ),
                  PaneItemHeader(header: const Text('Folders')),
                  ...folders.map((folder) {
                    final controller = _folderFlyoutControllers.putIfAbsent(
                      folder.id,
                      FlyoutController.new,
                    );
                    return PaneItem(
                      icon: const Icon(FluentIcons.folder_horizontal),
                      title: FlyoutTarget(
                        controller: controller,
                        child: GestureDetector(
                          onSecondaryTapUp: (details) {
                            unawaited(
                              controller.showFlyout<void>(
                                autoModeConfiguration: FlyoutAutoConfiguration(
                                  preferredMode:
                                      FlyoutPlacementMode.bottomRight,
                                ),
                                builder: (context) => MenuFlyout(
                                  items: [
                                    MenuFlyoutItem(
                                      leading: const Icon(FluentIcons.delete),
                                      text: const Text('Delete'),
                                      onPressed: () =>
                                          widget.onDeleteFolder(folder.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Text(folder.name),
                        ),
                      ),
                      body: const SizedBox.shrink(),
                      onTap: () => widget.onSelectionChanged(
                        SidebarSelection(
                          SidebarItemType.folder,
                          folder: folder,
                        ),
                      ),
                    );
                  }),
                  PaneItemAction(
                    icon: const Icon(FluentIcons.add),
                    title: const Text('New Folder'),
                    onTap: widget.onCreateFolder,
                  ),
                  if (tags.isNotEmpty) ...[
                    PaneItemHeader(header: const Text('Tags')),
                    ...tags.map(
                      (tag) => PaneItem(
                        icon: const Icon(FluentIcons.tag),
                        title: Text(tag),
                        body: const SizedBox.shrink(),
                        onTap: () => widget.onSelectionChanged(
                          SidebarSelection(SidebarItemType.tag, tag: tag),
                        ),
                      ),
                    ),
                  ],
                ],
                footerItems: [
                  PaneItem(
                    icon: const Icon(FluentIcons.settings),
                    title: const Text('Settings'),
                    body: const SizedBox.shrink(),
                    onTap: widget.onOpenSettings,
                  ),
                ],
              ),
              content: ScaffoldPage(
                content: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                      child: TextBox(
                        controller: widget.searchController,
                        placeholder: 'Search notes...',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(FluentIcons.search, size: 14),
                        ),
                      ),
                    ),
                    Expanded(child: widget.content),
                  ],
                ),
                bottomBar: widget.isTrashView
                    ? null
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton(
                              onPressed: widget.onCreateNote,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(FluentIcons.add),
                                  SizedBox(width: 8),
                                  Text('New Note'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Button(
                              onPressed: widget.onOpenQuickEditor,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(FluentIcons.quick_note),
                                  SizedBox(width: 8),
                                  Text('Quick Note'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
