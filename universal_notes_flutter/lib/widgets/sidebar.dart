import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/auth_screen.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';
import 'package:universal_notes_flutter/services/startup_logger.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';

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
  // Folder logic
  late final Stream<List<Folder>> _foldersStream;
  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  final BackupService _backupService = BackupService.instance;
  final SyncService _syncService = SyncService.instance;
  final NoteRepository _noteRepository = NoteRepository.instance;
  late final Stream<List<String>> _tagsStream;

  @override
  void initState() {
    super.initState();
    _foldersStream = _syncService.foldersStream;
    _tagsStream = _syncService.tagsStream;
  }

  Future<void> _createNewFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      await _noteRepository.createFolder(name.trim());
      await _syncService.refreshLocalData();
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    // If selected folder is deleted, switch to All Notes
    if (_selection.type == SidebarItemType.folder &&
        _selection.folder?.id == folderId) {
      const newSelection = SidebarSelection(SidebarItemType.all);
      setState(() => _selection = newSelection);
      widget.onSelectionChanged(newSelection);
    }
    await _noteRepository.deleteFolder(folderId);
    await _syncService.refreshLocalData();
  }

  Future<void> _performBackup() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encrypt Backup'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter Backup Password'),
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    try {
      final path = await _backupService.exportBackup(password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encrypted backup saved to: $path')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    unawaited(StartupLogger.log('🎨 [BUILD] Sidebar.build called'));
    // Use a Container on desktop to avoid Material Drawer conflicts with
    // Fluent UI
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
                  selected: _selection.type == SidebarItemType.all,
                  onTap: () {
                    const newSelection = SidebarSelection(SidebarItemType.all);
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
                ),
                ListTile(
                  key: const ValueKey('favorites'),
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Favorites'),
                  selected: _selection.type == SidebarItemType.favorites,
                  onTap: () {
                    const newSelection =
                        SidebarSelection(SidebarItemType.favorites);
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
                ),
                ListTile(
                  key: const ValueKey('trash'),
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Trash'),
                  selected: _selection.type == SidebarItemType.trash,
                  onTap: () {
                    const newSelection =
                        SidebarSelection(SidebarItemType.trash);
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
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
                  stream: _foldersStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final folders = snapshot.data!;
                    return Column(
                      children: folders.map((folder) {
                        return ListTile(
                          leading: const Icon(
                            Icons.folder_outlined,
                          ), // Changed to outlined
                          title: Text(folder.name),
                          selected: _selection.type == SidebarItemType.folder &&
                              _selection.folder?.id == folder.id,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await _deleteFolder(folder.id);
                              }
                            },
                          ),
                          onTap: () {
                            final newSelection = SidebarSelection(
                              SidebarItemType.folder,
                              folder: folder,
                            );
                            setState(() => _selection = newSelection);
                            widget.onSelectionChanged(newSelection);
                          },
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
                  stream: _tagsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final tags = snapshot.data!;
                    if (tags.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: tags.map((tag) {
                        return ListTile(
                          title: Text(tag),
                          leading: const Icon(Icons.label_outline),
                          selected: _selection.type == SidebarItemType.tag &&
                              _selection.tag == tag,
                          onTap: () {
                            final newSelection = SidebarSelection(
                              SidebarItemType.tag,
                              tag: tag,
                            );
                            setState(() => _selection = newSelection);
                            widget.onSelectionChanged(newSelection);
                          },
                        );
                      }).toList(),
                    );
                  },
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
                const Divider(),
                // --- Account / Auth Section ---
                Builder(
                  builder: (context) {
                    final user = context.watch<User?>();
                    if (user == null) {
                      return ListTile(
                        leading: const Icon(Icons.login),
                        title: const Text('Sign In to Sync'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          unawaited(
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                child: Text(
                                  user.email?.substring(0, 1).toUpperCase() ??
                                      'U',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user.email ?? 'Authenticated',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign Out'),
                          onTap: () async {
                            Navigator.pop(context); // Close drawer
                            await AuthService().signOut();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
