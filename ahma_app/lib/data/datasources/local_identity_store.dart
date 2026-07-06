import 'package:shared_preferences/shared_preferences.dart';

/// Device-local session for the profile lifecycle.
///
/// Two documented keys:
/// - `profile_user_id`: the backend `userId`. Written after a confirmed
///   profile creation (201) or a successful login resolve, and cleared ONLY
///   when the backend answers a JSON 404 `profile_not_found` — or on logout.
/// - `login_email`: the email used at the stub login. Its presence means
///   "a session exists"; cleared on logout.
///
/// This is a temporary local session mechanism; production auth will later
/// replace the source of identity (IdP token) while keeping the same
/// lifecycle shape.
class LocalIdentityStore {
  static const String userIdKey = 'profile_user_id';
  static const String loginEmailKey = 'login_email';

  Future<String?> readUserId() => _read(userIdKey);

  Future<void> saveUserId(String userId) => _write(userIdKey, userId);

  Future<void> clearUserId() => _clear(userIdKey);

  Future<String?> readLoginEmail() => _read(loginEmailKey);

  Future<void> saveLoginEmail(String email) => _write(loginEmailKey, email);

  Future<void> clearLoginEmail() => _clear(loginEmailKey);

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
