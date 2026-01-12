@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes_hub/services/reading_stats_service.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase extends Mock implements Database {}

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
        () => mockDatabase.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
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
        () => mockDatabase.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => []);

      final result = await service.getStatsForNote('note2');

      expect(result.noteId, 'note2');
      expect(result.totalReadingTimeSeconds, 0);
    });

    test('updatePosition saves position', () async {
      when(
        () => mockDatabase.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockDatabase.insert(
          any(),
          any(),
          conflictAlgorithm: any(named: 'conflictAlgorithm'),
        ),
      ).thenAnswer((_) async => 1);

      await service.updatePosition('note1', 100);

      verify(
        () => mockDatabase.insert(
          'reading_stats',
          any(that: containsPair('lastReadPosition', 100)),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).called(1);
    });

    test('setReadingGoal saves goal', () async {
      when(
        () => mockDatabase.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockDatabase.insert(
          any(),
          any(),
          conflictAlgorithm: any(named: 'conflictAlgorithm'),
        ),
      ).thenAnswer((_) async => 1);

      await service.setReadingGoal('note1', 30);

      verify(
        () => mockDatabase.insert(
          'reading_stats',
          any(that: containsPair('readingGoalMinutes', 30)),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).called(1);
    });
  });
}
