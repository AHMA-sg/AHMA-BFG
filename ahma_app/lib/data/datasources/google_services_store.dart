import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GoogleServicesStore {
  static const String _calendarCredentialsKey = 'google_calendar_credentials';
  static const String _calendarConnectedKey = 'google_calendar_connected';

  @Deprecated('Calendar credentials are now stored by the backend.')
  Future<Map<String, dynamic>?> readCalendarCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_calendarCredentialsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveCalendarCredentials(Map<String, dynamic> credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarCredentialsKey, jsonEncode(credentials));
  }

  Future<void> clearCalendarCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_calendarCredentialsKey);
    await prefs.remove(_calendarConnectedKey);
  }

  Future<bool> hasCalendarCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_calendarConnectedKey) == true ||
        (await readCalendarCredentials()) != null;
  }

  Future<bool> captureOAuthRedirectFromCurrentUrl() async {
    final fragment = Uri.base.fragment;
    if (fragment.isEmpty) {
      return false;
    }

    final params = Uri.splitQueryString(fragment);
    if (params['google_oauth_status'] != 'success') {
      return false;
    }

    final service = params['google_oauth'];
    if (service == 'calendar' || service == 'all') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_calendarConnectedKey, true);
      return true;
    }

    return false;
  }
}
