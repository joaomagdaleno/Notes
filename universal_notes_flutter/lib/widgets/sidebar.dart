import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';

enum SidebarItemType { all, favorites, trash, folder }

class SidebarSelection { // Only used when type is 'folder'

  const SidebarSelection(this.type, {this.folder});
  final SidebarItemType type;
  final Folder? folder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarSelection &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          folder?.id == other.folder?.id;

  @override
  int get hashCode => type.hashCode ^ folder.hashCode;
}


/// A sidebar widget to display and manage folders.
class Sidebar extends StatefulWidget {
  /// Creates a new instance of [Sidebar].
  const Sidebar({
    required this.onSelectionChanged,
    super.key,
  });

  final ValueChanged<SidebarSelection> onSelectionChanged;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<Folder> _folders = [];
  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await NoteRepository.instance.getAllFolders();
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _createNewFolder() async {
    final name = await _showFolderNameDialog();
    if (name != null && name.isNotEmpty) {
      await NoteRepository.instance.createFolder(name);
      await _loadFolders();
    }
  }

  Future<void> _performBackup() async {
    try {
      final path = await _backupService.exportDatabaseToJson();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved to: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<String?> _showFolderNameDialog({Folder? existingFolder}) {
    final controller = TextEditingController(text: existingFolder?.name);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingFolder == null ? 'New Folder' : 'Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
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
            child: Text('My Notes', style: Theme.of(context).textTheme.headlineSmall),
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
          Expanded(
            child: ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  selected: _selection.type == SidebarItemType.folder && _selection.folder?.id == folder.id,
                  onTap: () {
                    final newSelection = SidebarSelection(SidebarItemType.folder, folder: folder);
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New Folder'),
            onTap: _createNewFolder,
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Notes'),
            onTap: _performBackup,
          ),
        ],
      ),
    );
  }
}
