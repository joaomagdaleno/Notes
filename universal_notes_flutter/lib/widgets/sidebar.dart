import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/models/tag.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
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
  final Tag? tag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarSelection &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          folder?.id == other.folder?.id &&
          tag?.id == other.tag?.id;

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
  List<Folder> _folders = [];
  List<Tag> _tags = [];
  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    final folders = await NoteRepository.instance.getAllFolders();
    final tags = await NoteRepository.instance.getAllTags();
    if (mounted) {
      setState(() {
        _folders = folders;
        _tags = tags;
      });
    }
  }

  Future<void> _createNewFolder() async {
    final name = await _showInputDialog(title: 'New Folder');
    if (name != null && name.isNotEmpty) {
      await NoteRepository.instance.createFolder(name);
      await _loadData();
    }
  }

  Future<void> _renameTag(Tag tag) async {
    final newName =
        await _showInputDialog(title: 'Rename Tag', existingValue: tag.name);
    if (newName != null && newName.isNotEmpty) {
      await NoteRepository.instance.updateTag(Tag(id: tag.id, name: newName));
      await _loadData();
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete the tag "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NoteRepository.instance.deleteTag(tag.id);
      await _loadData();
    }
  }

  Future<void> _showTagContextMenu(BuildContext context, Tag tag) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        overlay.localToGlobal(Offset.zero),
        overlay.localToGlobal(overlay.size.bottomRight(Offset.zero)),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          onTap: () => unawaited(_renameTag(tag)),
          child: const Text('Rename'),
        ),
        PopupMenuItem(
          onTap: () => unawaited(_deleteTag(tag)),
          child: const Text('Delete'),
        ),
      ],
    );
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
            child: ListView.builder(
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                return GestureDetector(
                  onLongPress: () => unawaited(_showTagContextMenu(context, tag)),
                  child: ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(tag.name),
                    selected: _selection.type == SidebarItemType.tag &&
                        _selection.tag?.id == tag.id,
                    onTap: () {
                      final newSelection =
                          SidebarSelection(SidebarItemType.tag, tag: tag);
                      setState(() => _selection = newSelection);
                      widget.onSelectionChanged(newSelection);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New Folder'),
            onTap: () => unawaited(_createNewFolder()),
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
