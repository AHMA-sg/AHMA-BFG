import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/action_plan.dart';
import '../../data/datasources/local_db_web.dart'
    if (dart.library.io) '../../data/datasources/local_db.dart';
import '../../data/datasources/backend_api.dart';
import '../../data/datasources/local_identity_store.dart';

/// Backend update state
class BackendState {
  final List<BackendUpdate> updates;
  final BackendUpdate? latestUpdate;
  final bool isLoading;
  final String? error;

  const BackendState({
    this.updates = const [],
    this.latestUpdate,
    this.isLoading = false,
    this.error,
  });

  BackendState copyWith({
    List<BackendUpdate>? updates,
    BackendUpdate? latestUpdate,
    bool? isLoading,
    String? error,
  }) {
    return BackendState(
      updates: updates ?? this.updates,
      latestUpdate: latestUpdate ?? this.latestUpdate,
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

      final updates = await _localDb.getActionPlans();

      state = state.copyWith(
        updates: updates,
        latestUpdate: updates.isNotEmpty ? updates.first : null,
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
      final remoteUpdates = await _backendApi.getSummaries(userId: userId);
      for (final update in remoteUpdates.reversed) {
        await _localDb.saveActionPlan(update);
      }
      final localOnly = state.updates.where(
        (local) =>
            !remoteUpdates.any((remote) => remote.callId == local.callId),
      );
      final combined = [...remoteUpdates, ...localOnly]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(
        updates: combined,
        latestUpdate: combined.isEmpty ? null : combined.first,
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
      final updatedList = [update, ...filteredUpdates];

      state = state.copyWith(updates: updatedList, latestUpdate: update);

      print(
        '[Backend] Updated state with ${updatedList.length} total action plans',
      );
    } catch (e) {
      print('[Backend] Error saving action plan: $e');
      state = state.copyWith(error: 'Failed to save action plan');
    }
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
      state = const BackendState();
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
