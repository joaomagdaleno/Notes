import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';

/// A sidebar widget to display and manage folders.
class Sidebar extends StatefulWidget {
  /// Creates a new instance of [Sidebar].
  const Sidebar({
    required this.onFolderSelected,
    super.key,
  });

  /// Callback for when a folder is selected.
  /// If the folder is null, it means 'All Notes' was selected.
  final ValueChanged<Folder?> onFolderSelected;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<Folder> _folders = [];
  Folder? _selectedFolder;
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
            title: const Text('All Notes'),
            selected: _selectedFolder == null,
            onTap: () {
              setState(() => _selectedFolder = null);
              widget.onFolderSelected(null);
            },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return ListTile(
                  title: Text(folder.name),
                  selected: _selectedFolder?.id == folder.id,
                  onTap: () {
                    setState(() => _selectedFolder = folder);
                    widget.onFolderSelected(folder);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
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
