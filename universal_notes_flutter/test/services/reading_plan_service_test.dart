@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/services/reading_plan_service.dart';

void main() {
  late Database database;
  late ReadingPlanService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await ReadingPlanService.createTable(db);
      },
    );
    service = ReadingPlanService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('ReadingPlanService', () {
    test('createTable should create the table', () async {
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND "
        "name='reading_plans'",
      );
      expect(tables, isNotEmpty);
    });

    test('createPlan should insert a plan', () async {
      final plan = await service.createPlan(
        title: 'Test Plan',
        noteIds: ['note1', 'note2'],
      );

      expect(plan.id, isNotEmpty);
      expect(plan.title, 'Test Plan');
      expect(plan.noteIds, ['note1', 'note2']);
      expect(plan.currentIndex, 0);
    });

    test('getAllPlans should return all plans', () async {
      await service.createPlan(title: 'Plan 1', noteIds: ['n1']);
      await service.createPlan(title: 'Plan 2', noteIds: ['n2']);

      final plans = await service.getAllPlans();
      expect(plans.length, 2);
    });

    test('getPlan should return a plan by id', () async {
      final created = await service.createPlan(
        title: 'Plan X',
        noteIds: ['nx'],
      );
      final retrieved = await service.getPlan(created.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Plan X');
    });

    test('updatePlan should modify an existing plan', () async {
      final plan = await service.createPlan(
        title: 'Old Title',
        noteIds: ['n1'],
      );
      final updated = plan.copyWith(title: 'New Title', currentIndex: 1);

      await service.updatePlan(updated);
      final retrieved = await service.getPlan(plan.id);

      expect(retrieved!.title, 'New Title');
      expect(retrieved.currentIndex, 1);
    });

    test('deletePlan should remove a plan', () async {
      final plan = await service.createPlan(
        title: 'To Delete',
        noteIds: ['n1'],
      );
      await service.deletePlan(plan.id);

      final retrieved = await service.getPlan(plan.id);
      expect(retrieved, isNull);
    });
  });
}
