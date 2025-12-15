import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';

void main() {
  group('Note', () {
    test('Note can be created', () {
      final note = Note(
        id: '1',
        title: 'Test Note',
        content: 'This is a test note.',
        date: DateTime.now(),
      );
      expect(note, isNotNull);
    });

    test('Note can be created from map', () {
      final note = Note.fromMap({
        'id': '1',
        'title': 'Test Note',
        'content': 'This is a test note.',
        'date': DateTime.now().millisecondsSinceEpoch,
        'isFavorite': 1,
        'isLocked': 0,
        'isInTrash': 1,
      });
      expect(note, isNotNull);
    });

    test('Note can be converted to map', () {
      final note = Note(
        id: '1',
        title: 'Test Note',
        content: 'This is a test note.',
        date: DateTime.now(),
      );
      expect(note.toMap(), isNotNull);
    });

    test('Note can be copied', () {
      final note = Note(
        id: '1',
        title: 'Test Note',
        content: 'This is a test note.',
        date: DateTime.now(),
      );
      final copiedNote = note.copyWith(title: 'Copied Note');
      expect(copiedNote.title, 'Copied Note');
    });
  });
}
