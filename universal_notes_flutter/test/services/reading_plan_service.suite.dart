@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/models/reading_plan_model.dart';
import 'package:universal_notes_flutter/services/reading_plan_service.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabase mockDatabase;
  late ReadingPlanService service;

  setUp(() {
    mockDatabase = MockDatabase();
    service = ReadingPlanService(database: mockDatabase);
  });

  group('ReadingPlanService', () {
    test('getAllPlans returns list of plans', () async {
      when(
        () => mockDatabase.query(
          'reading_plans',
          orderBy: any(named: 'orderBy'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'plan-1',
            'title': 'Test Plan',
            'noteIds': 'note1,note2',
            'currentIndex': 0,
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
      );

      final plans = await service.getAllPlans();

      expect(plans.length, 1);
      expect(plans.first.title, 'Test Plan');
      verify(
        () => mockDatabase.query('reading_plans', orderBy: 'createdAt DESC'),
      ).called(1);
    });

    test('getPlan returns plan by id', () async {
      when(
        () => mockDatabase.query(
          'reading_plans',
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'plan-1',
            'title': 'Test Plan',
            'noteIds': 'note1,note2',
            'currentIndex': 0,
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
      );

      final plan = await service.getPlan('plan-1');

      expect(plan, isNotNull);
      expect(plan!.id, 'plan-1');
      verify(
        () => mockDatabase.query(
          'reading_plans',
          where: 'id = ?',
          whereArgs: ['plan-1'],
        ),
      ).called(1);
    });

    test('getPlan returns null when not found', () async {
      when(
        () => mockDatabase.query(
          'reading_plans',
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => []);

      final plan = await service.getPlan('nonexistent');

      expect(plan, isNull);
    });

    test('createPlan inserts and returns plan', () async {
      when(
        () => mockDatabase.insert(
          'reading_plans',
          any(),
        ),
      ).thenAnswer((_) async => 1);

      final plan = await service.createPlan(
        title: 'New Plan',
        noteIds: ['note1', 'note2'],
      );

      expect(plan.title, 'New Plan');
      expect(plan.noteIds, ['note1', 'note2']);
      expect(plan.id, isNotEmpty);
      verify(
        () => mockDatabase.insert('reading_plans', any()),
      ).called(1);
    });

    test('updatePlan calls database update', () async {
      when(
        () => mockDatabase.update(
          'reading_plans',
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => 1);

      final plan = ReadingPlan(
        id: 'plan-1',
        title: 'Updated',
        noteIds: ['n1'],
        currentIndex: 2,
      );
      await service.updatePlan(plan);

      verify(
        () => mockDatabase.update(
          'reading_plans',
          any(),
          where: 'id = ?',
          whereArgs: ['plan-1'],
        ),
      ).called(1);
    });

    test('deletePlan calls database delete', () async {
      when(
        () => mockDatabase.delete(
          'reading_plans',
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => 1);

      await service.deletePlan('plan-1');

      verify(
        () => mockDatabase.delete(
          'reading_plans',
          where: 'id = ?',
          whereArgs: ['plan-1'],
        ),
      ).called(1);
    });

    test('findPlanForNote returns matching plan', () async {
      when(
        () => mockDatabase.query(
          'reading_plans',
          orderBy: any(named: 'orderBy'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'plan-1',
            'title': 'Plan with note',
            'noteIds': 'note1,note2,target-note',
            'currentIndex': 0,
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
      );

      final plan = await service.findPlanForNote('target-note');

      expect(plan, isNotNull);
      expect(plan!.id, 'plan-1');
    });

    test('findPlanForNote returns null when not found', () async {
      when(
        () => mockDatabase.query(
          'reading_plans',
          orderBy: any(named: 'orderBy'),
        ),
      ).thenAnswer((_) async => []);

      final plan = await service.findPlanForNote('nonexistent');

      expect(plan, isNull);
    });
  });
}
