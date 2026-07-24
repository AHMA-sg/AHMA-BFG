import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/contact_format.dart';
import '../../data/datasources/auth_api.dart';
import '../../data/datasources/local_identity_store.dart';
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

  /// The email the code was sent to. Seeds onboarding's contact question and
  /// is the subject the code verifies against.
  final String? email;

  /// Inline error for the current screen, or null.
  final String? errorMessage;

  /// Neutral guidance (e.g. "profile created, enter your code"), or null.
  final String? infoMessage;

  const AuthState({
    required this.status,
    this.quoteSessionSeed = 0,
    this.email,
    this.errorMessage,
    this.infoMessage,
  });

  const AuthState.restoring() : this(status: AuthStatus.restoring);
}

/// OTP email auth. The flow the backend forces:
///
/// - Returning user: [requestCode] -> code emailed -> [verifyCode] -> JWT.
/// - New user: [startSignup] -> onboarding creates the profile (open) ->
///   [completeSignup] emails a code for that now-existing account ->
///   [verifyCode] -> JWT whose `sub` matches the created profile.
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

  /// Request a sign-in code for [rawEmail]. Moves to the code-entry screen on
  /// success. [infoMessage] carries neutral context (e.g. after signup).
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
    await requestCode(
      email,
      infoMessage:
          'If an account exists for this email, a new code is on its way.',
    );
  }

  /// Exchange the entered [rawCode] for a session JWT.
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
      final session = await _api.verifyCode(email, code);
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

  /// Enter the first-time signup flow (conversational onboarding). No session
  /// exists yet — onboarding creates the profile, then [completeSignup] runs.
  void startSignup() {
    state = AuthState(status: AuthStatus.onboarding, email: state.email);
  }

  /// Called by onboarding after a confirmed profile create. The account now
  /// exists, so a code CAN be emailed; route into verification.
  Future<void> completeSignup(String? email) async {
    if (email == null || email.trim().isEmpty) {
      // Phone-only signup: OTP is email-based, so there is nothing to send.
      state = const AuthState(
        status: AuthStatus.loggedOut,
        errorMessage:
            'Add an email to your profile to receive a sign-in code. '
            'Phone-only sign-in is coming soon.',
      );
      return;
    }
    await requestCode(
      email,
      infoMessage:
          "Your profile is ready. Enter the code we just emailed to finish "
          'signing in.',
    );
  }

  /// The entered contact already has an account (create returned a conflict):
  /// route them to sign in with a code instead of creating a duplicate.
  Future<void> signInExisting(String? email) async {
    if (email == null || email.trim().isEmpty) {
      state = const AuthState(
        status: AuthStatus.loggedOut,
        errorMessage:
            'That contact is already registered. Sign in with the email on '
            'that account.',
      );
      return;
    }
    await requestCode(
      email,
      infoMessage:
          "You already have an account. Enter the code we just emailed to "
          'sign in.',
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
