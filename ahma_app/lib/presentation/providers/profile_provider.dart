import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local_identity_store.dart';
import '../../data/datasources/profile_api.dart';
import '../../data/models/profile_models.dart';
import 'auth_provider.dart';

final localIdentityStoreProvider = Provider<LocalIdentityStore>(
  (ref) => LocalIdentityStore(),
);

final profileApiProvider = Provider<ProfileApi>((ref) {
  final identity = ref.watch(localIdentityStoreProvider);
  return ProfileApi(
    // The session JWT authenticates `/me`; profile create supplies its own
    // verified-email signup token on the request.
    bearerToken: () async => identity.readToken(),
  );
});

/// Backend option catalog (labels for raw option values). Fetched once and
/// cached; invalidate to retry after a failure.
final profileOptionsProvider = FutureProvider<ProfileOptions>((ref) {
  return ref.watch(profileApiProvider).getOptions();
});

/// Where the app should be at launch.
enum ProfileGateStatus {
  /// Fetching the profile for the current session.
  checking,

  /// Profile service unreachable/misconfigured with a live session.
  /// The session is KEPT; the user can retry.
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
/// variants). Only mounted once auth holds a valid session, so identity comes
/// from the JWT — the gate just fetches `/me`:
///
/// - GET /api/profile/me 200          -> ready
/// - 404 profile_not_found / 401      -> stale session, sign out to the login
/// - anything else                    -> unreachable (retriable, session kept)
class ProfileGateNotifier extends StateNotifier<ProfileGateState> {
  final ProfileApi _api;
  final Ref _ref;

  ProfileGateNotifier(this._api, this._ref)
    : super(const ProfileGateState.checking()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = const ProfileGateState.checking();

    try {
      final profile = await _api.getMe();
      if (!mounted) return;
      state = ProfileGateState(
        status: ProfileGateStatus.ready,
        profile: profile,
      );
    } on ProfileUnauthorizedException {
      // Token missing/expired/rejected: drop the session back to the login.
      await _ref.read(authProvider.notifier).signOut();
    } on ProfileNotFoundException {
      // The account+profile are created atomically, so a 404 for a valid
      // session means the data was wiped underneath us. Sign out; the user
      // can create a fresh profile.
      await _ref.read(authProvider.notifier).signOut();
    } catch (_) {
      // Connection refused, timeout, 5xx, non-JSON, parse failure…
      // Keep the session and offer retry — never sign out on an outage.
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

  /// Partial profile update (PATCH /me). On success the in-memory profile is
  /// replaced, so profile-derived UI (dashboard greeting, account page)
  /// refreshes immediately. Typed [ProfileApiException]s propagate to the
  /// caller for inline error mapping.
  Future<UserProfile> updateProfile(ProfilePatchRequest patch) async {
    if (state.status != ProfileGateStatus.ready || state.profile == null) {
      throw StateError('updateProfile called before the gate is ready');
    }

    final updated = await _api.updateMe(patch);
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
      return ProfileGateNotifier(ref.watch(profileApiProvider), ref);
    });

/// Call-time profile context (GET /api/profile/me/context).
///
/// Returns null when the gate is not ready or the context fetch fails —
/// call flows degrade gracefully to the base profile / generic greeting.
final profileContextProvider = FutureProvider<ProfileContextData?>((ref) async {
  final gate = ref.watch(profileGateProvider);
  if (gate.status != ProfileGateStatus.ready || gate.profile == null) {
    return null;
  }

  try {
    return await ref.watch(profileApiProvider).getMeContext();
  } catch (_) {
    return null;
  }
});
