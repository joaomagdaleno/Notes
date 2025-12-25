@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/reading_plan_model.dart';

void main() {
  group('ReadingPlan', () {
    test('toMap and fromMap should be symmetrical', () {
      final plan = ReadingPlan(
        id: 'plan-123',
        title: 'My Reading Plan',
        noteIds: ['note1', 'note2', 'note3'],
        currentIndex: 1,
        createdAt: DateTime.now(),
      );

      final map = plan.toMap();
      final fromMap = ReadingPlan.fromMap(map);

      expect(fromMap.id, plan.id);
      expect(fromMap.title, plan.title);
      expect(fromMap.noteIds, plan.noteIds);
      expect(fromMap.currentIndex, plan.currentIndex);
      // Compare dates as ISO strings to avoid microsecond precision issues in some environments
      expect(
        fromMap.createdAt.toIso8601String(),
        plan.createdAt.toIso8601String(),
      );
    });

    test('copyWith should work correctly', () {
      final plan = ReadingPlan(
        id: 'plan-123',
        title: 'My Reading Plan',
        noteIds: ['note1'],
        createdAt: DateTime.now(),
      );

      final updated = plan.copyWith(
        title: 'New Title',
        currentIndex: 1,
      );

      expect(updated.id, plan.id);
      expect(updated.title, 'New Title');
      expect(updated.currentIndex, 1);
      expect(updated.noteIds, plan.noteIds);
    });

    test('noteIds string conversion should handle comma separation', () {
      final plan = ReadingPlan(
        id: 'id',
        title: 'title',
        noteIds: ['a', 'b', 'c'],
        createdAt: DateTime.now(),
      );

      final map = plan.toMap();
      expect(map['noteIds'], 'a,b,c');

      final fromMap = ReadingPlan.fromMap(map);
      expect(fromMap.noteIds, ['a', 'b', 'c']);
    });
  });
}
