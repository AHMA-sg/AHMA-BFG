import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/contact_format.dart';
import '../../data/datasources/auth_api.dart';
import '../../data/datasources/local_identity_store.dart';
import '../../data/datasources/profile_api.dart';
import 'profile_provider.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

/// Where the app is in the OTP auth lifecycle.
enum AuthStatus {
  /// Reading the persisted session at cold start.
  restoring,

  /// No session — show the login screen.
  loggedOut,

  /// A sign-in code request is in flight.
  requestingCode,

  /// A code has been requested — show the code-entry screen.
  awaitingCode,

  /// A code is being verified.
  verifying,

  /// First-time user is filling out their profile (pre-session).
  onboarding,

  /// Session established (JWT stored) — hand off to the profile gate.
  loggedIn,
}

class AuthState {
  final AuthStatus status;
  final int quoteSessionSeed;

  /// The verified email that identifies the account or new profile.
  final String? email;

  /// Inline error for the current screen, or null.
  final String? errorMessage;

  /// Neutral guidance for the current verification attempt, or null.
  final String? infoMessage;

  /// Short-lived authority to create a profile for [email]. Memory-only.
  final String? signupToken;

  const AuthState({
    required this.status,
    this.quoteSessionSeed = 0,
    this.email,
    this.errorMessage,
    this.infoMessage,
    this.signupToken,
  });

  const AuthState.restoring() : this(status: AuthStatus.restoring);
}

/// Unified OTP email auth:
///
/// - Every user: [requestCode] -> [verifyCode].
/// - Returning user: verification yields a session JWT.
/// - New user: verification yields signup authority -> onboarding creates the
///   profile -> [completeOnboarding] stores the returned session JWT.
///
/// The verified JWT is the session; `/me` resolves identity from it, so there
/// is no id-in-path and no IDOR surface.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _api;
  final LocalIdentityStore _identity;
  final Ref _ref;

  AuthNotifier(this._api, this._identity, this._ref)
    : super(const AuthState.restoring()) {
    _restore();
  }

  Future<void> _restore() async {
    final token = await _identity.readToken();
    if (!mounted) return;

    if (token == null || _isExpired(await _identity.readTokenExpiresAt())) {
      // No token, or a stale one: start clean so no half-session lingers.
      if (token != null) await _identity.clearSession();
      if (!mounted) return;
      state = const AuthState(status: AuthStatus.loggedOut);
      return;
    }

    // A live token is the normal restore path; the profile gate verifies it
    // against `/me` and signs out if the backend rejects it.
    final email = await _identity.readLoginEmail();
    if (!mounted) return;
    state = AuthState(
      status: AuthStatus.loggedIn,
      email: email,
      quoteSessionSeed: token.hashCode,
    );
  }

  /// Request a verification code for [rawEmail]. Moves to code entry on
  /// success. [infoMessage] carries neutral context such as resend guidance.
  Future<void> requestCode(String rawEmail, {String? infoMessage}) async {
    final email = normalizeEmail(rawEmail);
    if (email == null) {
      state = AuthState(
        status: AuthStatus.loggedOut,
        email: state.email,
        errorMessage: "That email doesn't look right — mind checking it?",
      );
      return;
    }

    state = AuthState(status: AuthStatus.requestingCode, email: email);

    try {
      await _api.requestCode(email);
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.awaitingCode,
        email: email,
        infoMessage: infoMessage,
      );
    } on AuthValidationException {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.loggedOut,
        email: email,
        errorMessage: "That email doesn't look right — mind checking it?",
      );
    } on AuthRateLimitedException {
      // They may already hold a valid earlier code — let them enter it.
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.awaitingCode,
        email: email,
        infoMessage:
            'You have requested a few codes. Enter the latest one, or wait '
            'a bit before asking for another.',
      );
    } catch (_) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.loggedOut,
        email: email,
        errorMessage:
            "We couldn't reach the sign-in service. "
            'It may still be waking up, so please try again in a moment.',
      );
    }
  }

  /// Re-send a code to the email already in flight.
  Future<void> resendCode() async {
    final email = state.email;
    if (email == null) {
      state = const AuthState(status: AuthStatus.loggedOut);
      return;
    }
    await requestCode(email, infoMessage: 'A new code is on its way.');
  }

  /// Verify [rawCode], then route to an existing session or onboarding.
  Future<void> verifyCode(String rawCode) async {
    final email = state.email;
    if (email == null) {
      state = const AuthState(status: AuthStatus.loggedOut);
      return;
    }

    final code = rawCode.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      state = AuthState(
        status: AuthStatus.awaitingCode,
        email: email,
        errorMessage: 'Enter the 6-digit code we emailed you.',
      );
      return;
    }

    state = AuthState(status: AuthStatus.verifying, email: email);

    try {
      final verification = await _api.verifyCode(email, code);
      if (verification is SignupAuthorization) {
        if (!mounted) return;
        state = AuthState(
          status: AuthStatus.onboarding,
          email: email,
          signupToken: verification.token,
        );
      } else if (verification is AuthSession) {
        try {
          await _saveSession(verification, email);
        } catch (_) {
          if (!mounted) return;
          state = AuthState(
            status: AuthStatus.loggedOut,
            email: email,
            errorMessage:
                "You're verified, but we couldn't save your session on this "
                'device. Request a new code and try again.',
          );
        }
      }
    } on InvalidCodeException {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.awaitingCode,
        email: email,
        errorMessage: "That code didn't work — check it or request a new one.",
      );
    } catch (_) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.awaitingCode,
        email: email,
        errorMessage:
            "We couldn't reach the sign-in service. Try that code again in "
            'a moment.',
      );
    }
  }

  Future<void> completeOnboarding(ProfileCreationResult result) async {
    final email = state.email;
    if (email == null || state.status != AuthStatus.onboarding) return;
    await _saveSession(
      AuthSession(
        token: result.token,
        userId: result.userId,
        expiresAt: result.expiresAt,
      ),
      email,
    );
  }

  void signupExpired() {
    state = AuthState(
      status: AuthStatus.loggedOut,
      email: state.email,
      errorMessage:
          'Your verification expired. Request a new code to continue.',
    );
  }

  /// Abandon signup / code entry and return to the login screen.
  void backToLogin() {
    state = AuthState(status: AuthStatus.loggedOut, email: state.email);
  }

  /// Clears the session and returns to the login screen.
  Future<void> signOut() async {
    await _identity.clearSession();
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.loggedOut);
  }

  Future<void> _saveSession(AuthSession session, String email) async {
    await _identity.saveSession(
      token: session.token,
      userId: session.userId,
      email: email,
      expiresAt: session.expiresAt,
    );
    if (!mounted) return;
    // Re-run the launch gate against the new session BEFORE revealing it.
    _ref.read(profileGateProvider.notifier).retry();
    state = AuthState(
      status: AuthStatus.loggedIn,
      email: email,
      quoteSessionSeed: session.token.hashCode,
    );
  }

  static bool _isExpired(String? iso) {
    if (iso == null || iso.isEmpty) return false;
    final expiry = DateTime.tryParse(iso);
    if (expiry == null) return false;
    return expiry.toUtc().isBefore(DateTime.now().toUtc());
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authApiProvider),
    ref.watch(localIdentityStoreProvider),
    ref,
  );
});
