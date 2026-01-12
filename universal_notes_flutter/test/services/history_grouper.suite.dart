@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/services/history_grouper.dart';

void main() {
  group('HistoryGrouper', () {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final twoHoursAgo = now.subtract(const Duration(hours: 2));
    final twoDaysAgo = now.subtract(const Duration(days: 2));

    test('groupEvents should return empty list for empty input', () {
      final result = HistoryGrouper.groupEvents([]);
      expect(result, isEmpty);
    });

    test('groupEvents should group recent events by session (10m gap)', () {
      final events = [
        NoteEvent(
          id: '1',
          noteId: 'n1',
          type: NoteEventType.insert,
          timestamp: twoHoursAgo,
          payload: {'index': 0, 'text': 'H'},
        ),
        NoteEvent(
          id: '2',
          noteId: 'n1',
          type: NoteEventType.insert,
          timestamp: twoHoursAgo.add(const Duration(minutes: 5)),
          payload: {'index': 1, 'text': 'e'},
        ),
        // Gap of 15 minutes
        NoteEvent(
          id: '3',
          noteId: 'n1',
          type: NoteEventType.insert,
          timestamp: twoHoursAgo.add(const Duration(minutes: 20)),
          payload: {'index': 2, 'text': 'l'},
        ),
      ];

      final result = HistoryGrouper.groupEvents(events);

      // Should have 2 points: "Versão Atual" and one session before it.
      // Points are newest first.
      expect(result.length, 2);
      expect(result[0].label, 'Versão Atual');
      expect(result[0].eventsUpToPoint.length, 3);

      expect(result[1].label, contains('Sessão'));
      expect(result[1].eventsUpToPoint.length, 2);
    });

    test('groupEvents should handle old events with daily compression', () {
      // 10 events on the same day, 2 days ago
      final events = List.generate(
        10,
        (i) => NoteEvent(
          id: 'old_$i',
          noteId: 'n1',
          type: NoteEventType.insert,
          timestamp: twoDaysAgo.add(Duration(minutes: i)),
          payload: {'index': i, 'text': 'x'},
        ),
      );

      final result = HistoryGrouper.groupEvents(events);

      // Should have 5 points for that day (max 5 strategy)
      expect(result.length, 5);
      for (final point in result) {
        expect(point.label, 'Resumo Diário');
      }
    });

    test('groupEvents should handle mixed recent and old events', () {
      final oldEvent = NoteEvent(
        id: 'old',
        noteId: 'n1',
        type: NoteEventType.insert,
        timestamp: twoDaysAgo,
        payload: {'index': 0},
      );
      final recentEvent = NoteEvent(
        id: 'recent',
        noteId: 'n1',
        type: NoteEventType.insert,
        timestamp: oneHourAgo,
        payload: {'index': 1},
      );

      final result = HistoryGrouper.groupEvents([oldEvent, recentEvent]);

      expect(result.length, 2);
      expect(result[0].label, 'Versão Atual');
      expect(result[1].label, 'Resumo Diário');
    });

    test('groupEvents should group events by day for old events', () {
      final day1 = now.subtract(const Duration(days: 2));
      final day2 = now.subtract(const Duration(days: 3));

      final events = [
        NoteEvent(
          id: '1',
          noteId: 'n1',
          type: NoteEventType.unknown,
          timestamp: day2,
          payload: {},
        ),
        NoteEvent(
          id: '2',
          noteId: 'n1',
          type: NoteEventType.unknown,
          timestamp: day1,
          payload: {},
        ),
      ];

      final result = HistoryGrouper.groupEvents(events);
      expect(result.length, 2);
      expect(result[0].timestamp, day1);
      expect(result[1].timestamp, day2);
    });
  });
}
