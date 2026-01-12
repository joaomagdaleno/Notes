@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/sync_conflict.dart';

void main() {
  group('SyncConflict', () {
    final localNote = Note(
      id: '1',
      title: 'Local Title',
      content: 'Local Content',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );

    final remoteNote = Note(
      id: '1',
      title: 'Remote Title',
      content: 'Remote Content',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );

    test('should create a SyncConflict instance with current timestamp', () {
      final conflict = SyncConflict(
        localNote: localNote,
        remoteNote: remoteNote,
      );

      expect(conflict.localNote, localNote);
      expect(conflict.remoteNote, remoteNote);
      expect(
        conflict.timestamp.millisecondsSinceEpoch,
        closeTo(DateTime.now().millisecondsSinceEpoch, 100),
      );
    });
  });
}
