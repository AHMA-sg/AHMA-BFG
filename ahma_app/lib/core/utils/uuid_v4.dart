import 'dart:math';

/// Generates a random RFC 4122 version-4 UUID in lowercase canonical form
/// (e.g. `3f2a1b4c-9d8e-4f7a-b6c5-d4e3f2a1b0c9`).
///
/// The profile backend requires the client-supplied `userId` to be a
/// lowercase canonical UUIDv4, so keep this exact formatting.
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  // Set version (4) and RFC 4122 variant bits.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
