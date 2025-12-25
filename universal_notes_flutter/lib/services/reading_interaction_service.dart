import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/models/reading_annotation.dart';
import 'package:uuid/uuid.dart';

/// Service for managing reading annotations (highlights and notes).
class ReadingInteractionService {
  /// Creates a new [ReadingInteractionService].
  ReadingInteractionService({required Database database})
    : _database = database;

  final Database _database;
  static const _tableName = 'reading_annotations';
  static const _uuid = Uuid();

  /// Gets all annotations for a note.
  Future<List<ReadingAnnotation>> getAnnotationsForNote(String noteId) async {
    final results = await _database.query(
      _tableName,
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'startOffset ASC',
    );

    return results.map(ReadingAnnotation.fromMap).toList();
  }

  /// Adds a new annotation (highlight or note).
  Future<void> addAnnotation(ReadingAnnotation annotation) async {
    await _database.insert(_tableName, annotation.toMap());
  }

  /// Adds a new highlight.
  Future<ReadingAnnotation> addHighlight({
    required String noteId,
    required int startOffset,
    required int endOffset,
    required int color,
    String? textExcerpt,
  }) async {
    final annotation = ReadingAnnotation(
      id: _uuid.v4(),
      noteId: noteId,
      startOffset: startOffset,
      endOffset: endOffset,
      createdAt: DateTime.now(),
      color: color,
      textExcerpt: textExcerpt,
    );

    await _database.insert(_tableName, annotation.toMap());
    return annotation;
  }

  /// Adds a new note/comment.
  Future<ReadingAnnotation> addNote({
    required String noteId,
    required int offset,
    required String comment,
    String? textExcerpt,
  }) async {
    final annotation = ReadingAnnotation(
      id: _uuid.v4(),
      noteId: noteId,
      startOffset: offset,
      endOffset: offset,
      createdAt: DateTime.now(),
      comment: comment,
      textExcerpt: textExcerpt,
    );

    await _database.insert(_tableName, annotation.toMap());
    return annotation;
  }

  /// Updates an annotation.
  Future<void> updateAnnotation(ReadingAnnotation annotation) async {
    await _database.update(
      _tableName,
      annotation.toMap(),
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
  }

  /// Deletes an annotation.
  Future<void> deleteAnnotation(String id) async {
    await _database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
