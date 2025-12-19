import 'package:test/test.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/services/history_grouper.dart';

void main() {
  group('HistoryGrouper', () {
    final now = DateTime.now();

    NoteEvent createEvent(String id, DateTime timestamp) {
      return NoteEvent(
        id: id,
        noteId: 'note1',
        type: NoteEventType.insert,
        payload: {'text': 'a'},
        timestamp: timestamp,
      );
    }

    test('should return empty list for empty events', () {
      expect(HistoryGrouper.groupEvents([]), isEmpty);
    });

    test('should group recent events by session (10m gap)', () {
      final e1 = createEvent('1', now.subtract(const Duration(minutes: 30)));
      final e2 = createEvent(
        '2',
        now.subtract(const Duration(minutes: 25)),
      ); // session 1
      final e3 = createEvent(
        '3',
        now.subtract(const Duration(minutes: 5)),
      ); // session 2

      final points = HistoryGrouper.groupEvents([e1, e2, e3]);

      // Reversed: [Versão Atual, Sessão 1]
      expect(points.length, 2);
      expect(points[0].label, 'Versão Atual');
      expect(points[1].label, 'Sessão 1');
      expect(points[0].eventsUpToPoint.length, 3);
      expect(points[1].eventsUpToPoint.length, 2);
    });

    test('should compress old events (daily summary)', () {
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final events = List.generate(
        10,
        (i) => createEvent('old_$i', twoDaysAgo.add(Duration(minutes: i * 5))),
      );

      final points = HistoryGrouper.groupEvents(events);

      // Should have some "Resumo Diário" points and "Versão Atual" (if any recent)
      // Since all are old, we get daily summaries.
      // Max 5 strategy for old events.
      expect(points.any((p) => p.label == 'Resumo Diário'), isTrue);
      expect(
        points.length,
        lessThanOrEqualTo(6),
      ); // 5 summaries + maybe one more? No, reversed.
    });

    test('should handle mix of old and recent events', () {
      final old = createEvent('old', now.subtract(const Duration(days: 2)));
      final recent = createEvent(
        'recent',
        now.subtract(const Duration(minutes: 5)),
      );

      final points = HistoryGrouper.groupEvents([old, recent]);

      expect(points.length, 2);
      expect(points[0].label, 'Versão Atual');
      expect(points[1].label, 'Resumo Diário');
    });
  });
}
