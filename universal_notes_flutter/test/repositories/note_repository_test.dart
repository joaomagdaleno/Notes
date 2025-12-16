import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/models/note.dart';
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

    setUp(() {
      noteRepository = NoteRepository.instance..dbPath = inMemoryDatabasePath;
      note = Note(
        id: '1',
        title: 'Test Note',
        content: 'This is a test note.',
        date: DateTime.now(),
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

    test('uses default branch when dbPath is null', () async {
      // Ensure we enter the else-branch
      NoteRepository.instance.dbPath = null;

      // Directly invoke the private init routine that contains lines 34-35
      final db = await NoteRepository.instance.initDB();

      // _initDB succeeded → lines 34-35 were hit
      expect(db, isA<Database>());
      await db.close();
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
