import 'package:shared_preferences/shared_preferences.dart';

/// Device-local identity for the profile lifecycle.
///
/// A single documented key holds the client-generated UUIDv4 `userId`.
/// It is written ONLY after the backend confirms profile creation (201),
/// and cleared ONLY when the backend answers a JSON 404 `profile_not_found`.
///
/// This is a temporary local identity mechanism; production auth will later
/// replace the source of identity while keeping the same lifecycle shape.
class LocalIdentityStore {
  static const String userIdKey = 'profile_user_id';

  Future<String?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(userIdKey)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userId);
  }

  Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
  }
}
