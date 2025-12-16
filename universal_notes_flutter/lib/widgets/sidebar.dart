import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';

/// The type of item selected in the sidebar.
enum SidebarItemType {
  /// All notes.
  all,

  /// Favorite notes.
  favorites,

  /// Deleted notes (trash).
  trash,

  /// A specific folder.
  folder,

  /// Notes with a specific tag
  tag,
}

/// A class representing the current selection in the sidebar.
@immutable
class SidebarSelection {
  /// Creates a sidebar selection.
  const SidebarSelection(this.type, {this.folder, this.tag});

  /// The type of item selected.
  final SidebarItemType type;

  /// The specific folder selected, if type is [SidebarItemType.folder].
  final Folder? folder;

  /// The specific tag selected, if type is [SidebarItemType.tag].
  final String? tag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarSelection &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          folder?.id == other.folder?.id &&
          tag == other.tag;

  @override
  int get hashCode => type.hashCode ^ folder.hashCode ^ tag.hashCode;
}

/// A sidebar widget to display and manage folders.
class Sidebar extends StatefulWidget {
  /// Creates a new instance of [Sidebar].
  const Sidebar({
    required this.onSelectionChanged,
    super.key,
  });

  /// Callback when the selection changes.
  final ValueChanged<SidebarSelection> onSelectionChanged;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // Folder logic remains, but we will use a Stream for tags.
  final List<Folder> _folders = [];
  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  final BackupService _backupService = BackupService();
  final FirestoreRepository _firestoreRepository = FirestoreRepository();
  late final Stream<List<String>> _tagsStream;

  @override
  void initState() {
    super.initState();
    _tagsStream = _firestoreRepository.getAllTagsStream();
    // We can keep folder logic if it's still local or refactor later
    // unawaited(_loadFolders());
  }

  Future<void> _createNewFolder() async {
    // This would need to be refactored to use a new FolderRepository
    // if we migrate folders to Firestore as well. For now, it's disabled.
  }

  Future<void> _performBackup() async {
    try {
      final path = await _backupService.exportDatabaseToJson();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved to: $path')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<String?> _showInputDialog({
    required String title,
    String? existingValue,
  }) {
    final controller = TextEditingController(text: existingValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Text(
              'My Notes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notes),
            title: const Text('All Notes'),
            selected: _selection.type == SidebarItemType.all,
            onTap: () {
              const newSelection = SidebarSelection(SidebarItemType.all);
              setState(() => _selection = newSelection);
              widget.onSelectionChanged(newSelection);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Favorites'),
            selected: _selection.type == SidebarItemType.favorites,
            onTap: () {
              const newSelection = SidebarSelection(SidebarItemType.favorites);
              setState(() => _selection = newSelection);
              widget.onSelectionChanged(newSelection);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Trash'),
            selected: _selection.type == SidebarItemType.trash,
            onTap: () {
              const newSelection = SidebarSelection(SidebarItemType.trash);
              setState(() => _selection = newSelection);
              widget.onSelectionChanged(newSelection);
            },
          ),
          const Divider(),
          // --- Folders ---
          Expanded(
            child: ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  selected: _selection.type == SidebarItemType.folder &&
                      _selection.folder?.id == folder.id,
                  onTap: () {
                    final newSelection = SidebarSelection(
                      SidebarItemType.folder,
                      folder: folder,
                    );
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
                );
              },
            ),
          ),
          const Divider(),
          // --- Tags ---
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _tagsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink(); // No tags to show
                }
                final tags = snapshot.data!;
                return ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(tag),
                      selected: _selection.type == SidebarItemType.tag &&
                          _selection.tag == tag,
                      onTap: () {
                        final newSelection =
                            SidebarSelection(SidebarItem.tag, tag: tag);
                        setState(() => _selection = newSelection);
                        widget.onSelectionChanged(newSelection);
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New Folder'),
            onTap: () => unawaited(_createNewFolder()),
            enabled: false, // Temporarily disable folder creation
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Notes'),
            onTap: () => unawaited(_performBackup()),
          ),
        ],
      ),
    );
  }
}
