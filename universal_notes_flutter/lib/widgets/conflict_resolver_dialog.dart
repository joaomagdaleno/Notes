import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/sync_conflict.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

/// A dialog that allows users to resolve sync conflicts.
class ConflictResolverDialog extends StatelessWidget {
  /// Creates a new [ConflictResolverDialog].
  const ConflictResolverDialog({required this.conflict, super.key});

  /// The conflict to resolve.
  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentDialog(context);
    } else {
      return _buildMaterialDialog(context);
    }
  }

  Widget _buildFluentDialog(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return fluent.ContentDialog(
      title: const Text('Sync Conflict Detected'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A change was made on another device. How would you like to resolve it?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Local Version:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.resources.subtleFillColorSecondary,
              child: Text(
                conflict.localNote.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Remote Version:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.accentColor.withValues(alpha: 0.1),
              child: Text(
                conflict.remoteNote.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        fluent.Button(
          onPressed: () => _resolve(context, useRemote: false),
          child: const Text('Keep Local'),
        ),
        fluent.FilledButton(
          onPressed: () => _resolve(context, useRemote: true),
          child: const Text('Use Remote'),
        ),
        fluent.Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Decide Later'),
        ),
      ],
    );
  }

  Widget _buildMaterialDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync Conflict Detected'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A change was made on another device. How would you like to resolve it?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Local Version:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text(
                conflict.localNote.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Remote Version:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue[50],
              child: Text(
                conflict.remoteNote.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _resolve(context, useRemote: false),
          child: const Text('Keep Local'),
        ),
        TextButton(
          onPressed: () => _resolve(context, useRemote: true),
          child: const Text('Use Remote'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Decide Later'),
        ),
      ],
    );
  }

  Future<void> _resolve(BuildContext context, {required bool useRemote}) async {
    final noteRepo = NoteRepository.instance;
    final navigator = Navigator.of(context);
    if (useRemote) {
      await noteRepo.updateNoteContent(
        conflict.remoteNote.copyWith(syncStatus: SyncStatus.synced),
      );
    } else {
      await noteRepo.updateNote(
        conflict.localNote.copyWith(syncStatus: SyncStatus.modified),
      );
    }
    navigator.pop();
  }
}

/// Shows a dialog for resolving a sync conflict.
Future<void> showConflictResolver(
  BuildContext context,
  SyncConflict conflict,
) async {
  if (defaultTargetPlatform == TargetPlatform.windows) {
    await fluent.showDialog<void>(
      context: context,
      builder: (context) => ConflictResolverDialog(conflict: conflict),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (context) => ConflictResolverDialog(conflict: conflict),
    );
  }
}
