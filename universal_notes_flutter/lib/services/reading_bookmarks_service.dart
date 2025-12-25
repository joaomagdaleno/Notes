import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/models/reading_bookmark.dart';
import 'package:uuid/uuid.dart';

/// Service for managing reading bookmarks.
///
/// Provides CRUD operations for bookmarks stored in SQLite.
class ReadingBookmarksService {
  /// Creates a new [ReadingBookmarksService].
  ReadingBookmarksService({required Database database}) : _database = database;

  final Database _database;
  static const _tableName = 'reading_bookmarks';
  static const _uuid = Uuid();

  /// Ensures the bookmarks table exists.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        noteId TEXT NOT NULL,
        position INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        name TEXT,
        excerpt TEXT
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bookmarks_noteId ON $_tableName (noteId)
    ''');
  }

  /// Gets all bookmarks for a note.
  Future<List<ReadingBookmark>> getBookmarksForNote(String noteId) async {
    final results = await _database.query(
      _tableName,
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'position ASC',
    );

    return results.map(_fromRow).toList();
  }

  /// Gets a bookmark by ID.
  Future<ReadingBookmark?> getBookmark(String id) async {
    final results = await _database.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return _fromRow(results.first);
  }

  /// Adds a new bookmark.
  Future<ReadingBookmark> addBookmark({
    required String noteId,
    required int position,
    String? name,
    String? excerpt,
  }) async {
    final bookmark = ReadingBookmark(
      id: _uuid.v4(),
      noteId: noteId,
      position: position,
      createdAt: DateTime.now(),
      name: name,
      excerpt: excerpt,
    );

    await _database.insert(_tableName, _toRow(bookmark));
    return bookmark;
  }

  /// Updates an existing bookmark.
  Future<void> updateBookmark(ReadingBookmark bookmark) async {
    await _database.update(
      _tableName,
      _toRow(bookmark),
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }

  /// Deletes a bookmark.
  Future<void> deleteBookmark(String id) async {
    await _database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all bookmarks for a note.
  Future<void> deleteBookmarksForNote(String noteId) async {
    await _database.delete(
      _tableName,
      where: 'noteId = ?',
      whereArgs: [noteId],
    );
  }

  /// Counts bookmarks for a note.
  Future<int> countBookmarksForNote(String noteId) async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE noteId = ?',
      [noteId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  ReadingBookmark _fromRow(Map<String, dynamic> row) {
    return ReadingBookmark(
      id: row['id'] as String,
      noteId: row['noteId'] as String,
      position: row['position'] as int,
      createdAt: DateTime.parse(row['createdAt'] as String),
      name: row['name'] as String?,
      excerpt: row['excerpt'] as String?,
    );
  }

  Map<String, dynamic> _toRow(ReadingBookmark bookmark) {
    return {
      'id': bookmark.id,
      'noteId': bookmark.noteId,
      'position': bookmark.position,
      'createdAt': bookmark.createdAt.toIso8601String(),
      'name': bookmark.name,
      'excerpt': bookmark.excerpt,
    };
  }
}
