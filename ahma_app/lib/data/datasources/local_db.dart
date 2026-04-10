import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/action_plan.dart';

/// Local SQLite database for persisting action plans
///
/// Stores all backend updates/action plans locally so users can:
/// - View history offline
/// - Browse past action plans by date
/// - Search for specific calls
class LocalDatabase {
  static Database? _database;
  static const String _dbName = 'ahma.db';
  static const int _dbVersion = 2;

  /// Table names
  static const String _actionPlansTable = 'action_plans';

  /// Singleton instance
  static final LocalDatabase instance = LocalDatabase._internal();

  factory LocalDatabase() => instance;

  LocalDatabase._internal();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initialize database with schema
  Future<Database> _initDB() async {
    // Initialize FFI for desktop platforms (Linux, Windows, macOS)
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_actionPlansTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        call_id TEXT NOT NULL UNIQUE,
        call_type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        classification TEXT NOT NULL,
        action_plan TEXT NOT NULL,
        stats TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON $_actionPlansTable(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_user_id ON $_actionPlansTable(user_id)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future schema changes
    if (oldVersion < 2) {
      // Add UNIQUE constraint to call_id column
      // SQLite doesn't support ALTER TABLE ADD CONSTRAINT, so we need to recreate the table
      await db.execute('''
        CREATE TABLE $_actionPlansTable\_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          call_id TEXT NOT NULL UNIQUE,
          call_type TEXT NOT NULL,
          user_id TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          classification TEXT NOT NULL,
          action_plan TEXT NOT NULL,
          stats TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      
      // Copy data from old table to new table (removing duplicates)
      await db.execute('''
        INSERT INTO $_actionPlansTable\_new (call_id, call_type, user_id, timestamp, classification, action_plan, stats, created_at)
        SELECT call_id, call_type, user_id, timestamp, classification, action_plan, stats, created_at
        FROM $_actionPlansTable
        GROUP BY call_id
      ''');
      
      // Drop old table and rename new table
      await db.execute('DROP TABLE $_actionPlansTable');
      await db.execute('ALTER TABLE $_actionPlansTable\_new RENAME TO $_actionPlansTable');
      
      // Recreate indexes
      await db.execute('''
        CREATE INDEX idx_timestamp ON $_actionPlansTable(timestamp DESC)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_user_id ON $_actionPlansTable(user_id)
      ''');
    }
  }

  /// Save an action plan to the database
  Future<int> saveActionPlan(BackendUpdate update) async {
    final db = await database;

    final data = {
      'call_id': update.callId,
      'call_type': update.type,
      'user_id': update.userId,
      'timestamp': update.timestamp.toIso8601String(), // Convert DateTime to String
      'classification': jsonEncode(update.classification.toJson()),
      'action_plan': jsonEncode(update.actionPlan.toJson()),
      'stats': jsonEncode(update.stats.toJson()),
      'created_at': DateTime.now().toIso8601String(),
    };

    print('[DB] Saving action plan for call: ${update.callId}');
    print('[DB]   Calendar events: ${update.actionPlan.calendarEvents.length}');
    print('[DB]   Todoist tasks: ${update.actionPlan.todoistTasks.length}');
    print('[DB]   Resources: ${update.actionPlan.resources.length}');

    final result = await db.insert(
      _actionPlansTable,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('[DB] Insert result: $result');
    return result;
  }

  /// Get action plans with optional filters
  Future<List<BackendUpdate>> getActionPlans({
    String? callId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;

    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (callId != null) {
      where += ' AND call_id = ?';
      whereArgs.add(callId);
    }

    if (userId != null) {
      where += ' AND user_id = ?';
      whereArgs.add(userId);
    }

    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final results = await db.query(
      _actionPlansTable,
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    print('[DB] Query returned ${results.length} results');
    
    final updates = results.map((row) {
      final update = BackendUpdate.fromJson({
        'type': row['call_type'],
        'userId': row['user_id'],
        'callId': row['call_id'],
        'timestamp': row['timestamp'],
        'classification': jsonDecode(row['classification'] as String),
        'action_plan': jsonDecode(row['action_plan'] as String),
        'stats': jsonDecode(row['stats'] as String),
      });
      
      print('[DB]   Call: ${update.callId}, Tasks: ${update.actionPlan.todoistTasks.length}');
      return update;
    }).toList();

    return updates;
  }

  /// Get action plans grouped by date
  Future<Map<String, List<BackendUpdate>>> getActionPlansGroupedByDate({
    String? userId,
  }) async {
    final allPlans = await getActionPlans(userId: userId);
    final grouped = <String, List<BackendUpdate>>{};

    for (final plan in allPlans) {
      // plan.timestamp is already a DateTime object
      final dateKey = DateFormat('yyyy-MM-dd').format(plan.timestamp);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(plan);
    }

    return grouped;
  }

  /// Get action plan by call ID
  Future<BackendUpdate?> getActionPlanByCallId(String callId) async {
    final plans = await getActionPlans(callId: callId, limit: 1);
    return plans.isEmpty ? null : plans.first;
  }

  /// Delete an action plan
  Future<int> deleteActionPlan(String callId) async {
    final db = await database;
    return await db.delete(
      _actionPlansTable,
      where: 'call_id = ?',
      whereArgs: [callId],
    );
  }

  /// Delete all action plans for a user
  Future<int> deleteAllActionPlans({String? userId}) async {
    final db = await database;

    if (userId != null) {
      return await db.delete(
        _actionPlansTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      return await db.delete(_actionPlansTable);
    }
  }

  /// Get count of action plans
  Future<int> getActionPlanCount({String? userId}) async {
    final db = await database;

    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      where += ' AND user_id = ?';
      whereArgs.add(userId);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_actionPlansTable WHERE $where',
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
