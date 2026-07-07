import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/contact_format.dart';
import '../../data/datasources/local_identity_store.dart';
import '../../data/datasources/profile_api.dart';
import 'profile_provider.dart';

/// Where the app is in the (stubbed) auth lifecycle.
enum AuthStatus {
  /// Reading the persisted session at cold start.
  restoring,

  /// No session — show the login screen.
  loggedOut,

  /// Login submitted; resolving the email against the profile backend.
  signingIn,

  /// Session established — hand off to the profile gate.
  loggedIn,
}

class AuthState {
  final AuthStatus status;

  /// The email used at login. Seeds the onboarding contact question for
  /// first-time users and is persisted as the session marker.
  final String? email;

  /// Inline error for the login screen, or null.
  final String? errorMessage;

  const AuthState({required this.status, this.email, this.errorMessage});

  const AuthState.restoring() : this(status: AuthStatus.restoring);
}

/// Simulated auth, deliberately shaped like a real `AuthRepository`:
/// `signIn(credential) -> session`, `restore()`, `signOut()`.
///
/// There is NO real authentication — the email is a stand-in for a verified
/// token subject (`sub`). Sign-in resolves the email to a `userId` via
/// `POST /api/profile/resolve` (the stub's token→identity resolution):
///
/// - resolved            -> save session, straight to the app
/// - profile_not_found   -> save session without identity; the profile gate
///                          runs onboarding with the email pre-filled
/// - backend unreachable -> stay logged out with a retriable inline error
///
/// Real auth later replaces the body of [signIn] (IdP token exchange) and
/// the session source — the states and call sites stay as they are.
class AuthNotifier extends StateNotifier<AuthState> {
  final ProfileApi _api;
  final LocalIdentityStore _identity;
  final Ref _ref;

  AuthNotifier(this._api, this._identity, this._ref)
    : super(const AuthState.restoring()) {
    _restore();
  }

  Future<void> _restore() async {
    final email = await _identity.readLoginEmail();
    final userId = await _identity.readUserId();
    if (!mounted) return;

    // Any persisted session marker (email from a login, or a userId from a
    // pre-login build) restores the session; the profile gate re-verifies
    // the identity against the backend as usual.
    if (email != null || userId != null) {
      state = AuthState(status: AuthStatus.loggedIn, email: email);
    } else {
      state = const AuthState(status: AuthStatus.loggedOut);
    }
  }

  /// Login with an email — the stub credential. Any provider button funnels
  /// here with a fabricated address.
  Future<void> signIn(String rawEmail) async {
    final email = normalizeEmail(rawEmail);
    if (email == null) {
      state = const AuthState(
        status: AuthStatus.loggedOut,
        errorMessage: "That email doesn't look right — mind checking it?",
      );
      return;
    }

    state = AuthState(status: AuthStatus.signingIn, email: email);

    try {
      final userId = await _api.resolveUserId(email: email);
      await _identity.saveUserId(userId);
    } on ProfileNotFoundException {
      // First-time login: no profile owns this email yet. Make sure no
      // stale identity survives so the gate routes into onboarding.
      await _identity.clearUserId();
    } on ProfileValidationException {
      if (!mounted) return;
      state = const AuthState(
        status: AuthStatus.loggedOut,
        errorMessage: "That email doesn't look right — mind checking it?",
      );
      return;
    } catch (_) {
      // Unreachable backend, 5xx, malformed response… login needs the
      // resolve round-trip, so surface a retriable error.
      if (!mounted) return;
      state = const AuthState(
        status: AuthStatus.loggedOut,
        errorMessage:
            "We couldn't reach the profile service to sign you in. "
            'If you run the app locally, start it with '
            'dev_setup_and_run.sh and try again.',
      );
      return;
    }

    await _identity.saveLoginEmail(email);
    if (!mounted) return;

    // Re-run the launch gate against the (possibly new) identity BEFORE
    // revealing it, so it never flashes a previous session's state.
    _ref.read(profileGateProvider.notifier).retry();
    state = AuthState(status: AuthStatus.loggedIn, email: email);
  }

  /// Clears the session and returns to the login screen. The next login
  /// re-resolves identity from the backend, so the same email lands back
  /// in the same profile.
  Future<void> signOut() async {
    await _identity.clearUserId();
    await _identity.clearLoginEmail();
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.loggedOut);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(profileApiProvider),
    ref.watch(localIdentityStoreProvider),
    ref,
  );
});
