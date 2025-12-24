@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/reading_bookmark.dart';

void main() {
  group('ReadingBookmark', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    test('creates with required parameters', () {
      final bookmark = ReadingBookmark(
        id: 'bm-1',
        noteId: 'note-123',
        position: 500,
        createdAt: testDate,
      );

      expect(bookmark.id, 'bm-1');
      expect(bookmark.noteId, 'note-123');
      expect(bookmark.position, 500);
      expect(bookmark.createdAt, testDate);
      expect(bookmark.name, isNull);
      expect(bookmark.excerpt, isNull);
    });

    test('creates with optional parameters', () {
      final bookmark = ReadingBookmark(
        id: 'bm-2',
        noteId: 'note-456',
        position: 1000,
        createdAt: testDate,
        name: 'Chapter 5',
        excerpt: 'The quick brown fox...',
      );

      expect(bookmark.name, 'Chapter 5');
      expect(bookmark.excerpt, 'The quick brown fox...');
    });

    group('JSON serialization', () {
      test('toJson converts to map', () {
        final bookmark = ReadingBookmark(
          id: 'bm-1',
          noteId: 'note-123',
          position: 500,
          createdAt: testDate,
          name: 'Test',
          excerpt: 'Sample text',
        );

        final json = bookmark.toJson();

        expect(json['id'], 'bm-1');
        expect(json['noteId'], 'note-123');
        expect(json['position'], 500);
        expect(json['createdAt'], testDate.toIso8601String());
        expect(json['name'], 'Test');
        expect(json['excerpt'], 'Sample text');
      });

      test('fromJson creates from map', () {
        final json = {
          'id': 'bm-3',
          'noteId': 'note-789',
          'position': 750,
          'createdAt': testDate.toIso8601String(),
          'name': 'Intro',
          'excerpt': 'Beginning...',
        };

        final bookmark = ReadingBookmark.fromJson(json);

        expect(bookmark.id, 'bm-3');
        expect(bookmark.noteId, 'note-789');
        expect(bookmark.position, 750);
        expect(bookmark.createdAt, testDate);
        expect(bookmark.name, 'Intro');
        expect(bookmark.excerpt, 'Beginning...');
      });

      test('fromJson handles null optional fields', () {
        final json = {
          'id': 'bm-4',
          'noteId': 'note-999',
          'position': 100,
          'createdAt': testDate.toIso8601String(),
          'name': null,
          'excerpt': null,
        };

        final bookmark = ReadingBookmark.fromJson(json);

        expect(bookmark.name, isNull);
        expect(bookmark.excerpt, isNull);
      });

      test('roundtrip serialization', () {
        final original = ReadingBookmark(
          id: 'bm-rt',
          noteId: 'note-rt',
          position: 999,
          createdAt: testDate,
          name: 'Roundtrip',
          excerpt: 'Test excerpt',
        );

        final json = original.toJson();
        final restored = ReadingBookmark.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = ReadingBookmark(
          id: 'bm-1',
          noteId: 'note-123',
          position: 500,
          createdAt: testDate,
        );

        final copied = original.copyWith(
          position: 600,
          name: 'New Name',
        );

        expect(copied.id, 'bm-1'); // unchanged
        expect(copied.noteId, 'note-123'); // unchanged
        expect(copied.position, 600); // changed
        expect(copied.name, 'New Name'); // changed
        expect(copied.createdAt, testDate); // unchanged
      });

      test('copies with all new values', () {
        final newDate = DateTime(2024, 2, 20);
        final original = ReadingBookmark(
          id: 'bm-1',
          noteId: 'note-1',
          position: 100,
          createdAt: testDate,
        );

        final copied = original.copyWith(
          id: 'bm-new',
          noteId: 'note-new',
          position: 200,
          createdAt: newDate,
          name: 'Name',
          excerpt: 'Excerpt',
        );

        expect(copied.id, 'bm-new');
        expect(copied.noteId, 'note-new');
        expect(copied.position, 200);
        expect(copied.createdAt, newDate);
        expect(copied.name, 'Name');
        expect(copied.excerpt, 'Excerpt');
      });
    });

    group('equality', () {
      test('equals with same values', () {
        final bookmark1 = ReadingBookmark(
          id: 'bm-1',
          noteId: 'note-1',
          position: 100,
          createdAt: testDate,
          name: 'Test',
          excerpt: 'Sample',
        );

        final bookmark2 = ReadingBookmark(
          id: 'bm-1',
          noteId: 'note-1',
          position: 100,
          createdAt: testDate,
          name: 'Test',
          excerpt: 'Sample',
        );

        expect(bookmark1, equals(bookmark2));
        expect(bookmark1.hashCode, equals(bookmark2.hashCode));
      });

      test('not equals with different values', () {
        final bookmark1 = ReadingBookmark(
          id: 'bm-1',
          noteId: 'note-1',
          position: 100,
          createdAt: testDate,
        );

        final bookmark2 = ReadingBookmark(
          id: 'bm-2',
          noteId: 'note-1',
          position: 100,
          createdAt: testDate,
        );

        expect(bookmark1, isNot(equals(bookmark2)));
      });

      test('equals with identical reference', () {
        final bookmark = ReadingBookmark(
          id: 'bm-1',
          noteId: 'note-1',
          position: 100,
          createdAt: testDate,
        );

        expect(bookmark == bookmark, isTrue);
      });
    });

    test('toString returns descriptive string', () {
      final bookmark = ReadingBookmark(
        id: 'bm-1',
        noteId: 'note-123',
        position: 500,
        createdAt: testDate,
      );

      final str = bookmark.toString();

      expect(str, contains('bm-1'));
      expect(str, contains('note-123'));
      expect(str, contains('500'));
    });
  });
}
