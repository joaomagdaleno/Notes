import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:universal_notes_flutter/models/snippet.dart';
import 'package:uuid/uuid.dart';

/// A repository for managing all app data in a local database.
class NoteRepository {
  NoteRepository._();
  static final NoteRepository instance = NoteRepository._();

  String? dbPath;
  Database? _database;

  static const String _dbName = 'notes_database.db';
  static const String _notesTable = 'notes';
  static const String _foldersTable = 'folders';
  static const String _versionsTable = 'note_versions';
  static const String _snippetsTable = 'snippets';

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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_foldersTable(id TEXT PRIMARY KEY, name TEXT)
    ''');
    await db.execute('''
      CREATE TABLE $_notesTable(
        id TEXT PRIMARY KEY, title TEXT, content TEXT, date INTEGER,
        isFavorite INTEGER, isLocked INTEGER, isInTrash INTEGER, isDeleted INTEGER,
        drawingJson TEXT, prefsJson TEXT, folderId TEXT,
        FOREIGN KEY (folderId) REFERENCES $_foldersTable(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_versionsTable(
        id TEXT PRIMARY KEY, noteId TEXT, content TEXT, date INTEGER,
        FOREIGN KEY (noteId) REFERENCES $_notesTable(id) ON DELETE CASCADE
      )
    ''');
     await db.execute('''
      CREATE TABLE $_snippetsTable(
        id TEXT PRIMARY KEY,
        trigger TEXT UNIQUE,
        content TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE $_foldersTable(id TEXT PRIMARY KEY, name TEXT)');
      await db.execute('ALTER TABLE $_notesTable ADD COLUMN folderId TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $_versionsTable(
          id TEXT PRIMARY KEY, noteId TEXT, content TEXT, date INTEGER,
          FOREIGN KEY (noteId) REFERENCES $_notesTable(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE $_snippetsTable(
          id TEXT PRIMARY KEY,
          trigger TEXT UNIQUE,
          content TEXT
        )
      ''');
    }
  }

  // --- Snippet Methods ---
  Future<Snippet> createSnippet({required String trigger, required String content}) async {
    final db = await database;
    final snippet = Snippet(id: const Uuid().v4(), trigger: trigger, content: content);
    await db.insert(_snippetsTable, snippet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return snippet;
  }

  Future<List<Snippet>> getAllSnippets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_snippetsTable, orderBy: 'trigger');
    return List.generate(maps.length, (i) => Snippet.fromMap(maps[i]));
  }

  Future<void> updateSnippet(Snippet snippet) async {
    final db = await database;
    await db.update(_snippetsTable, snippet.toMap(), where: 'id = ?', whereArgs: [snippet.id]);
  }

  Future<void> deleteSnippet(String id) async {
    final db = await database;
    await db.delete(_snippetsTable, where: 'id = ?', whereArgs: [id]);
  }

  // --- Autocomplete Methods ---
  Future<List<String>> getFrequentWords(String prefix) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_notesTable, columns: ['content']);
    final wordCounts = <String, int>{};

    for (final map in maps) {
      final content = map['content'] as String;
      // This assumes content is the JSON from our editor. A safer parsing is needed.
      try {
        final List<dynamic> spans = json.decode(content);
        for (final span in spans) {
          final text = span['text'] as String;
          final words = text.split(RegExp(r'\s+'));
          for (final word in words) {
            final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
            if (cleanWord.isNotEmpty) {
              wordCounts[cleanWord] = (wordCounts[cleanWord] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        // Ignore content that isn't valid JSON
      }
    }

    final matchingWords = wordCounts.keys
        .where((word) => word.startsWith(prefix.toLowerCase()))
        .toList();

    matchingWords.sort((a, b) => wordCounts[b]!.compareTo(wordCounts[a]!));

    return matchingWords;
  }

  // --- Versioning Methods ---
  Future<void> createNoteVersion(NoteVersion version) async {
    final db = await database;
    await db.insert(_versionsTable, version.toMap());
  }

  Future<List<NoteVersion>> getNoteVersions(String noteId) async {
    final db = await database;
    final maps = await db.query(_versionsTable, where: 'noteId = ?', whereArgs: [noteId], orderBy: 'date DESC');
    return List.generate(maps.length, (i) => NoteVersion.fromMap(maps[i]));
  }

  // --- Folder Methods ---
  Future<Folder> createFolder(String name) async {
    final db = await database;
    final folder = Folder(id: const Uuid().v4(), name: name);
    await db.insert(_foldersTable, folder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return folder;
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query(_foldersTable);
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
    await db.insert(_notesTable, note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return note.id;
  }

  Future<List<Note>> getAllNotes({String? folderId}) async {
    final db = await database;
    final maps = await db.query(_notesTable, where: folderId == null ? null : 'folderId = ?', whereArgs: folderId == null ? null : [folderId]);
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
