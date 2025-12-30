import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
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
    String? name;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      name = await fluent.showDialog<String>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('New Folder'),
          content: fluent.TextBox(
            controller: controller,
            placeholder: 'Folder Name',
            autofocus: true,
          ),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            fluent.FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Create'),
            ),
          ],
        ),
      );
    } else {
      name = await showDialog<String>(
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
    }

    if (name != null && name.trim().isNotEmpty) {
      await _noteRepository.createFolder(name.trim());
      await _syncService.refreshLocalData();
    }
  }

  Future<void> _deleteFolder(String folderId) async {
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
    String? password;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      password = await fluent.showDialog<String>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Encrypt Backup'),
          content: fluent.PasswordBox(
            controller: controller,
            placeholder: 'Enter Backup Password',
          ),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            fluent.FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Export'),
            ),
          ],
        ),
      );
    } else {
      password = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Encrypt Backup'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter Backup Password'),
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
    }

    if (password == null || password.isEmpty) return;

    try {
      final path = await _backupService.exportBackup(password);
      if (!mounted) return;

      if (defaultTargetPlatform == TargetPlatform.windows) {
        await fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Backup Saved'),
            content: Text('Encrypted backup saved to: $path'),
            severity: fluent.InfoBarSeverity.success,
            onClose: close,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Encrypted backup saved to: $path')),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;

      if (defaultTargetPlatform == TargetPlatform.windows) {
        await fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Backup Failed'),
            content: Text('$e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    unawaited(StartupLogger.log('🎨 [BUILD] Sidebar.build called'));

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentSidebar(context);
    } else {
      return _buildMaterialSidebar(context);
    }
  }

  Widget _buildFluentSidebar(BuildContext context) {
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
                  selected: _selection.type == SidebarItemType.all,
                  onPressed: () {
                    const newSelection = SidebarSelection(SidebarItemType.all);
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
                ),
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.favorite_star),
                  title: const Text('Favorites'),
                  selected: _selection.type == SidebarItemType.favorites,
                  onPressed: () {
                    const newSelection =
                        SidebarSelection(SidebarItemType.favorites);
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
                ),
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.delete),
                  title: const Text('Trash'),
                  selected: _selection.type == SidebarItemType.trash,
                  onPressed: () {
                    const newSelection =
                        SidebarSelection(SidebarItemType.trash);
                    setState(() => _selection = newSelection);
                    widget.onSelectionChanged(newSelection);
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Folders',
                    style: theme.typography.caption,
                  ),
                ),
                StreamBuilder<List<Folder>>(
                  stream: _foldersStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final folders = snapshot.data!;
                    return Column(
                      children: folders.map((folder) {
                        return fluent.ListTile.selectable(
                          leading: const Icon(fluent.FluentIcons.folder),
                          title: Text(folder.name),
                          selected:
                              _selection.type == SidebarItemType.folder &&
                                  _selection.folder?.id == folder.id,
                          trailing: fluent.IconButton(
                            icon: const Icon(fluent.FluentIcons.delete),
                            onPressed: () =>
                                unawaited(_deleteFolder(folder.id)),
                          ),
                          onPressed: () {
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Tags',
                    style: theme.typography.caption,
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
                        return fluent.ListTile.selectable(
                          leading: const Icon(fluent.FluentIcons.tag),
                          title: Text(tag),
                          selected: _selection.type == SidebarItemType.tag &&
                              _selection.tag == tag,
                          onPressed: () {
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
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.add),
                  title: const Text('New Folder'),
                  onPressed: () => unawaited(_createNewFolder()),
                ),
                fluent.ListTile.selectable(
                  leading: const Icon(fluent.FluentIcons.cloud_download),
                  title: const Text('Backup Notes'),
                  onPressed: () => unawaited(_performBackup()),
                ),
                const Divider(),
                _buildAccountSection(isFluent: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSidebar(BuildContext context) {
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
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(folder.name),
                          selected:
                              _selection.type == SidebarItemType.folder &&
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
                _buildAccountSection(isFluent: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection({required bool isFluent}) {
    return Builder(
      builder: (context) {
        final user = context.watch<User?>();
        if (user == null) {
          if (isFluent) {
            return fluent.ListTile.selectable(
              leading: const Icon(fluent.FluentIcons.signin),
              title: const Text('Sign In to Sync'),
              onPressed: () {
                Navigator.pop(context);
                unawaited(
                  Navigator.push(
                    context,
                    fluent.FluentPageRoute(
                      builder: (context) => const AuthScreen(),
                    ),
                  ),
                );
              },
            );
          } else {
            return ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In to Sync'),
              onTap: () {
                Navigator.pop(context);
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
        }

        if (isFluent) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        user.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.email ?? 'Authenticated',
                        style: fluent.FluentTheme.of(context).typography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              fluent.ListTile.selectable(
                leading: const Icon(fluent.FluentIcons.sign_out),
                title: const Text('Sign Out'),
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();
                },
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        user.email?.substring(0, 1).toUpperCase() ?? 'U',
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
                  Navigator.pop(context);
                  await AuthService().signOut();
                },
              ),
            ],
          );
        }
      },
    );
  }
}
