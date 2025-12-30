import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart' hide ListTile, Divider, IconButton;
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';

class FluentSidebarView extends StatelessWidget {
  const FluentSidebarView({
    required this.selection,
    required this.onSelectionChanged,
    required this.foldersStream,
    required this.tagsStream,
    required this.onCreateFolder,
    required this.onDeleteFolder,
    required this.onPerformBackup,
    required this.accountSection,
    super.key,
  });

  final SidebarSelection selection;
  final ValueChanged<SidebarSelection> onSelectionChanged;
  final Stream<List<Folder>> foldersStream;
  final Stream<List<String>> tagsStream;
  final VoidCallback onCreateFolder;
  final ValueChanged<String> onDeleteFolder;
  final VoidCallback onPerformBackup;
  final Widget accountSection;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Container(
      width: 280,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'My Notes',
              style: theme.typography.subtitle,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.quick_note),
                  title: const Text('All Notes'),
                  selected: selection.type == SidebarItemType.all,
                  onPressed: () => onSelectionChanged(const SidebarSelection(SidebarItemType.all)),
                ),
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.favorite_star),
                  title: const Text('Favorites'),
                  selected: selection.type == SidebarItemType.favorites,
                  onPressed: () => onSelectionChanged(const SidebarSelection(SidebarItemType.favorites)),
                ),
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.delete),
                  title: const Text('Trash'),
                  selected: selection.type == SidebarItemType.trash,
                  onPressed: () => onSelectionChanged(const SidebarSelection(SidebarItemType.trash)),
                ),
                const fluent.Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Folders',
                    style: theme.typography.caption,
                  ),
                ),
                StreamBuilder<List<Folder>>(
                  stream: foldersStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final folders = snapshot.data!;
                    return Column(
                      children: folders.map((folder) {
                        return fluent.ListTile.selectable(
                          leading: const Icon(fluent.FluentIcons.folder),
                          title: Text(folder.name),
                          selected: selection.type == SidebarItemType.folder &&
                                  selection.folder?.id == folder.id,
                          trailing: fluent.IconButton(
                            icon: const Icon(fluent.FluentIcons.delete),
                            onPressed: () => onDeleteFolder(folder.id),
                          ),
                          onPressed: () => onSelectionChanged(SidebarSelection(
                            SidebarItemType.folder,
                            folder: folder,
                          )),
                        );
                      }).toList(),
                    );
                  },
                ),
                const fluent.Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Tags',
                    style: theme.typography.caption,
                  ),
                ),
                StreamBuilder<List<String>>(
                  stream: tagsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final tags = snapshot.data!;
                    if (tags.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: tags.map((tag) {
                        return fluent.ListTile.selectable(
                          leading: const Icon(fluent.FluentIcons.tag),
                          title: Text(tag),
                          selected: selection.type == SidebarItemType.tag &&
                                  selection.tag == tag,
                          onPressed: () => onSelectionChanged(SidebarSelection(
                            SidebarItemType.tag,
                            tag: tag,
                          )),
                        );
                      }).toList(),
                    );
                  },
                ),
                const fluent.Divider(),
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.add),
                  title: const Text('New Folder'),
                  onPressed: onCreateFolder,
                ),
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.cloud_download),
                  title: const Text('Backup Notes'),
                  onPressed: onPerformBackup,
                ),
                const fluent.Divider(),
                accountSection,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
