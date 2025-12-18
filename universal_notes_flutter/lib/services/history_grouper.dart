import 'package:universal_notes_flutter/models/note_event.dart';

/// Represents a point in history that the user can revert to.
class HistoryPoint {
  const HistoryPoint({
    required this.timestamp,
    required this.eventsUpToPoint,
    required this.label,
  });

  /// The timestamp of this history point (usually the time of the last event in the group).
  final DateTime timestamp;

  /// The list of events that leads to this point from the beginning.
  /// (Or the subset of events if we optimize later).
  /// For now, this is the full list up to this point.
  final List<NoteEvent> eventsUpToPoint;

  /// A user-friendly label (e.g., "Edited 10 minutes ago", "Daily Summary").
  final String label;
}

class HistoryGrouper {
  /// Groups raw [events] into meaningful [HistoryPoint]s.
  ///
  /// Strategy:
  /// 1. Events < 24h old: Group by session (gap > 10m = new session).
  /// 2. Events > 24h old: Compress to max 5 versions per day.
  static List<HistoryPoint> groupEvents(List<NoteEvent> events) {
    if (events.isEmpty) return [];

    final sortedEvents = List<NoteEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final points = <HistoryPoint>[];
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(hours: 24));

    // Split events into recent and old
    final recentEvents = <NoteEvent>[];
    final oldEvents = <NoteEvent>[];

    for (final event in sortedEvents) {
      if (event.timestamp.isAfter(oneDayAgo)) {
        recentEvents.add(event);
      } else {
        oldEvents.add(event);
      }
    }

    // Process old events (Daily compression)
    points.addAll(_processOldEvents(oldEvents));

    // Process recent events (Session grouping)
    points.addAll(_processRecentEvents(recentEvents, oldEvents));

    // Sort points descending (newest first) for UI
    return points.reversed.toList();
  }

  static List<HistoryPoint> _processRecentEvents(
    List<NoteEvent> recentEvents,
    List<NoteEvent> priorEvents,
  ) {
    final points = <HistoryPoint>[];
    if (recentEvents.isEmpty) return points;

    final allEventsRun = [...priorEvents];
    // ignore: unused_local_variable
    var currentSessionStart = recentEvents.first.timestamp;
    var lastEventTime = recentEvents.first.timestamp;

    for (var i = 0; i < recentEvents.length; i++) {
      final event = recentEvents[i];
      final timeDiff = event.timestamp.difference(lastEventTime).inMinutes;

      // If gap > 10 mins, close previous session and start new one
      if (i > 0 && timeDiff > 10) {
        // Checkpoint at the LAST event of the previous session
        points.add(
          HistoryPoint(
            timestamp: lastEventTime,
            eventsUpToPoint: List.from(
              allEventsRun,
            ), // Snapshot of events up to here
            label: 'Sessão ${points.length + 1}', // Placeholder
          ),
        );
        currentSessionStart = event.timestamp;
      }

      allEventsRun.add(event);
      lastEventTime = event.timestamp;
    }

    // Always add the very latest state
    points.add(
      HistoryPoint(
        timestamp: lastEventTime,
        eventsUpToPoint: List.from(allEventsRun),
        label: 'Versão Atual',
      ),
    );

    return points;
  }

  static List<HistoryPoint> _processOldEvents(List<NoteEvent> oldEvents) {
    // Group by day key (YYYY-MM-DD)
    final points = <HistoryPoint>[];
    if (oldEvents.isEmpty) return points;

    final eventsByDay =
        <String, List<int>>{}; // dayKey -> list of INDICES in oldEvents

    for (var i = 0; i < oldEvents.length; i++) {
      final event = oldEvents[i];
      final dayKey =
          '${event.timestamp.year}-${event.timestamp.month}-${event.timestamp.day}';
      eventsByDay.putIfAbsent(dayKey, () => []).add(i);
    }

    for (final dayEntry in eventsByDay.entries) {
      final indices = dayEntry.value;
      final selectedIndices = <int>{};

      // Max 5 strategy
      if (indices.length <= 5) {
        selectedIndices.addAll(indices);
      } else {
        // Always include Last (end of day state)
        selectedIndices.add(indices.last);
        // Always include First (start of day changes)
        selectedIndices.add(indices.first);
        // Pick 3 more
        final step = (indices.length - 1) / 4;
        for (var k = 1; k < 4; k++) {
          selectedIndices.add(indices[(k * step).round()]);
        }
      }

      final sortedSelected = selectedIndices.toList()..sort();

      for (final idx in sortedSelected) {
        final event = oldEvents[idx];
        points.add(
          HistoryPoint(
            timestamp: event.timestamp,
            eventsUpToPoint: oldEvents.sublist(0, idx + 1),
            label: 'Resumo Diário',
          ),
        );
      }
    }
    return points;
  }
}
