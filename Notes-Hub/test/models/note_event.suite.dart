@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/models/note_event.dart';
import 'package:notes_hub/models/sync_status.dart';

void main() {
  group('NoteEvent', () {
    final timestamp = DateTime(2023, 1, 1, 12);
    const payload = {'text': 'Hello', 'pos': 0};

    test('toMap/fromMap symmetry', () {
      final event = NoteEvent(
        id: 'e1',
        noteId: 'n1',
        type: NoteEventType.insert,
        payload: payload,
        timestamp: timestamp,
        deviceId: 'd1',
      );

      final map = event.toMap();
      final fromMap = NoteEvent.fromMap(map);

      expect(fromMap.id, event.id);
      expect(fromMap.noteId, event.noteId);
      expect(fromMap.type, event.type);
      expect(fromMap.payload, event.payload);
      expect(
        fromMap.timestamp.millisecondsSinceEpoch,
        event.timestamp.millisecondsSinceEpoch,
      );
      expect(fromMap.syncStatus, event.syncStatus);
      expect(fromMap.deviceId, event.deviceId);
    });

    test('fromFirestore handles different value types', () {
      final firestoreMap = {
        'noteId': 'n1',
        'type': 'insert',
        'payload': payload,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'deviceId': 'd1',
      };

      final event = NoteEvent.fromFirestore(firestoreMap, 'e1');

      expect(event.id, 'e1');
      expect(event.noteId, 'n1');
      expect(event.type, NoteEventType.insert);
      expect(event.payload, payload);
      expect(
        event.timestamp.millisecondsSinceEpoch,
        timestamp.millisecondsSinceEpoch,
      );
      expect(event.syncStatus, SyncStatus.synced);
    });

    test('toFirestore should include all fields', () {
      final event = NoteEvent(
        id: 'e1',
        noteId: 'n1',
        type: NoteEventType.delete,
        payload: {'len': 5},
        timestamp: timestamp,
      );

      final firestore = event.toFirestore();
      expect(firestore['noteId'], 'n1');
      expect(firestore['type'], 'delete');
      expect(firestore['payload'], {'len': 5});
      expect(firestore['timestamp'], timestamp.millisecondsSinceEpoch);
    });

    test('copyWith should update fields correctly', () {
      final event = NoteEvent(
        id: 'e1',
        noteId: 'n1',
        type: NoteEventType.insert,
        payload: {},
        timestamp: timestamp,
      );

      final updated = event.copyWith(id: 'e2', noteId: 'n2');
      expect(updated.id, 'e2');
      expect(updated.noteId, 'n2');
      expect(updated.type, event.type);
    });

    test('currentDeviceId should return something', () {
      expect(NoteEvent.currentDeviceId, isNotEmpty);
    });
  });
}
