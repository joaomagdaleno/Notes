import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

void main() {
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

      expect(db, isA<Database>()); // _initDB succeeded → lines 34-35 were hit
      await db.close();
    });
  });
}
