import '../models/action_plan.dart';

/// In-memory action plan store for Flutter Web builds.
///
/// The SQLite implementation depends on dart:io and sqflite FFI, which are not
/// available in browsers. This keeps the web build functional without changing
/// the provider API.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._internal();

  final List<BackendUpdate> _updates = [];

  factory LocalDatabase() => instance;

  LocalDatabase._internal();

  Future<int> saveActionPlan(BackendUpdate update) async {
    _updates.removeWhere((existing) => existing.callId == update.callId);
    _updates.insert(0, update);
    return _updates.length;
  }

  Future<List<BackendUpdate>> getActionPlans({
    String? callId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    Iterable<BackendUpdate> results = _updates;

    if (callId != null) {
      results = results.where((update) => update.callId == callId);
    }
    if (userId != null) {
      results = results.where((update) => update.userId == userId);
    }
    if (startDate != null) {
      results = results.where(
        (update) => !update.timestamp.isBefore(startDate),
      );
    }
    if (endDate != null) {
      results = results.where((update) => !update.timestamp.isAfter(endDate));
    }

    final sorted = results.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return limit == null ? sorted : sorted.take(limit).toList();
  }

  Future<Map<String, List<BackendUpdate>>> getActionPlansGroupedByDate({
    String? userId,
  }) async {
    final allPlans = await getActionPlans(userId: userId);
    final grouped = <String, List<BackendUpdate>>{};

    for (final plan in allPlans) {
      final timestamp = plan.timestamp;
      final dateKey =
          '${timestamp.year.toString().padLeft(4, '0')}-'
          '${timestamp.month.toString().padLeft(2, '0')}-'
          '${timestamp.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(plan);
    }

    return grouped;
  }

  Future<BackendUpdate?> getActionPlanByCallId(String callId) async {
    final plans = await getActionPlans(callId: callId, limit: 1);
    return plans.isEmpty ? null : plans.first;
  }

  Future<int> deleteAllActionPlans({String? userId}) async {
    final before = _updates.length;

    if (userId == null) {
      _updates.clear();
    } else {
      _updates.removeWhere((update) => update.userId == userId);
    }

    return before - _updates.length;
  }
}
