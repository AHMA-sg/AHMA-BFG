/// Client-side contact normalization shared by the login and account
/// screens (mirrors the onboarding rules, R16): emails are lowercased,
/// bare 8-digit phone numbers get the +65 Singapore prefix so backend
/// normalization can't silently store a wrong country code.
library;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _phonePattern = RegExp(r'^\+[1-9]\d{7,14}$');

/// Returns the normalized (lowercased) email, or null when [input] is not a
/// plausible email address.
String? normalizeEmail(String input) {
  final trimmed = input.trim();
  if (!_emailPattern.hasMatch(trimmed)) return null;
  return trimmed.toLowerCase();
}

/// Returns the normalized E.164-ish phone (+65 assumed for bare 8-digit
/// numbers), or null when [input] is not a plausible phone number.
String? normalizePhone(String input) {
  var compact = input.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (RegExp(r'^\d{8}$').hasMatch(compact)) {
    compact = '+65$compact';
  }
  if (!_phonePattern.hasMatch(compact)) return null;
  return compact;
}
