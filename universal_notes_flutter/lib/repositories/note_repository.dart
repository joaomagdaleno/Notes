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
  Map<String, int>? _wordFrequencyCache;

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
      version: 5,
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
        isFavorite INTEGER, isLocked INTEGER, isInTrash INTEGER, isDeleted INTEGER, isDraft INTEGER,
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
     if (oldVersion < 5) {
      await db.execute('ALTER TABLE $_notesTable ADD COLUMN isDraft INTEGER DEFAULT 0');
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
  Future<void> _buildWordFrequencyCache() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_notesTable, columns: ['content']);
    _wordFrequencyCache = <String, int>{};

    for (final map in maps) {
      final content = map['content'] as String;
      try {
        final List<dynamic> spans = json.decode(content);
        for (final span in spans) {
          if (span is Map<String, dynamic> && span['text'] is String) {
            final text = span['text'] as String;
            final words = text.split(RegExp(r'\s+'));
            for (final word in words) {
              final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
              if (cleanWord.isNotEmpty) {
                _wordFrequencyCache![cleanWord] = (_wordFrequencyCache![cleanWord] ?? 0) + 1;
              }
            }
          }
        }
      } catch (e) {
        // Ignore content that isn't valid JSON
      }
    }
  }

  Future<List<String>> getFrequentWords(String prefix) async {
    if (_wordFrequencyCache == null) {
      await _buildWordFrequencyCache();
    }

    final matchingWords = _wordFrequencyCache!.keys
        .where((word) => word.startsWith(prefix.toLowerCase()))
        .toList();

    matchingWords.sort((a, b) => _wordFrequencyCache![b]!.compareTo(_wordFrequencyCache![a]!));

    return matchingWords.take(10).toList(); // Limit to top 10 for performance
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
    _wordFrequencyCache = null;
    return note.id;
  }

  Future<List<Note>> getAllNotes({
    String? folderId,
    bool? isFavorite,
    bool? isInTrash,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (isInTrash == true) {
      whereClauses.add('isInTrash = ?');
      whereArgs.add(1);
    } else {
      whereClauses.add('isInTrash = ?');
      whereArgs.add(0);
    }

    if (folderId != null) {
      whereClauses.add('folderId = ?');
      whereArgs.add(folderId);
    }

    if (isFavorite == true) {
      whereClauses.add('isFavorite = ?');
      whereArgs.add(1);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final columnsToFetch = Note.fromMap({}).toMap().keys.where((key) => key != 'content').toList();

    final maps = await db.query(
      _notesTable,
      columns: columnsToFetch,
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<List<Note>> searchAllNotes(String searchTerm) async {
    final db = await database;
    if (searchTerm.isEmpty) {
      return getAllNotes();
    }
    final columnsToFetch = Note.fromMap({}).toMap().keys.where((key) => key != 'content').toList();
    final maps = await db.query(
      _notesTable,
      columns: columnsToFetch,
      where: '(title LIKE ? OR content LIKE ?) AND isInTrash = 0',
      whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<Note> getNoteWithContent(String noteId) async {
    final db = await database;
    final maps = await db.query(
      _notesTable,
      where: 'id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    throw Exception('Note not found');
  }

  Future<void> updateNoteContent(Note note) async {
    final db = await database;
    await db.update(_notesTable, note.toMap(), where: 'id = ?', whereArgs: [note.id]);
    _wordFrequencyCache = null;
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(_notesTable, note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(_notesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteNotePermanently(String id) async {
    final db = await database;
    await db.delete(_notesTable, where: 'id = ?', whereArgs: [id]);
    _wordFrequencyCache = null; // Invalidate cache on deletion
  }

  Future<void> restoreNoteFromTrash(String id) async {
    final db = await database;
    await db.update(_notesTable, {'isInTrash': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
