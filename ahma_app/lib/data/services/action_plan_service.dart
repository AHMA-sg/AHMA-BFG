import '../datasources/local_db.dart';
import '../models/action_plan.dart';

/// Service for managing action plans from local database
class ActionPlanService {
  /// Get all action plans from local database
  static Future<List<ActionPlan>> getAllActionPlans() async {
    final db = await LocalDatabase.getDatabase();
    final plans = await db.query(_actionPlansTable);
    
    return plans.map((row) => ActionPlan(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String,
      date: DateTime.parse(row['date'] as String),
      steps: (row['steps'] as String).split(','),
      isActive: (row['is_active'] as int) == 1,
    )).toList();
  }

  /// Get action plans by date range
  static Future<List<ActionPlan>> getActionPlansByDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final db = await LocalDatabase.getDatabase();
    final plans = await db.query(
      _actionPlansTable,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    
    return plans.map((row) => ActionPlan(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String,
      date: DateTime.parse(row['date'] as String),
      steps: (row['steps'] as String).split(','),
      isActive: (row['is_active'] as int) == 1,
    )).toList();
  }

  /// Save a new action plan
  static Future<void> saveActionPlan(ActionPlan plan) async {
    final db = await LocalDatabase.getDatabase();
    await db.insert(
      _actionPlansTable,
      {
        'title': plan.title,
        'description': plan.description,
        'date': plan.date.toIso8601String(),
        'steps': plan.steps.join(','),
        'is_active': plan.isActive ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Update an existing action plan
  static Future<void> updateActionPlan(ActionPlan plan) async {
    final db = await LocalDatabase.getDatabase();
    await db.update(
      _actionPlansTable,
      {
        'title': plan.title,
        'description': plan.description,
        'date': plan.date.toIso8601String(),
        'steps': plan.steps.join(','),
        'is_active': plan.isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  /// Delete an action plan
  static Future<void> deleteActionPlan(int planId) async {
    final db = await LocalDatabase.getDatabase();
    await db.delete(
      _actionPlansTable,
      where: 'id = ?',
      whereArgs: [planId],
    );
  }
}
