import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/action_plan.dart';
import '../../data/datasources/local_db_web.dart'
    if (dart.library.io) '../../data/datasources/local_db.dart';
import '../../data/datasources/backend_api.dart';
import '../../data/datasources/local_identity_store.dart';

/// Backend update state
class BackendState {
  static const Object _notProvided = Object();

  final List<BackendUpdate> updates;
  final BackendUpdate? latestUpdate;
  final int journeyCount;
  final bool isLoading;
  final String? error;

  const BackendState({
    this.updates = const [],
    this.latestUpdate,
    this.journeyCount = 0,
    this.isLoading = false,
    this.error,
  });

  BackendState copyWith({
    List<BackendUpdate>? updates,
    Object? latestUpdate = _notProvided,
    int? journeyCount,
    bool? isLoading,
    String? error,
  }) {
    return BackendState(
      updates: updates ?? this.updates,
      latestUpdate: identical(latestUpdate, _notProvided)
          ? this.latestUpdate
          : latestUpdate as BackendUpdate?,
      journeyCount: journeyCount ?? this.journeyCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Backend provider - manages action plans and updates from backend
class BackendNotifier extends StateNotifier<BackendState> {
  final LocalDatabase _localDb;
  final BackendApi _backendApi;
  final LocalIdentityStore _identityStore;

  BackendNotifier(this._localDb, this._backendApi, this._identityStore)
    : super(const BackendState()) {
    _loadInitialUpdates();
  }

  Future<void> _loadInitialUpdates() async {
    await _loadFromLocalStorage();
    await refreshFromBackend();
  }

  /// Load action plans from local storage on initialization
  Future<void> _loadFromLocalStorage() async {
    try {
      state = state.copyWith(isLoading: true);

      final updates = await _localDb.getActionPlans(limit: 20);

      state = state.copyWith(
        updates: updates,
        latestUpdate: updates.isNotEmpty ? updates.first : null,
        // Postgres replaces this provisional offline value on refresh.
        journeyCount: state.journeyCount > 0
            ? state.journeyCount
            : updates.length,
        isLoading: false,
      );

      print(
        '[Backend] Loaded ${updates.length} action plans from local storage',
      );
    } catch (e) {
      print('[Backend] Error loading from local storage: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load action plans',
      );
    }
  }

  /// Hydrate web and newly installed clients from durable Postgres storage.
  Future<void> refreshFromBackend() async {
    final userId = await _identityStore.readUserId();
    if (userId == null || userId.isEmpty) return;

    try {
      final result = await _backendApi.getSummaries(userId: userId, limit: 20);
      final remoteUpdates = result.summaries;
      final remoteIds = remoteUpdates.map((update) => update.callId).toSet();
      final cachedUpdates = await _localDb.getActionPlans(userId: userId);
      for (final cached in cachedUpdates) {
        if (!remoteIds.contains(cached.callId)) {
          await _localDb.deleteActionPlan(cached.callId);
        }
      }
      for (final update in remoteUpdates.reversed) {
        await _localDb.saveActionPlan(update);
      }
      await _localDb.pruneActionPlans(keep: 20, userId: userId);
      final combined = List<BackendUpdate>.from(remoteUpdates)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(
        updates: combined,
        latestUpdate: combined.isEmpty ? null : combined.first,
        journeyCount: result.journeyCount,
        isLoading: false,
      );
      print('[Backend] Loaded ${remoteUpdates.length} summaries from backend');
    } catch (e) {
      // Keep locally cached entries visible if the API is temporarily offline.
      print('[Backend] Could not refresh summaries from backend: $e');
    }
  }

  /// Process a new backend update from webhook
  Future<void> processUpdate(BackendUpdate update) async {
    print('[Backend] Processing update: ${update.type}');
    print('[Backend] Total actions: ${update.stats.actionsInWebhook}');
    print('[Backend] New actions: ${update.stats.newActions}');
    print('[Backend] Duplicates skipped: ${update.stats.duplicatesSkipped}');

    try {
      // Save to local database
      await _localDb.saveActionPlan(update);
      print(
        '[Backend] Saved action plan to local storage (call: ${update.callId})',
      );

      // Remove existing update with same callId to prevent duplicates in state
      final filteredUpdates = state.updates
          .where((u) => u.callId != update.callId)
          .toList();

      // Add new update to the beginning of the list
      final isNewJourney = filteredUpdates.length == state.updates.length;
      final updatedList = [update, ...filteredUpdates].take(20).toList();
      final retainedIds = updatedList.map((item) => item.callId).toSet();
      for (final oldUpdate in state.updates) {
        if (!retainedIds.contains(oldUpdate.callId)) {
          await _localDb.deleteActionPlan(oldUpdate.callId);
        }
      }
      await _localDb.pruneActionPlans(keep: 20, userId: update.userId);

      state = state.copyWith(
        updates: updatedList,
        latestUpdate: update,
        journeyCount: isNewJourney
            ? state.journeyCount + 1
            : state.journeyCount,
      );

      print(
        '[Backend] Updated state with ${updatedList.length} total action plans',
      );
    } catch (e) {
      print('[Backend] Error saving action plan: $e');
      state = state.copyWith(error: 'Failed to save action plan');
    }
  }

  /// Delete a journal summary from Postgres, local cache, and in-memory state.
  /// The lifetime journey count deliberately stays unchanged.
  Future<void> deleteSummary(String callId) async {
    final userId = await _identityStore.readUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('No signed-in user is available.');
    }

    await _backendApi.deleteSummary(userId: userId, callId: callId);
    await _localDb.deleteActionPlan(callId);

    final remaining = state.updates
        .where((update) => update.callId != callId)
        .toList();
    state = state.copyWith(
      updates: remaining,
      latestUpdate: remaining.isEmpty ? null : remaining.first,
    );
  }

  /// Get action plans grouped by date
  Future<Map<String, List<BackendUpdate>>> getGroupedByDate() async {
    try {
      return await _localDb.getActionPlansGroupedByDate();
    } catch (e) {
      print('[Backend] Error getting grouped action plans: $e');
      return {};
    }
  }

  /// Get action plans for a specific date range
  Future<List<BackendUpdate>> getActionPlansInRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _localDb.getActionPlans(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('[Backend] Error getting action plans in range: $e');
      return [];
    }
  }

  /// Get action plan by call ID
  Future<BackendUpdate?> getActionPlanByCallId(String callId) async {
    try {
      return await _localDb.getActionPlanByCallId(callId);
    } catch (e) {
      print('[Backend] Error getting action plan by call ID: $e');
      return null;
    }
  }

  /// Clear all updates (from memory and database)
  Future<void> clearUpdates() async {
    try {
      await _localDb.deleteAllActionPlans();
      state = BackendState(journeyCount: state.journeyCount);
      print('[Backend] Cleared all action plans');
    } catch (e) {
      print('[Backend] Error clearing action plans: $e');
      state = state.copyWith(error: 'Failed to clear action plans');
    }
  }

  /// Mark update as viewed
  void markAsViewed(String callId) {
    final updatedList = state.updates.map((update) {
      if (update.callId == callId) {
        // Could add a 'viewed' flag to BackendUpdate model
        return update;
      }
      return update;
    }).toList();

    state = state.copyWith(updates: updatedList);
  }

  /// Reload from database (useful after external changes)
  Future<void> reload() async {
    await _loadFromLocalStorage();
    await refreshFromBackend();
  }
}

/// Local database provider
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase.instance;
});

/// Provider
final backendProvider = StateNotifierProvider<BackendNotifier, BackendState>((
  ref,
) {
  final localDb = ref.watch(localDatabaseProvider);
  return BackendNotifier(localDb, BackendApi(), LocalIdentityStore());
});
