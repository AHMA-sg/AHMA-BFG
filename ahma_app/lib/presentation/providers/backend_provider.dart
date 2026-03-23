import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/action_plan.dart';

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
  BackendNotifier() : super(const BackendState());

  /// Process a new backend update from webhook
  void processUpdate(BackendUpdate update) {
    print('[Backend] Processing update: ${update.type}');
    print('[Backend] Total actions: ${update.stats.actionsInWebhook}');
    print('[Backend] New actions: ${update.stats.newActions}');
    print('[Backend] Duplicates skipped: ${update.stats.duplicatesSkipped}');

    // Add to updates list
    final updatedList = [update, ...state.updates];

    state = state.copyWith(
      updates: updatedList,
      latestUpdate: update,
    );
  }

  /// Clear all updates
  void clearUpdates() {
    state = const BackendState();
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
}

/// Provider
final backendProvider = StateNotifierProvider<BackendNotifier, BackendState>((ref) {
  return BackendNotifier();
});
