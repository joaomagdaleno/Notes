import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:universal_notes_flutter/models/snippet.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';
import 'package:universal_notes_flutter/models/tag.dart';
import 'package:universal_notes_flutter/services/firebase_service.dart';
import 'package:universal_notes_flutter/services/reading_bookmarks_service.dart';
import 'package:universal_notes_flutter/services/reading_interaction_service.dart';
import 'package:universal_notes_flutter/services/reading_plan_service.dart';
import 'package:universal_notes_flutter/services/reading_stats_service.dart';
import 'package:uuid/uuid.dart';

/// A repository for managing all app data in a local database.
class NoteRepository {
  NoteRepository._();

  /// The singleton instance of [NoteRepository].
  static NoteRepository instance = NoteRepository._();

  @visibleForTesting
  FirebaseService firebaseService = FirebaseService();

  /// The path to the database file.
  String? dbPath;
  Database? _database;
  Map<String, int>? _wordFrequencyCache;

  late final ReadingBookmarksService bookmarksService;
  late final ReadingInteractionService readingInteractionService;
  late final ReadingStatsService readingStatsService;
  late final ReadingPlanService readingPlanService;

  static const String _dbName = 'notes_database.db';
  static const String _notesTable = 'notes';
  static const String _foldersTable = 'folders';
  static const String _versionsTable = 'note_versions';
  static const String _snippetsTable = 'snippets';
  static const String _tagsTable = 'tags';
  static const String _noteTagsTable = 'note_tags';
  static const String _noteEventsTable = 'note_events';
  static const String _notesFtsTable = 'notes_fts';
  static const String _userDictionaryTable = 'user_dictionary';
  static const String _readingAnnotationsTable = 'reading_annotations';
  static const String _readingStatsTable = 'reading_stats';

  /// Returns the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  /// Initializes the database.
  @visibleForTesting
  Future<Database> initDB() async {
    final String path;
    if (dbPath != null) {
      path = dbPath!;
    } else {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      path = join(dir.path, _dbName);
    }
    _database = await openDatabase(
      path,
      version: 15,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    bookmarksService = ReadingBookmarksService(database: _database!);
    readingInteractionService = ReadingInteractionService(database: _database!);
    readingStatsService = ReadingStatsService(database: _database!);
    readingPlanService = ReadingPlanService(database: _database!);
    return _database!;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_foldersTable(
        id TEXT PRIMARY KEY, name TEXT, isSmart INTEGER DEFAULT 0, query TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_notesTable(
        id TEXT PRIMARY KEY, title TEXT, content TEXT, date INTEGER,
        isFavorite INTEGER, isLocked INTEGER, isInTrash INTEGER, isDeleted INTEGER, isDraft INTEGER,
        drawingJson TEXT, prefsJson TEXT, folderId TEXT, syncStatus INTEGER DEFAULT 2,
        thumbnail BLOB,
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
    await db.execute('''
      CREATE TABLE $_tagsTable(
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE,
        color INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE $_noteTagsTable(
        note_id TEXT,
        tag_id TEXT,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id) REFERENCES $_notesTable(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES $_tagsTable(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE $_noteEventsTable(
        id TEXT PRIMARY KEY,
        noteId TEXT,
        type TEXT,
        payload TEXT,
        timestamp INTEGER,
        syncStatus TEXT,
        deviceId TEXT,
        FOREIGN KEY (noteId) REFERENCES $_notesTable(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE $_userDictionaryTable(
        word TEXT PRIMARY KEY,
        frequency INTEGER DEFAULT 1,
        lastUsed INTEGER,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // FTS5 Virtual Table for full-text search
    await _createFtsTable(db);

    // Reading Bookmarks
    await ReadingBookmarksService.createTable(db);
    await ReadingPlanService.createTable(db);

    await _createReadingTables(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'CREATE TABLE $_foldersTable(id TEXT PRIMARY KEY, name TEXT)',
      );
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
      await db.execute(
        'ALTER TABLE $_notesTable ADD COLUMN isDraft INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE $_tagsTable(
          id TEXT PRIMARY KEY,
          name TEXT UNIQUE,
          color INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE $_noteTagsTable(
          note_id TEXT,
          tag_id TEXT,
          PRIMARY KEY (note_id, tag_id),
          FOREIGN KEY (note_id) REFERENCES $_notesTable(id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES $_tagsTable(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE $_noteEventsTable(
          id TEXT PRIMARY KEY,
          noteId TEXT,
          type TEXT,
          payload TEXT,
          timestamp INTEGER,
          FOREIGN KEY (noteId) REFERENCES $_notesTable(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 8) {
      await _createFtsTable(db);
      // Populate FTS with existing notes
      await _rebuildFtsIndex(db);
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_userDictionaryTable(
          word TEXT PRIMARY KEY,
          frequency INTEGER DEFAULT 1,
          lastUsed INTEGER,
          isSynced INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE $_notesTable ADD COLUMN syncStatus INTEGER DEFAULT 2',
      );
    }
    if (oldVersion < 11) {
      await db.execute(
        'ALTER TABLE $_foldersTable ADD COLUMN isSmart INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE $_foldersTable ADD COLUMN query TEXT');
      await db.execute('ALTER TABLE $_notesTable ADD COLUMN thumbnail BLOB');
    }
    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE $_noteEventsTable ADD COLUMN syncStatus TEXT',
      );
      await db.execute(
        'ALTER TABLE $_noteEventsTable ADD COLUMN deviceId TEXT',
      );
    }
    if (oldVersion < 13) {
      await ReadingBookmarksService.createTable(db);
    }
    if (oldVersion < 14) {
      await _createReadingTables(db);
    }
    if (oldVersion < 15) {
      await ReadingPlanService.createTable(db);
    }
  }

  /// Creates the FTS5 virtual table for full-text search.
  Future<void> _createFtsTable(Database db) async {
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS $_notesFtsTable USING fts5(
        title,
        content,
        content=$_notesTable,
        content_rowid=rowid
      )
    ''');

    // Triggers to keep FTS in sync with notes table
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON $_notesTable BEGIN
        INSERT INTO $_notesFtsTable(rowid, title, content)
        VALUES (new.rowid, new.title, new.content);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON $_notesTable BEGIN
        INSERT INTO $_notesFtsTable($_notesFtsTable, rowid, title, content)
        VALUES ('delete', old.rowid, old.title, old.content);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON $_notesTable BEGIN
        INSERT INTO $_notesFtsTable($_notesFtsTable, rowid, title, content)
        VALUES ('delete', old.rowid, old.title, old.content);
        INSERT INTO $_notesFtsTable(rowid, title, content)
        VALUES (new.rowid, new.title, new.content);
      END
    ''');
  }

  Future<void> _createReadingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_readingAnnotationsTable (
        id TEXT PRIMARY KEY,
        noteId TEXT NOT NULL,
        startOffset INTEGER NOT NULL,
        endOffset INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        color INTEGER,
        comment TEXT,
        textExcerpt TEXT
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_annotations_noteId ON $_readingAnnotationsTable (noteId)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_readingStatsTable (
        noteId TEXT PRIMARY KEY,
        totalReadingTimeSeconds INTEGER DEFAULT 0,
        lastReadPosition INTEGER DEFAULT 0,
        readingGoalMinutes INTEGER DEFAULT 0,
        lastOpenedAt TEXT
      )
    ''');
  }

  /// Rebuilds the FTS index from existing notes.
  Future<void> _rebuildFtsIndex(Database db) async {
    await db.execute(
      'INSERT INTO $_notesFtsTable(rowid, title, content) '
      'SELECT rowid, title, content FROM $_notesTable',
    );
  }

  // --- Tag Methods ---
  /// Creates a new [tag].
  Future<Tag> createTag(Tag tag) async {
    final db = await database;
    await db.insert(
      _tagsTable,
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return tag;
  }

  /// Retrieves all tags.
  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tagsTable);
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }

  /// Updates an existing [tag].
  Future<void> updateTag(Tag tag) async {
    final db = await database;
    await db.update(
      _tagsTable,
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  /// Deletes a tag by [id].
  Future<void> deleteTag(String id) async {
    final db = await database;
    await db.delete(_tagsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Associates a tag with a note.
  Future<void> addTagToNote(String noteId, String tagId) async {
    final db = await database;
    await db.insert(
      _noteTagsTable,
      {'note_id': noteId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Removes a tag from a note.
  Future<void> removeTagFromNote(String noteId, String tagId) async {
    final db = await database;
    await db.delete(
      _noteTagsTable,
      where: 'note_id = ? AND tag_id = ?',
      whereArgs: [noteId, tagId],
    );
  }

  /// Gets all tags for a specific note.
  Future<List<Tag>> getTagsForNote(String noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT T.* FROM $_tagsTable T
      INNER JOIN $_noteTagsTable NT ON T.id = NT.tag_id
      WHERE NT.note_id = ?
    ''',
      [noteId],
    );
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }

  // --- Snippet Methods ---
  /// Creates a new snippet.
  Future<Snippet> createSnippet({
    required String trigger,
    required String content,
  }) async {
    final db = await database;
    final snippet = Snippet(
      id: const Uuid().v4(),
      trigger: trigger,
      content: content,
    );
    await db.insert(
      _snippetsTable,
      snippet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return snippet;
  }

  /// Retrieves all snippets from the database.
  Future<List<Snippet>> getAllSnippets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _snippetsTable,
      orderBy: 'trigger',
    );
    return List.generate(maps.length, (i) => Snippet.fromMap(maps[i]));
  }

  /// Updates an existing snippet.
  Future<void> updateSnippet(Snippet snippet) async {
    final db = await database;
    await db.update(
      _snippetsTable,
      snippet.toMap(),
      where: 'id = ?',
      whereArgs: [snippet.id],
    );
  }

  /// Deletes a snippet by its ID.
  Future<void> deleteSnippet(String id) async {
    final db = await database;
    await db.delete(_snippetsTable, where: 'id = ?', whereArgs: [id]);
  }

  // --- Autocomplete Methods ---
  Future<void> _buildWordFrequencyCache() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _notesTable,
      columns: ['content'],
    );
    _wordFrequencyCache = <String, int>{};

    for (final map in maps) {
      final content = map['content'] as String;
      try {
        final spans = json.decode(content) as List<dynamic>;
        for (final span in spans) {
          if (span is Map<String, dynamic> && span['text'] is String) {
            final text = span['text'] as String;
            final words = text.split(RegExp(r'\s+'));
            for (final word in words) {
              final cleanWord = word
                  .replaceAll(RegExp('[^a-zA-Z]'), '')
                  .toLowerCase();
              if (cleanWord.isNotEmpty) {
                _wordFrequencyCache![cleanWord] =
                    (_wordFrequencyCache![cleanWord] ?? 0) + 1;
              }
            }
          }
        }
      } on FormatException catch (_) {
        // Ignore content that isn't valid JSON
      }
    }
  }

  /// Returns a list of frequently used words starting with [prefix].
  Future<List<String>> getFrequentWords(String prefix) async {
    if (_wordFrequencyCache == null) {
      await _buildWordFrequencyCache();
    }

    final matchingWords = _wordFrequencyCache!.keys
        .where((word) => word.startsWith(prefix.toLowerCase()))
        .toList();

    final cache = _wordFrequencyCache!;
    matchingWords.sort((a, b) {
      return cache[b]!.compareTo(cache[a]!);
    });

    return matchingWords.take(10).toList(); // Limit to top 10 for performance
  }

  // --- Versioning Methods ---
  /// Creates a new version of a note.
  Future<void> createNoteVersion(NoteVersion version) async {
    final db = await database;
    await db.insert(_versionsTable, version.toMap());
  }

  /// Retrieves all versions for a specific note.
  Future<List<NoteVersion>> getNoteVersions(String noteId) async {
    final db = await database;
    final maps = await db.query(
      _versionsTable,
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => NoteVersion.fromMap(maps[i]));
  }

  // --- Folder Methods ---
  /// Creates a new folder with the given [name].
  Future<Folder> createFolder(String name) async {
    final db = await database;
    final folder = Folder(id: const Uuid().v4(), name: name);
    await db.insert(
      _foldersTable,
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return folder;
  }

  /// Inserts a folder with a specific ID (used for backup restore).
  Future<void> insertFolder(Folder folder) async {
    final db = await database;
    await db.insert(
      _foldersTable,
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all folders.
  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query(_foldersTable);
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  /// Updates an existing folder.
  Future<void> updateFolder(Folder folder) async {
    final db = await database;
    await db.update(
      _foldersTable,
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  /// Deletes a folder by its ID.
  Future<void> deleteFolder(String id) async {
    final db = await database;
    await db.delete(_foldersTable, where: 'id = ?', whereArgs: [id]);
  }

  // --- Note Methods ---
  /// Inserts a new note into the database.
  Future<String> insertNote(Note note) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        _notesTable,
        note.copyWith(syncStatus: SyncStatus.local).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _updateTagsForNote(txn, note);
    });
    _wordFrequencyCache = null;
    return note.id;
  }

  /// Retrieves notes, optionally filtering by folder, favorite, or trash
  /// status.
  Future<List<Note>> getAllNotes({
    String? folderId,
    String? tagId,
    bool? isFavorite,
    bool? isInTrash,
  }) async {
    final db = await database;
    var query = 'SELECT DISTINCT N.* FROM $_notesTable N';
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (tagId != null) {
      query +=
          ' INNER JOIN $_noteTagsTable NT ON N.id = NT.note_id '
          'AND NT.tag_id = ?';
      whereArgs.add(tagId);
    }

    if (isInTrash ?? false) {
      whereClauses.add('N.isInTrash = ?');
      whereArgs.add(1);
    } else {
      whereClauses.add('N.isInTrash = ?');
      whereArgs.add(0);
    }

    if (folderId != null) {
      whereClauses.add('N.folderId = ?');
      whereArgs.add(folderId);
    }

    if (isFavorite ?? false) {
      whereClauses.add('N.isFavorite = ?');
      whereArgs.add(1);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY N.date DESC';

    // final columnsToFetch = Note.fromMap(
    //   const {},
    // ).toMap().keys.where((key) => key != 'content').toList();

    final maps = await db.rawQuery(query, whereArgs);
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  /// Searches all notes for the given term.
  Future<List<Note>> searchAllNotes(String searchTerm) async {
    final db = await database;

    // 🛡️ Sentinel: Add input length validation to prevent local DoS attacks
    // from excessively long search terms.
    if (searchTerm.length > 256) {
      return [];
    }

    if (searchTerm.isEmpty) {
      return getAllNotes();
    }
    final columnsToFetch = Note.fromMap(
      const {},
    ).toMap().keys.where((key) => key != 'content').toList();
    final maps = await db.query(
      _notesTable,
      columns: columnsToFetch,
      where: '(title LIKE ? OR content LIKE ?) AND isInTrash = 0',
      whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  /// Retrieves a specific note by ID, including its content.
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

  /// Retrieves a note by its title.
  Future<Note?> getNoteByTitle(String title) async {
    final db = await database;
    final maps = await db.query(
      _notesTable,
      where: 'title = ? AND isInTrash = 0',
      whereArgs: [title],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  /// Updates the content of a note.
  Future<void> updateNoteContent(Note note) async {
    final db = await database;
    await db.update(
      _notesTable,
      note.copyWith(syncStatus: SyncStatus.modified).toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
    _wordFrequencyCache = null;
  }

  /// Updates a note's metadata.
  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        _notesTable,
        note.copyWith(syncStatus: SyncStatus.modified).toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      await _updateTagsForNote(txn, note);
    });
  }

  /// Helper to update relational tag tables.
  Future<void> _updateTagsForNote(Transaction txn, Note note) async {
    // 1. Clear existing tags for this note
    await txn.delete(
      _noteTagsTable,
      where: 'note_id = ?',
      whereArgs: [note.id],
    );

    // 2. Insert new tags
    for (final tag in note.tags) {
      if (tag.isEmpty) continue;

      // Ensure tag definitions exist (using tag name as ID)
      await txn.insert(
        _tagsTable,
        {'id': tag, 'name': tag, 'color': null},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Link tag to note
      await txn.insert(
        _noteTagsTable,
        {'note_id': note.id, 'tag_id': tag},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Retrieves all distinct tag names used in the database.
  Future<List<String>> getAllTagNames() async {
    final db = await database;
    // We fetch from _tagsTable, but maybe only those that are used?
    // Since we lazy-create tags, _tagsTable might have orphans if we remove
    // tags from notes.
    // ideal: join with _noteTagsTable to find used tags.
    // Or just return all known tags. Let's return all known tags to allow
    // reuse.
    final result = await db.query(
      _tagsTable,
      columns: ['name'],
      orderBy: 'name',
    );
    return result.map((row) => row['name']! as String).toList();
  }

  /// Moves a note to the trash (soft delete).
  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(_notesTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Permanently deletes a note from the database.
  Future<void> deleteNotePermanently(String id) async {
    final db = await database;
    await db.delete(_notesTable, where: 'id = ?', whereArgs: [id]);
    _wordFrequencyCache = null; // Invalidate cache on deletion
  }

  /// Restores a note from the trash.
  Future<void> restoreNoteFromTrash(String id) async {
    final db = await database;
    await db.update(
      _notesTable,
      {'isInTrash': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Collaborative Note Methods ---

  /// Returns a stream of a collaborative note.
  Stream<Note> getCollaborativeNoteStream(String noteId) {
    return firebaseService.documentStream.map((docData) {
      final contentJson = docData['content'] as Map<String, dynamic>;
      final contentStr = json.encode(contentJson);
      // Create a temporary Note object with the synced content.
      // Other note properties (title, etc.) would also be synced in a full
      // implementation.
      return Note(
        id: noteId,
        title: 'Collaborative Note', // Placeholder title
        content: contentStr,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'collaborator',
      );
    });
  }

  /// Updates the content of a collaborative note.
  Future<void> updateCollaborativeNote(String noteId, DocumentModel content) {
    return firebaseService.updateDocument(noteId, content);
  }

  /// Returns a stream of presence data for a collaborative note.
  Stream<Map<String, Map<String, dynamic>>> getPresenceStream(String noteId) {
    return firebaseService.presenceStream;
  }

  /// Updates the presence and cursor position of the current user.
  Future<void> updateUserPresence(
    String noteId,
    String userId,
    Map<String, dynamic> cursorData,
  ) {
    return firebaseService.updateUserPresence(noteId, userId, cursorData);
  }

  /// Removes the current user from the presence tracking.
  Future<void> removeUserPresence(String noteId, String userId) {
    return firebaseService.removeUserPresence(noteId, userId);
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // --- Event Sourcing Methods ---

  /// Adds a new event to the log.
  Future<void> addNoteEvent(NoteEvent event) async {
    final db = await database;
    await db.insert(
      _noteEventsTable,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all events for a specific note, ordered by timestamp.
  Future<List<NoteEvent>> getNoteEvents(String noteId) async {
    final db = await database;
    final maps = await db.query(
      _noteEventsTable,
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => NoteEvent.fromMap(maps[i]));
  }

  /// Updates an existing event (e.g., to mark as synced).
  Future<void> updateNoteEvent(NoteEvent event) async {
    final db = await database;
    await db.update(
      _noteEventsTable,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  // --- Full-Text Search Methods ---

  /// Performs a full-text search across notes.
  Future<List<SearchResult>> searchNotes(String query) async {
    if (query.trim().isEmpty) return [];

    final db = await database;

    // Escape special FTS5 characters and add prefix matching
    final sanitizedQuery = query
        .replaceAll('"', '""')
        .split(' ')
        .where((w) => w.length > 1) // Only use words > 1 char for search
        .map((w) => '"$w"*') // Prefix match with quotes for safety
        .join(' ');

    if (sanitizedQuery.isEmpty) return [];

    // Query FTS5 with ranking - Title has higher weight (10.0 vs 1.0)
    final results = await db.rawQuery(
      '''
      SELECT 
        n.*,
        snippet($_notesFtsTable, 0, '<b>', '</b>', '...', 16) as title_snippet,
        snippet($_notesFtsTable, 1, '<b>', '</b>', '...', 32) as content_snippet,
        bm25($_notesFtsTable, 10.0, 1.0) as rank
      FROM $_notesFtsTable fts
      JOIN $_notesTable n ON fts.rowid = n.rowid
      WHERE $_notesFtsTable MATCH ?
        AND n.isInTrash = 0
        AND n.isDeleted = 0
      ORDER BY rank
      LIMIT 100
    ''',
      [sanitizedQuery],
    );

    return results.map((row) {
      final titleSnippet = row['title_snippet'] as String? ?? '';
      final contentSnippet = row['content_snippet'] as String? ?? '';

      return SearchResult(
        note: Note.fromMap(row),
        snippet: titleSnippet.contains('<b>') ? titleSnippet : contentSnippet,
        rank: (row['rank'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  // --- User Dictionary Methods ---

  /// Learns a new word or increments its frequency.
  Future<void> learnWord(String word) async {
    if (word.length < 3) return; // Ignore short words

    final db = await database;
    final lowerWord = word.toLowerCase();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.rawInsert(
      '''
      INSERT INTO $_userDictionaryTable (word, frequency, lastUsed, isSynced)
      VALUES (?, 1, ?, 0)
      ON CONFLICT(word) DO UPDATE SET
        frequency = frequency + 1,
        lastUsed = ?,
        isSynced = 0
    ''',
      [lowerWord, now, now],
    );
  }

  /// Gets learned words matching a prefix, sorted by frequency.
  Future<List<String>> getLearnedWords(String prefix) async {
    final db = await database;
    final lowerPrefix = prefix.toLowerCase();

    final results = await db.query(
      _userDictionaryTable,
      columns: ['word'],
      where: 'word LIKE ?',
      whereArgs: ['$lowerPrefix%'],
      orderBy: 'frequency DESC',
      limit: 10,
    );

    return results.map((r) => r['word']! as String).toList();
  }

  /// Gets all unsynced words for push to cloud.
  Future<List<Map<String, dynamic>>> getUnsyncedWords() async {
    final db = await database;
    return db.query(
      _userDictionaryTable,
      where: 'isSynced = 0',
    );
  }

  /// Marks words as synced after successful push.
  Future<void> markWordsSynced(List<String> words) async {
    if (words.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(words.length, '?').join(',');
    await db.rawUpdate('''
      UPDATE $_userDictionaryTable 
      SET isSynced = 1 
      WHERE word IN ($placeholders)
    ''', words);
  }

  /// Imports words from cloud sync (merges with local).
  Future<void> importWords(List<Map<String, dynamic>> cloudWords) async {
    final db = await database;
    final batch = db.batch();

    for (final word in cloudWords) {
      batch.rawInsert(
        '''
        INSERT INTO $_userDictionaryTable (word, frequency, lastUsed, isSynced)
        VALUES (?, ?, ?, 1)
        ON CONFLICT(word) DO UPDATE SET
          frequency = MAX(frequency, excluded.frequency),
          lastUsed = MAX(lastUsed, excluded.lastUsed),
          isSynced = 1
      ''',
        [
          word['word'],
          word['frequency'] ?? 1,
          word['lastUsed'] ?? DateTime.now().millisecondsSinceEpoch,
        ],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Retrieves all notes that haven't been synced to the remote storage.
  Future<List<Note>> getUnsyncedNotes() async {
    final db = await database;
    final results = await db.query(
      _notesTable,
      where: 'syncStatus = ? OR syncStatus = ?',
      whereArgs: [SyncStatus.local.index, SyncStatus.modified.index],
    );
    return results.map(Note.fromMap).toList();
  }
}

/// Represents a search result with the matched note and a snippet.
class SearchResult {
  /// Creates a [SearchResult].
  const SearchResult({
    required this.note,
    required this.snippet,
    required this.rank,
  });

  /// The matched note.
  final Note note;

  /// A snippet of the matched content with highlights.
  final String snippet;

  /// The relevance rank (lower is better in BM25).
  final double rank;
}
