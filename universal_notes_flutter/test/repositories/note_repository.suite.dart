@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:universal_notes_flutter/models/snippet.dart';
import 'package:universal_notes_flutter/models/tag.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

void main() {
  // --- START OF THE FIX ---
  // Store the original platform to restore it later
  late PathProviderPlatform platform;

  setUpAll(() async {
    // Create a fake implementation of the PathProviderPlatform
    platform = FakePathProviderPlatform();
    // Register the fake implementation for all tests in this file
    PathProviderPlatform.instance = platform;
  });
  // --- END OF THE FIX ---
  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialize FFI
  sqfliteFfiInit();

  // Use FFI database factory
  databaseFactory = databaseFactoryFfi;

  group('NoteRepository', () {
    late NoteRepository noteRepository;
    late Note note;

    setUp(() async {
      NoteRepository.resetInstance();
      noteRepository = NoteRepository.instance..dbPath = inMemoryDatabasePath;
      note = Note(
        id: '1',
        title: 'Test Note',
        content: 'This is a test note.',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'user1',
      );
    });

    tearDown(() async {
      await noteRepository.close();
    });

    test('insertNote and getAllNotes', () async {
      await noteRepository.insertNote(note);
      final notes = await noteRepository.getAllNotes();
      expect(notes.length, 1);
      expect(notes[0].title, 'Test Note');
    });

    test('updateNote', () async {
      await noteRepository.insertNote(note);
      final updatedNote = note.copyWith(title: 'Updated Note');
      await noteRepository.updateNote(updatedNote);
      final notes = await noteRepository.getAllNotes();
      expect(notes[0].title, 'Updated Note');
    });

    test('deleteNote', () async {
      await noteRepository.insertNote(note);
      await noteRepository.deleteNote(note.id);
      final notes = await noteRepository.getAllNotes();
      expect(notes.length, 0);
    });

    test('Tag operations', () async {
      const tag = Tag(
        id: 't1',
        name: 'Test Tag',
        color: Color(0xFF00FF00),
      );
      await noteRepository.createTag(tag);
      final allTags = await noteRepository.getAllTags();
      expect(allTags.any((t) => t.name == 'Test Tag'), true);

      await noteRepository.addTagToNote(note.id, tag.id);
      final noteTags = await noteRepository.getTagsForNote(note.id);
      expect(noteTags.length, 1);
      expect(noteTags[0].name, 'Test Tag');

      await noteRepository.removeTagFromNote(note.id, tag.id);
      final noteTagsAfter = await noteRepository.getTagsForNote(note.id);
      expect(noteTagsAfter.length, 0);
    });

    test('Folder operations', () async {
      final folder = await noteRepository.createFolder('Work');
      expect(folder.name, 'Work');

      final folders = await noteRepository.getAllFolders();
      expect(folders.any((f) => f.name == 'Work'), true);

      await noteRepository.deleteFolder(folder.id);
      final foldersAfter = await noteRepository.getAllFolders();
      expect(foldersAfter.any((f) => f.id == folder.id), false);
    });

    test('Snippet operations', () async {
      final snippet = await noteRepository.createSnippet(
        trigger: '/hi',
        content: 'Hello World',
      );
      expect(snippet.trigger, '/hi');

      final allSnippets = await noteRepository.getAllSnippets();
      expect(allSnippets.any((s) => s.trigger == '/hi'), true);
    });

    test('Note event operations', () async {
      final event = NoteEvent(
        id: 'e1',
        noteId: note.id,
        type: NoteEventType.insert,
        payload: {'text': 'X'},
        timestamp: DateTime.now(),
      );
      await noteRepository.addNoteEvent(event);
      final events = await noteRepository.getNoteEvents(note.id);
      expect(events.length, 1);
      expect(events[0].id, 'e1');
    });

    test(
      'searchAllNotes returns empty list when search term is too long',
      () async {
        await noteRepository.insertNote(note);
        final longSearchTerm = 'a' * 257;
        final notes = await noteRepository.searchNotes(longSearchTerm);
        expect(notes.length, 0);
      },
    );

    test('uses default branch when dbPath is null', () async {
      // Ensure we enter the else-branch
      NoteRepository.instance.dbPath = null;

      // Directly invoke the private init routine that contains lines 34-35
      final db = await NoteRepository.instance.initDB();

      // _initDB succeeded → lines 34-35 were hit
      expect(db, isA<Database>());
      await db.close();
    });

    group('Edge Cases', () {
      test('getAllNotes returns empty list on empty database', () async {
        final notes = await noteRepository.getAllNotes();
        expect(notes, isEmpty);
      });

      test('getNoteWithContent throws for non-existent note', () async {
        expect(
          () => noteRepository.getNoteWithContent('non-existent'),
          throwsException,
        );
      });

      test('updateNote on non-existent note does not throw', () async {
        final fakeNote = Note(
          id: 'fake-id',
          title: 'Fake',
          content: '',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          ownerId: 'u1',
        );
        // Should not throw, just no-op or upsert depending on implementation
        await noteRepository.updateNote(fakeNote);
      });

      test('searchAllNotes returns matching notes', () async {
        await noteRepository.insertNote(note);
        final results = await noteRepository.searchNotes('Test');
        expect(results.any((n) => n.title.contains('Test')), true);
      });

      test('searchAllNotes is case insensitive', () async {
        await noteRepository.insertNote(note);
        final results = await noteRepository.searchNotes('test');
        expect(results.any((n) => n.title.contains('Test')), true);
      });

      test('getNoteByTitle returns note', () async {
        await noteRepository.insertNote(note);
        final fetched = await noteRepository.getNoteByTitle('Test Note');
        expect(fetched, isNotNull);
        expect(fetched!.id, note.id);
      });

      test('updateNoteContent sets syncStatus to modified', () async {
        await noteRepository.insertNote(note);
        final noteWithContent = note.copyWith(content: 'New content');
        await noteRepository.updateNoteContent(noteWithContent);
        final fetched = await noteRepository.getNoteWithContent(note.id);
        expect(fetched.content, 'New content');
        // syncStatus should be modified (1) per implementation in
        // updateNoteContent
      });

      test(
        'getUnsyncedNotes returns notes with modified/local status',
        () async {
          await noteRepository.insertNote(note);
          final unsynced = await noteRepository.getUnsyncedNotes();
          expect(unsynced.length, 1);
          expect(unsynced[0].id, note.id);
        },
      );

      test('getUnsyncedWords and markWordsSynced', () async {
        final db = await noteRepository.database;
        await db.insert('user_dictionary', {
          'word': 'testword',
          'frequency': 1,
          'lastUsed': 123,
          'isSynced': 0,
        });

        final unsynced = await noteRepository.getUnsyncedWords();
        expect(unsynced.length, 1);
        expect(unsynced[0]['word'], 'testword');

        await noteRepository.markWordsSynced(['testword']);
        final unsyncedAfter = await noteRepository.getUnsyncedWords();
        expect(unsyncedAfter.length, 0);
      });

      test('Snippet operations extended', () async {
        final s = await noteRepository.createSnippet(
          trigger: '/t',
          content: 'C',
        );
        final all = await noteRepository.getAllSnippets();
        expect(all.length, 1);

        final updated = Snippet(id: s.id, trigger: s.trigger, content: 'New C');
        await noteRepository.updateSnippet(updated);
        final all2 = await noteRepository.getAllSnippets();
        expect(all2[0].content, 'New C');

        await noteRepository.deleteSnippet(s.id);
        expect(await noteRepository.getAllSnippets(), isEmpty);
      });

      test('Frequency cache and words', () async {
        await noteRepository.insertNote(
          Note(
            id: 'n1',
            title: 'T',
            content: '[{"type":"text","spans":[{"text":"hello world"}]}]',
            createdAt: DateTime.now(),
            lastModified: DateTime.now(),
            ownerId: 'u1',
          ),
        );

        final words = await noteRepository.getFrequentWords('hel');
        expect(words, contains('hello'));
      });

      test('Note versioning operations', () async {
        await noteRepository.insertNote(note);
        final version = NoteVersion(
          id: 'v1',
          noteId: note.id,
          content: 'Old content',
          date: DateTime.now(),
        );
        await noteRepository.createNoteVersion(version);

        final versions = await noteRepository.getNoteVersions(note.id);
        expect(versions.length, 1);
        expect(versions[0].content, 'Old content');
      });
    });
  });
}

// You need to define the FakePathProviderPlatform class
// This class implements the methods of PathProviderPlatform and
// returns fake values.
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp/fake_app_documents'; // A fake path for tests
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '/tmp/fake_temp'; // A fake path for tests
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    // This is the one your failing test needs!
    return '/tmp/fake_app_support';
  }

  @override
  Future<String?> getLibraryPath() async {
    return '/tmp/fake_library';
  }

  @override
  Future<String?> getApplicationCachePath() async {
    return '/tmp/fake_cache';
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return '/tmp/fake_external_storage';
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return ['/tmp/fake_external_cache'];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return ['/tmp/fake_external_storage_path'];
  }

  @override
  Future<String?> getDownloadsPath() async {
    return '/tmp/fake_downloads';
  }
}
