import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:uuid/uuid.dart';

/// A repository for managing notes and folders in a local database.
class NoteRepository {
  NoteRepository._();
  static final NoteRepository instance = NoteRepository._();

  String? dbPath;
  Database? _database;

  static const String _dbName = 'notes_database.db';
  static const String _notesTable = 'notes';
  static const String _foldersTable = 'folders';
  static const String _versionsTable = 'note_versions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  @visibleForTesting
  Future<Database> initDB() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final path = join(dir.path, _dbName);
    return openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_foldersTable(
        id TEXT PRIMARY KEY,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_notesTable(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        date INTEGER,
        isFavorite INTEGER,
        isLocked INTEGER,
        isInTrash INTEGER,
        isDeleted INTEGER,
        drawingJson TEXT,
        prefsJson TEXT,
        folderId TEXT,
        FOREIGN KEY (folderId) REFERENCES $_foldersTable(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_versionsTable(
        id TEXT PRIMARY KEY,
        noteId TEXT,
        content TEXT,
        date INTEGER,
        FOREIGN KEY (noteId) REFERENCES $_notesTable(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_foldersTable(
          id TEXT PRIMARY KEY,
          name TEXT
        )
      ''');
      await db.execute('ALTER TABLE $_notesTable ADD COLUMN folderId TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $_versionsTable(
          id TEXT PRIMARY KEY,
          noteId TEXT,
          content TEXT,
          date INTEGER,
          FOREIGN KEY (noteId) REFERENCES $_notesTable(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // --- Versioning Methods ---
  Future<void> createNoteVersion(NoteVersion version) async {
    final db = await database;
    await db.insert(_versionsTable, version.toMap());
  }

  Future<List<NoteVersion>> getNoteVersions(String noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _versionsTable,
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => NoteVersion.fromMap(maps[i]));
  }

  // --- Folder Methods ---
  Future<Folder> createFolder(String name) async {
    final db = await database;
    final folder = Folder(id: const Uuid().v4(), name: name);
    await db.insert(_foldersTable, folder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return folder;
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_foldersTable);
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  Future<void> updateFolder(Folder folder) async {
    final db = await database;
    await db.update(_foldersTable, folder.toMap(), where: 'id = ?', whereArgs: [folder.id]);
  }

  Future<void> deleteFolder(String id) async {
    final db = await database;
    await db.delete(_foldersTable, where: 'id = ?', whereArgs: [id]);
  }

  // --- Note Methods ---
  Future<String> insertNote(Note note) async {
    final db = await database;
    await db.insert(_notesTable, note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return note.id;
  }

  Future<List<Note>> getAllNotes({String? folderId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _notesTable,
      where: folderId == null ? null : 'folderId = ?',
      whereArgs: folderId == null ? null : [folderId],
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(_notesTable, note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(_notesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
