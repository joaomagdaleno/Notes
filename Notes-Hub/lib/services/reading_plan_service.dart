import 'package:notes_hub/models/reading_plan_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Service for managing reading plans.
class ReadingPlanService {
  /// Internal constructor.
  ReadingPlanService({required Database database}) : _database = database;

  final Database _database;
  static const _tableName = 'reading_plans';
  static const _uuid = Uuid();

  /// Ensures the table exists.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        noteIds TEXT NOT NULL,
        currentIndex INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Gets all reading plans.
  Future<List<ReadingPlan>> getAllPlans() async {
    final results = await _database.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );
    return results.map(ReadingPlan.fromMap).toList();
  }

  /// Gets a plan by ID.
  Future<ReadingPlan?> getPlan(String id) async {
    final results = await _database.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return ReadingPlan.fromMap(results.first);
  }

  /// Creates a new reading plan.
  Future<ReadingPlan> createPlan({
    required String title,
    required List<String> noteIds,
  }) async {
    final plan = ReadingPlan(
      id: _uuid.v4(),
      title: title,
      noteIds: noteIds,
    );
    await _database.insert(_tableName, plan.toMap());
    return plan;
  }

  /// Updates an existing reading plan.
  Future<void> updatePlan(ReadingPlan plan) async {
    await _database.update(
      _tableName,
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  /// Deletes a reading plan.
  Future<void> deletePlan(String id) async {
    await _database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Finds the first plan containing the given note ID.
  Future<ReadingPlan?> findPlanForNote(String noteId) async {
    final plans = await getAllPlans();
    for (final plan in plans) {
      if (plan.noteIds.contains(noteId)) {
        return plan;
      }
    }
    return null;
  }
}
