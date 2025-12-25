@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/services/event_replayer.dart';

void main() {
  group('EventReplayer', () {
    test('reconstructs empty document from no events', () {
      final result = EventReplayer.reconstruct([]);
      expect(result.blocks, isEmpty);
    });

    test('reconstructs document from insert events', () {
      final events = [
        NoteEvent(
          id: '1',
          noteId: 'note1',
          type: NoteEventType.insert,
          payload: {'pos': 0, 'text': 'Hello'},
          timestamp: DateTime(2024, 1, 1, 10),
        ),
        NoteEvent(
          id: '2',
          noteId: 'note1',
          type: NoteEventType.insert,
          payload: {'pos': 5, 'text': ' World'},
          timestamp: DateTime(2024, 1, 1, 10, 1),
        ),
      ];

      final result = EventReplayer.reconstruct(events);
      expect(result.toPlainText(), equals('Hello World'));
    });

    test('reconstructs document with delete events', () {
      final events = [
        NoteEvent(
          id: '1',
          noteId: 'note1',
          type: NoteEventType.insert,
          payload: {'pos': 0, 'text': 'Hello World'},
          timestamp: DateTime(2024, 1, 1, 10),
        ),
        NoteEvent(
          id: '2',
          noteId: 'note1',
          type: NoteEventType.delete,
          payload: {'pos': 5, 'len': 6}, // Delete " World"
          timestamp: DateTime(2024, 1, 1, 10, 1),
        ),
      ];

      final result = EventReplayer.reconstruct(events);
      expect(result.toPlainText(), equals('Hello'));
    });

    test('handles events out of order by sorting', () {
      final events = [
        NoteEvent(
          id: '2',
          noteId: 'note1',
          type: NoteEventType.insert,
          payload: {'pos': 5, 'text': ' World'},
          timestamp: DateTime(2024, 1, 1, 10, 1),
        ),
        NoteEvent(
          id: '1',
          noteId: 'note1',
          type: NoteEventType.insert,
          payload: {'pos': 0, 'text': 'Hello'},
          timestamp: DateTime(2024, 1, 1, 10),
        ),
      ];

      final result = EventReplayer.reconstruct(events);
      expect(result.toPlainText(), equals('Hello World'));
    });

    test('applies baseline document if provided', () {
      final baseline = DocumentModel.fromPlainText('Existing ');
      final events = [
        NoteEvent(
          id: '1',
          noteId: 'note1',
          type: NoteEventType.insert,
          payload: {'pos': 9, 'text': 'Content'},
          timestamp: DateTime(2024, 1, 1, 10),
        ),
      ];

      final result = EventReplayer.reconstruct(events, baseline: baseline);
      expect(result.toPlainText(), equals('Existing Content'));
    });
  });
}
