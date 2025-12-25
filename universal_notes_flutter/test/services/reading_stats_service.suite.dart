@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/services/reading_stats_service.dart';

import 'reading_interaction_service_test.mocks.dart';

void main() {
  late ReadingStatsService service;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockDatabase();
    service = ReadingStatsService(database: mockDatabase);
  });

  group('ReadingStatsService', () {
    test('getStatsForNote returns stats', () async {
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer(
        (_) async => [
          {'noteId': 'note1', 'totalReadingTimeSeconds': 120},
        ],
      );

      final result = await service.getStatsForNote('note1');

      expect(result.noteId, 'note1');
      expect(result.totalReadingTimeSeconds, 120);
    });

    test('getStatsForNote returns default for new note', () async {
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => []);

      final result = await service.getStatsForNote('note2');

      expect(result.noteId, 'note2');
      expect(result.totalReadingTimeSeconds, 0);
    });

    test('updatePosition saves position', () async {
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockDatabase.insert(
          any,
          any,
          conflictAlgorithm: anyNamed('conflictAlgorithm'),
        ),
      ).thenAnswer((_) async => 1);

      await service.updatePosition('note1', 100);

      verify(
        mockDatabase.insert(
          'reading_stats',
          argThat(containsPair('lastReadPosition', 100)),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).called(1);
    });

    test('setReadingGoal saves goal', () async {
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockDatabase.insert(
          any,
          any,
          conflictAlgorithm: anyNamed('conflictAlgorithm'),
        ),
      ).thenAnswer((_) async => 1);

      await service.setReadingGoal('note1', 30);

      verify(
        mockDatabase.insert(
          'reading_stats',
          argThat(containsPair('readingGoalMinutes', 30)),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).called(1);
    });
  });
}
