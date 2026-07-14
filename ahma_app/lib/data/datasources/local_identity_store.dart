import 'package:shared_preferences/shared_preferences.dart';

/// Device-local session for the profile lifecycle.
///
/// Keys:
/// - `session_token`: the OTP-issued JWT. Presence (and non-expiry) means "a
///   session exists"; every profile request carries it as a Bearer token.
/// - `token_expires_at`: ISO-8601 expiry of the JWT, used to short-circuit a
///   restore when the token is already stale.
/// - `profile_user_id`: the backend `userId` (== JWT `sub`). Written after a
///   confirmed verify (or a profile create), cleared on sign-out.
/// - `login_email`: the email used to sign in. Seeds onboarding's contact
///   question; cleared on sign-out.
class LocalIdentityStore {
  static const String userIdKey = 'profile_user_id';
  static const String loginEmailKey = 'login_email';
  static const String sessionTokenKey = 'session_token';
  static const String tokenExpiresAtKey = 'token_expires_at';

  Future<String?> readUserId() => _read(userIdKey);

  Future<void> saveUserId(String userId) => _write(userIdKey, userId);

  Future<void> clearUserId() => _clear(userIdKey);

  Future<String?> readLoginEmail() => _read(loginEmailKey);

  Future<void> saveLoginEmail(String email) => _write(loginEmailKey, email);

  Future<void> clearLoginEmail() => _clear(loginEmailKey);

  Future<String?> readToken() => _read(sessionTokenKey);

  Future<void> saveToken(String token) => _write(sessionTokenKey, token);

  Future<String?> readTokenExpiresAt() => _read(tokenExpiresAtKey);

  Future<void> saveTokenExpiresAt(String value) =>
      _write(tokenExpiresAtKey, value);

  /// Persist a freshly verified session in one shot.
  Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
    String? expiresAt,
  }) async {
    await saveToken(token);
    await saveUserId(userId);
    await saveLoginEmail(email);
    if (expiresAt != null && expiresAt.isNotEmpty) {
      await saveTokenExpiresAt(expiresAt);
    } else {
      await _clear(tokenExpiresAtKey);
    }
  }

  /// Wipe everything session-related. Used on sign-out and on a rejected token.
  Future<void> clearSession() async {
    await _clear(sessionTokenKey);
    await _clear(tokenExpiresAtKey);
    await _clear(userIdKey);
    await _clear(loginEmailKey);
  }

  Future<String?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
