@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/services/reading_bookmarks_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late ReadingBookmarksService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await ReadingBookmarksService.createTable(db);
      },
    );
    service = ReadingBookmarksService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('ReadingBookmarksService', () {
    group('createTable', () {
      test('creates bookmarks table', () async {
        final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND "
          "name='reading_bookmarks'",
        );
        expect(tables, isNotEmpty);
      });

      test('creates noteId index', () async {
        final indexes = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND "
          "name='idx_bookmarks_noteId'",
        );
        expect(indexes, isNotEmpty);
      });
    });

    group('addBookmark', () {
      test('adds bookmark with required fields', () async {
        final bookmark = await service.addBookmark(
          noteId: 'note-1',
          position: 100,
        );

        expect(bookmark.id, isNotEmpty);
        expect(bookmark.noteId, 'note-1');
        expect(bookmark.position, 100);
        expect(bookmark.createdAt, isNotNull);
      });

      test('adds bookmark with optional fields', () async {
        final bookmark = await service.addBookmark(
          noteId: 'note-2',
          position: 200,
          name: 'Chapter 1',
          excerpt: 'In the beginning...',
        );

        expect(bookmark.name, 'Chapter 1');
        expect(bookmark.excerpt, 'In the beginning...');
      });
    });

    group('getBookmarksForNote', () {
      test('returns empty list for note without bookmarks', () async {
        final bookmarks = await service.getBookmarksForNote('empty-note');

        expect(bookmarks, isEmpty);
      });

      test('returns all bookmarks for note', () async {
        await service.addBookmark(noteId: 'note-1', position: 100);
        await service.addBookmark(noteId: 'note-1', position: 200);
        await service.addBookmark(noteId: 'note-2', position: 300);

        final bookmarks = await service.getBookmarksForNote('note-1');

        expect(bookmarks.length, 2);
        expect(bookmarks.every((b) => b.noteId == 'note-1'), true);
      });

      test('returns bookmarks ordered by position', () async {
        await service.addBookmark(noteId: 'note-1', position: 300);
        await service.addBookmark(noteId: 'note-1', position: 100);
        await service.addBookmark(noteId: 'note-1', position: 200);

        final bookmarks = await service.getBookmarksForNote('note-1');

        expect(bookmarks[0].position, 100);
        expect(bookmarks[1].position, 200);
        expect(bookmarks[2].position, 300);
      });
    });

    group('getBookmark', () {
      test('returns bookmark by id', () async {
        final added = await service.addBookmark(
          noteId: 'note-1',
          position: 100,
          name: 'Test',
        );

        final retrieved = await service.getBookmark(added.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, added.id);
        expect(retrieved.name, 'Test');
      });

      test('returns null for non-existent id', () async {
        final retrieved = await service.getBookmark('non-existent');

        expect(retrieved, isNull);
      });
    });

    group('updateBookmark', () {
      test('updates bookmark fields', () async {
        final original = await service.addBookmark(
          noteId: 'note-1',
          position: 100,
        );

        final updated = original.copyWith(
          position: 150,
          name: 'Updated Name',
        );
        await service.updateBookmark(updated);

        final retrieved = await service.getBookmark(original.id);
        expect(retrieved!.position, 150);
        expect(retrieved.name, 'Updated Name');
      });
    });

    group('deleteBookmark', () {
      test('deletes bookmark by id', () async {
        final bookmark = await service.addBookmark(
          noteId: 'note-1',
          position: 100,
        );

        await service.deleteBookmark(bookmark.id);

        final retrieved = await service.getBookmark(bookmark.id);
        expect(retrieved, isNull);
      });
    });

    group('deleteBookmarksForNote', () {
      test('deletes all bookmarks for note', () async {
        await service.addBookmark(noteId: 'note-1', position: 100);
        await service.addBookmark(noteId: 'note-1', position: 200);
        await service.addBookmark(noteId: 'note-2', position: 300);

        await service.deleteBookmarksForNote('note-1');

        final note1Bookmarks = await service.getBookmarksForNote('note-1');
        final note2Bookmarks = await service.getBookmarksForNote('note-2');

        expect(note1Bookmarks, isEmpty);
        expect(note2Bookmarks.length, 1);
      });
    });

    group('countBookmarksForNote', () {
      test('returns 0 for note without bookmarks', () async {
        final count = await service.countBookmarksForNote('empty-note');

        expect(count, 0);
      });

      test('returns correct count', () async {
        await service.addBookmark(noteId: 'note-1', position: 100);
        await service.addBookmark(noteId: 'note-1', position: 200);

        final count = await service.countBookmarksForNote('note-1');

        expect(count, 2);
      });
    });
  });
}
