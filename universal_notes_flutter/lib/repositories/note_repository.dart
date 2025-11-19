import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// A repository for managing notes in a local database.
class NoteRepository {
  /// Creates a new instance of [NoteRepository].
  NoteRepository._();

  /// The shared instance of the [NoteRepository].
  static final NoteRepository instance = NoteRepository._();

  /// The path to the database. If null, the default path is used.
  String? dbPath;

  static const String _dbName = 'notes_database.db';
  static const String _tableName = 'notes';
  Database? _database;

  /// Returns the database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path;
    if (dbPath != null) {
      path = dbPath!;
    } else {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      path = join(dir.path, _dbName);
    }
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        date INTEGER,
        isFavorite INTEGER,
        isLocked INTEGER,
        isInTrash INTEGER,
        drawingJson TEXT,
        prefsJson TEXT
      )
    ''');
  }

  /// Inserts a note into the database.
  Future<String> insertNote(Note note) async {
    final db = await database;
    await db.insert(
      _tableName,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return note.id;
  }

  /// Returns all notes from the database.
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  /// Updates a note in the database.
  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      _tableName,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Deletes a note from the database.
  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Closes the database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
