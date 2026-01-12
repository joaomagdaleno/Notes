import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notes_hub/models/reading_stats.dart';
import 'package:sqflite/sqflite.dart';

/// Service for tracking reading statistics (time, position, goals).
class ReadingStatsService extends ChangeNotifier {
  /// Creates a new [ReadingStatsService].
  ReadingStatsService({required Database database}) : _database = database;

  final Database _database;
  static const _tableName = 'reading_stats';

  Timer? _readingTimer;
  DateTime? _sessionStartTime;
  String? _currentNoteId;

  /// Gets stats for a note.
  Future<ReadingStats> getStatsForNote(String noteId) async {
    final results = await _database.query(
      _tableName,
      where: 'noteId = ?',
      whereArgs: [noteId],
    );

    if (results.isEmpty) {
      return ReadingStats(noteId: noteId);
    }
    return ReadingStats.fromMap(results.first);
  }

  /// Starts tracking a reading session.
  void startSession(String noteId) {
    if (_currentNoteId == noteId) return;
    stopSession();

    _currentNoteId = noteId;
    _sessionStartTime = DateTime.now();
    unawaited(_saveLastOpened(noteId));

    _readingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      unawaited(_incrementTime(noteId, 60));
    });
  }

  /// Stops tracking the current session.
  void stopSession() {
    if (_currentNoteId != null && _sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      unawaited(_incrementTime(_currentNoteId!, duration.inSeconds % 60));
    }
    _readingTimer?.cancel();
    _currentNoteId = null;
    _sessionStartTime = null;
  }

  /// Updates the last read position.
  Future<void> updatePosition(String noteId, int position) async {
    final stats = await getStatsForNote(noteId);
    await _saveStats(stats.copyWith(lastReadPosition: position));
  }

  /// Sets a reading goal (in minutes).
  Future<void> setReadingGoal(String noteId, int minutes) async {
    final stats = await getStatsForNote(noteId);
    await _saveStats(stats.copyWith(readingGoalMinutes: minutes));
  }

  Future<void> _incrementTime(String noteId, int seconds) async {
    final stats = await getStatsForNote(noteId);
    await _saveStats(
      stats.copyWith(
        totalReadingTimeSeconds: stats.totalReadingTimeSeconds + seconds,
      ),
    );
  }

  Future<void> _saveLastOpened(String noteId) async {
    final stats = await getStatsForNote(noteId);
    await _saveStats(stats.copyWith(lastOpenedAt: DateTime.now()));
  }

  Future<void> _saveStats(ReadingStats stats) async {
    await _database.insert(
      _tableName,
      stats.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }
}
