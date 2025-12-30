import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';

/// A Material Design view for the application sidebar.
class MaterialSidebarView extends StatelessWidget {
  /// Creates a [MaterialSidebarView].
  const MaterialSidebarView({
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

  /// The current sidebar selection.
  final SidebarSelection selection;

  /// Callback when the sidebar selection is changed.
  final ValueChanged<SidebarSelection> onSelectionChanged;

  /// Stream of available folders.
  final Stream<List<Folder>> foldersStream;

  /// Stream of available tags.
  final Stream<List<String>> tagsStream;

  /// Callback to create a new folder.
  final VoidCallback onCreateFolder;

  /// Callback to delete a folder by its ID.
  final ValueChanged<String> onDeleteFolder;

  /// Callback to perform a manual backup.
  final VoidCallback onPerformBackup;

  /// The widget representing the user account section.
  final Widget accountSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'My Notes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  key: const ValueKey('all_notes'),
                  leading: const Icon(Icons.notes),
                  title: const Text('All Notes'),
                  selected: selection.type == SidebarItemType.all,
                  onTap: () => onSelectionChanged(
                    const SidebarSelection(SidebarItemType.all),
                  ),
                ),
                ListTile(
                  key: const ValueKey('favorites'),
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Favorites'),
                  selected: selection.type == SidebarItemType.favorites,
                  onTap: () => onSelectionChanged(
                    const SidebarSelection(SidebarItemType.favorites),
                  ),
                ),
                ListTile(
                  key: const ValueKey('trash'),
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Trash'),
                  selected: selection.type == SidebarItemType.trash,
                  onTap: () => onSelectionChanged(
                    const SidebarSelection(SidebarItemType.trash),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Folders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                StreamBuilder<List<Folder>>(
                  stream: foldersStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final folders = snapshot.data!;
                    return Column(
                      children: folders.map((folder) {
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(folder.name),
                          selected: selection.type == SidebarItemType.folder &&
                                  selection.folder?.id == folder.id,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                onDeleteFolder(folder.id);
                              }
                            },
                          ),
                          onTap: () => onSelectionChanged(
                            SidebarSelection(
                              SidebarItemType.folder,
                              folder: folder,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Tags',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
                        return ListTile(
                          title: Text(tag),
                          leading: const Icon(Icons.label_outline),
                          selected: selection.type == SidebarItemType.tag &&
                                  selection.tag == tag,
                          onTap: () => onSelectionChanged(
                            SidebarSelection(
                              SidebarItemType.tag,
                              tag: tag,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('New Folder'),
                  onTap: onCreateFolder,
                ),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup Notes'),
                  onTap: onPerformBackup,
                ),
                const Divider(),
                accountSection,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
