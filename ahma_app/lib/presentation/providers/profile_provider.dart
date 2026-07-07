import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local_identity_store.dart';
import '../../data/datasources/profile_api.dart';
import '../../data/models/profile_models.dart';

final localIdentityStoreProvider = Provider<LocalIdentityStore>(
  (ref) => LocalIdentityStore(),
);

final profileApiProvider = Provider<ProfileApi>((ref) {
  final identity = ref.watch(localIdentityStoreProvider);
  return ProfileApi(
    // Stub session token: the saved userId (or the login email before a
    // profile exists) stands in for a real IdP token. The local backend
    // ignores the header; production middleware will verify it.
    bearerToken: () async =>
        await identity.readUserId() ?? await identity.readLoginEmail(),
  );
});

/// Backend option catalog (labels for raw option values). Fetched once and
/// cached; invalidate to retry after a failure.
final profileOptionsProvider = FutureProvider<ProfileOptions>((ref) {
  return ref.watch(profileApiProvider).getOptions();
});

/// Where the app should be at launch.
enum ProfileGateStatus {
  /// Reading the saved userId / fetching the profile.
  checking,

  /// No local identity — run conversational onboarding.
  onboarding,

  /// Profile service unreachable/misconfigured with a saved identity.
  /// Identity is KEPT; the user can retry.
  unreachable,

  /// Profile loaded — enter the main AHMA experience.
  ready,
}

class ProfileGateState {
  final ProfileGateStatus status;
  final UserProfile? profile;
  final String? message;

  const ProfileGateState({required this.status, this.profile, this.message});

  const ProfileGateState.checking() : this(status: ProfileGateStatus.checking);
}

/// Launch gate for the profile lifecycle (sits above both home-screen
/// variants):
///
/// - no saved userId          -> onboarding
/// - GET /api/profile/:id 200 -> ready
/// - JSON 404 profile_not_found -> clear identity, onboarding
/// - anything else            -> unreachable (retriable, identity kept)
class ProfileGateNotifier extends StateNotifier<ProfileGateState> {
  final ProfileApi _api;
  final LocalIdentityStore _identity;

  ProfileGateNotifier(this._api, this._identity)
    : super(const ProfileGateState.checking()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = const ProfileGateState.checking();

    final userId = await _identity.readUserId();
    if (!mounted) return;

    if (userId == null) {
      state = const ProfileGateState(status: ProfileGateStatus.onboarding);
      return;
    }

    try {
      final profile = await _api.getProfile(userId);
      if (!mounted) return;
      state = ProfileGateState(
        status: ProfileGateStatus.ready,
        profile: profile,
      );
    } on ProfileNotFoundException {
      // The only case where local identity is cleared: the backend
      // explicitly said this profile does not exist (e.g. after
      // --reset-profile-data wiped the local database).
      await _identity.clearUserId();
      if (!mounted) return;
      state = const ProfileGateState(status: ProfileGateStatus.onboarding);
    } catch (_) {
      // Connection refused, timeout, 5xx, non-JSON 404, parse failure…
      // Keep the identity and offer retry — never onboard on outage.
      if (!mounted) return;
      state = const ProfileGateState(
        status: ProfileGateStatus.unreachable,
        message:
            "We can't reach the profile service right now. "
            'If you run the app locally, start it with '
            './setup_and_run.sh --with-profile-backend and try again.',
      );
    }
  }

  Future<void> retry() => _initialize();

  /// Called by onboarding after a confirmed 201 create.
  void completeOnboarding(UserProfile profile) {
    state = ProfileGateState(status: ProfileGateStatus.ready, profile: profile);
  }

  /// Partial profile update (PATCH). On success the in-memory profile is
  /// replaced, so profile-derived UI (dashboard greeting, account page)
  /// refreshes immediately. Typed [ProfileApiException]s propagate to the
  /// caller for inline error mapping.
  Future<UserProfile> updateProfile(ProfilePatchRequest patch) async {
    final current = state.profile;
    if (state.status != ProfileGateStatus.ready || current == null) {
      throw StateError('updateProfile called before the gate is ready');
    }

    final updated = await _api.updateProfile(current.userId, patch);
    if (mounted) {
      state = ProfileGateState(
        status: ProfileGateStatus.ready,
        profile: updated,
      );
    }
    return updated;
  }
}

final profileGateProvider =
    StateNotifierProvider<ProfileGateNotifier, ProfileGateState>((ref) {
      return ProfileGateNotifier(
        ref.watch(profileApiProvider),
        ref.watch(localIdentityStoreProvider),
      );
    });

/// Call-time profile context (GET /api/profile/:userId/context).
///
/// Returns null when the gate is not ready or the context fetch fails —
/// call flows degrade gracefully to the base profile / generic greeting.
final profileContextProvider = FutureProvider<ProfileContextData?>((ref) async {
  final gate = ref.watch(profileGateProvider);
  final profile = gate.profile;
  if (gate.status != ProfileGateStatus.ready || profile == null) {
    return null;
  }

  try {
    return await ref
        .watch(profileApiProvider)
        .getProfileContext(profile.userId);
  } catch (_) {
    return null;
  }
});
