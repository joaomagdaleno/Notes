import 'dart:convert';
import 'package:test/test.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';

void main() {
  group('NoteEvent', () {
    final timestamp = DateTime(2023);
    final payload = {'text': 'hello', 'position': 0};

    test('should create a NoteEvent instance', () {
      final event = NoteEvent(
        id: 'evt1',
        noteId: 'note1',
        type: NoteEventType.insert,
        payload: payload,
        timestamp: timestamp,
        deviceId: 'dev1',
      );

      expect(event.id, 'evt1');
      expect(event.noteId, 'note1');
      expect(event.type, NoteEventType.insert);
      expect(event.payload, payload);
      expect(event.timestamp, timestamp);
      expect(event.deviceId, 'dev1');
    });

    test('fromMap should create a NoteEvent from a local map', () {
      final map = {
        'id': 'evt2',
        'noteId': 'note2',
        'type': 'delete',
        'payload': jsonEncode({'length': 5, 'position': 10}),
        'timestamp': timestamp.millisecondsSinceEpoch,
        'syncStatus': 'modified',
        'deviceId': 'dev2',
      };

      final event = NoteEvent.fromMap(map);

      expect(event.id, 'evt2');
      expect(event.type, NoteEventType.delete);
      expect(event.payload['length'], 5);
      expect(event.syncStatus, SyncStatus.modified);
    });

    test('fromFirestore should create a NoteEvent from Firestore data', () {
      final map = {
        'noteId': 'note3',
        'type': 'format',
        'payload': {'bold': true},
        'timestamp': timestamp.millisecondsSinceEpoch,
        'deviceId': 'dev3',
      };

      final event = NoteEvent.fromFirestore(map, 'doc123');

      expect(event.id, 'doc123');
      expect(event.noteId, 'note3');
      expect(event.type, NoteEventType.format);
      expect(event.syncStatus, SyncStatus.synced);
    });

    test('toMap should convert to local map', () {
      final event = NoteEvent(
        id: 'evt4',
        noteId: 'note4',
        type: NoteEventType.imageInsert,
        payload: {'url': 'http://test.com'},
        timestamp: timestamp,
      );

      final map = event.toMap();

      expect(map['id'], 'evt4');
      expect(map['type'], 'imageInsert');
      final payload =
          jsonDecode(map['payload'] as String) as Map<String, dynamic>;
      expect(payload['url'], 'http://test.com');
      expect(map['syncStatus'], 'local');
    });

    test('toFirestore should convert to Firestore map', () {
      final event = NoteEvent(
        id: 'evt5',
        noteId: 'note5',
        type: NoteEventType.insert,
        payload: {'text': 'abc'},
        timestamp: timestamp,
        deviceId: 'dev5',
      );

      final map = event.toFirestore();

      expect(map['noteId'], 'note5');
      final payload = map['payload'] as Map<String, dynamic>;
      expect(payload['text'], 'abc');
      expect(map['deviceId'], 'dev5');
    });

    test('copyWith should return a new instance with updated fields', () {
      final event = NoteEvent(
        id: 'evt6',
        noteId: 'note6',
        type: NoteEventType.insert,
        payload: {},
        timestamp: timestamp,
      );

      final updated = event.copyWith(syncStatus: SyncStatus.synced);

      expect(updated.id, event.id);
      expect(updated.syncStatus, SyncStatus.synced);
      expect(event.syncStatus, SyncStatus.local);
    });
  });
}
