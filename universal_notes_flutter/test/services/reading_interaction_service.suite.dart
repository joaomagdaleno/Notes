@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/services/reading_interaction_service.dart';

import 'reading_interaction_service_test.mocks.dart';

@GenerateMocks([Database])
void main() {
  late ReadingInteractionService service;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockDatabase();
    service = ReadingInteractionService(database: mockDatabase);
  });

  group('ReadingInteractionService', () {
    test('getAnnotationsForNote returns list of annotations', () async {
      final mockData = [
        {
          'id': '1',
          'noteId': 'note1',
          'startOffset': 10,
          'endOffset': 20,
          'createdAt': DateTime.now().toIso8601String(),
          'color': 0xFFFF0000,
          'textExcerpt': 'hello',
        },
      ];

      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => mockData);

      final result = await service.getAnnotationsForNote('note1');

      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.textExcerpt, 'hello');
    });

    test('addHighlight inserts and returns annotation', () async {
      when(mockDatabase.insert(any, any)).thenAnswer((_) async => 1);

      final result = await service.addHighlight(
        noteId: 'note1',
        startOffset: 10,
        endOffset: 20,
        color: 0xFFFF0000,
        textExcerpt: 'test',
      );

      expect(result.noteId, 'note1');
      expect(result.startOffset, 10);
      expect(result.color, 0xFFFF0000);
      verify(mockDatabase.insert('reading_annotations', any)).called(1);
    });

    test('addNote inserts and returns annotation', () async {
      when(mockDatabase.insert(any, any)).thenAnswer((_) async => 1);

      final result = await service.addNote(
        noteId: 'note1',
        offset: 50,
        comment: 'nice',
      );

      expect(result.noteId, 'note1');
      expect(result.comment, 'nice');
      expect(result.startOffset, 50);
      verify(mockDatabase.insert('reading_annotations', any)).called(1);
    });

    test('deleteAnnotation calls database delete', () async {
      when(
        mockDatabase.delete(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => 1);

      await service.deleteAnnotation('1');

      verify(
        mockDatabase.delete(
          'reading_annotations',
          where: 'id = ?',
          whereArgs: ['1'],
        ),
      ).called(1);
    });
  });
}
