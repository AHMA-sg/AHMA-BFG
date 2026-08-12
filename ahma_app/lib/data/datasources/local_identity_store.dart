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
/// - `login_email`: the verified sign-in email; cleared on sign-out.
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
    // why: restore treats the token as the session commit marker. Write it
    // last so a partial preferences failure cannot reveal a half-session.
    await saveUserId(userId);
    await saveLoginEmail(email);
    if (expiresAt != null && expiresAt.isNotEmpty) {
      await saveTokenExpiresAt(expiresAt);
    } else {
      await _clear(tokenExpiresAtKey);
    }
    await saveToken(token);
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
    final stored = await prefs.setString(key, value);
    if (!stored) throw StateError('Could not persist $key');
  }

  Future<void> _clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(key)) return;
    final removed = await prefs.remove(key);
    if (!removed) throw StateError('Could not clear $key');
  }
}
