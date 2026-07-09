import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GoogleServicesStore {
  static const String _calendarCredentialsKey = 'google_calendar_credentials';
  static const String _calendarConnectedKey = 'google_calendar_connected';
  static const String _lastOAuthStatusKey = 'google_oauth_last_status';
  static const String _lastOAuthErrorKey = 'google_oauth_last_error';

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
    await prefs.remove(_lastOAuthStatusKey);
    await prefs.remove(_lastOAuthErrorKey);
  }

  Future<String?> readLastOAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOAuthStatusKey);
  }

  Future<String?> readLastOAuthError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOAuthErrorKey);
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

    final normalizedFragment = fragment.startsWith('&')
        ? fragment.substring(1)
        : fragment;
    final params = Uri.splitQueryString(normalizedFragment);
    final status = params['google_oauth_status'];
    if (status != 'success') {
      final prefs = await SharedPreferences.getInstance();
      if (status != null) {
        await prefs.setString(_lastOAuthStatusKey, status);
      }
      final error = params['error'];
      if (error != null && error.isNotEmpty) {
        await prefs.setString(_lastOAuthErrorKey, error);
      }
      return false;
    }

    final service = params['google_oauth'];
    if (service == 'calendar' || service == 'all') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_calendarConnectedKey, true);
      await prefs.setString(_lastOAuthStatusKey, status!);
      await prefs.remove(_lastOAuthErrorKey);
      return true;
    }

    return false;
  }
}
