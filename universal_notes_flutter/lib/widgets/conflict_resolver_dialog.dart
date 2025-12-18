import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/sync_conflict.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

class ConflictResolverDialog extends StatelessWidget {
  const ConflictResolverDialog({required this.conflict, super.key});
  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            // Merge logic usually goes here, for now just allow pick manual
            Navigator.pop(context);
          },
          child: const Text('Decide Later'),
        ),
      ],
    );
  }

  Future<void> _resolve(BuildContext context, {required bool useRemote}) async {
    final noteRepo = NoteRepository.instance;
    final navigator = Navigator.of(context);
    if (useRemote) {
      // Overwrite local with remote
      await noteRepo.updateNoteContent(
        conflict.remoteNote.copyWith(syncStatus: SyncStatus.synced),
      );
    } else {
      // Force local. Next syncUp will push it to remote.
      await noteRepo.updateNote(
        conflict.localNote.copyWith(syncStatus: SyncStatus.modified),
      );
    }
    navigator.pop();
  }
}

Future<void> showConflictResolver(
  BuildContext context,
  SyncConflict conflict,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => ConflictResolverDialog(conflict: conflict),
  );
}
