import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/folder.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/screens/auth_screen.dart';
import 'package:notes_hub/services/auth_service.dart';
import 'package:notes_hub/services/backup_service.dart';
import 'package:notes_hub/services/startup_logger.dart';
import 'package:notes_hub/services/sync_service.dart';
import 'package:notes_hub/widgets/sidebar/fluent_sidebar_view.dart';
import 'package:notes_hub/widgets/sidebar/material_sidebar_view.dart';
import 'package:provider/provider.dart';

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
      return FluentSidebarView(
        selection: _selection,
        onSelectionChanged: (selection) {
          setState(() => _selection = selection);
          widget.onSelectionChanged(selection);
        },
        foldersStream: _foldersStream,
        tagsStream: _tagsStream,
        onCreateFolder: () => unawaited(_createNewFolder()),
        onDeleteFolder: (id) => unawaited(_deleteFolder(id)),
        onPerformBackup: () => unawaited(_performBackup()),
        accountSection: _buildAccountSection(isFluent: true),
      );
    } else {
      return MaterialSidebarView(
        selection: _selection,
        onSelectionChanged: (selection) {
          setState(() => _selection = selection);
          widget.onSelectionChanged(selection);
        },
        foldersStream: _foldersStream,
        tagsStream: _tagsStream,
        onCreateFolder: () => unawaited(_createNewFolder()),
        onDeleteFolder: (id) => unawaited(_deleteFolder(id)),
        onPerformBackup: () => unawaited(_performBackup()),
        accountSection: _buildAccountSection(isFluent: false),
      );
    }
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
                        style:
                            fluent.FluentTheme.of(context).typography.caption,
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
