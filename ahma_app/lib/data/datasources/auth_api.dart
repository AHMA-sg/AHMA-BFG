import 'package:dio/dio.dart';

import '../../core/config/env_config.dart';

/// Result of proving ownership of an email address.
sealed class AuthVerification {
  final String? expiresAt;

  const AuthVerification({this.expiresAt});
}

/// An existing account session returned by `POST /api/auth/verify`.
class AuthSession extends AuthVerification {
  final String token;
  final String userId;

  const AuthSession({
    required this.token,
    required this.userId,
    super.expiresAt,
  });
}

/// Short-lived authority to create a profile for a newly verified email.
class SignupAuthorization extends AuthVerification {
  final String token;

  const SignupAuthorization({required this.token, super.expiresAt});
}

/// Base error for the auth API.
class AuthApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const AuthApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'AuthApiException($code, $statusCode): $message';
}

/// 401 `invalid_code` - wrong or expired verification code.
class InvalidCodeException extends AuthApiException {
  const InvalidCodeException({super.statusCode})
    : super(
        code: 'invalid_code',
        message: 'Invalid or expired verification code.',
      );
}

/// 400 `validation_error` — e.g. a malformed email.
class AuthValidationException extends AuthApiException {
  const AuthValidationException({required super.message, super.statusCode})
    : super(code: 'validation_error');
}

/// 429 `rate_limited` — too many codes requested.
class AuthRateLimitedException extends AuthApiException {
  const AuthRateLimitedException({super.statusCode})
    : super(
        code: 'rate_limited',
        message: 'Too many verification codes requested. Try again in a bit.',
      );
}

/// Network failure, timeout, 5xx, 503 (email/config), or a non-envelope body.
class AuthApiUnavailableException extends AuthApiException {
  const AuthApiUnavailableException({super.statusCode, String? detail})
    : super(
        code: 'auth_api_unavailable',
        message: detail ?? 'Cannot reach the sign-in service.',
      );
}

/// Dio client for the AHMA OTP auth endpoints (backend_v2, PROFILE_API_URL).
/// Requests are unauthenticated — the JWT is the *result* of verify.
class AuthApi {
  late final Dio _dio;

  AuthApi({Dio? dio}) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: EnvConfig.profileApiUrl,
            headers: {'Content-Type': 'application/json'},
            // The auth API shares the free Render service with profiles, so
            // the first request must tolerate a 30-60 second cold start.
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 75),
            validateStatus: (_) => true,
          ),
        );

    // why: auth requests and responses contain OTPs and bearer credentials;
    // logging them would make debug output sufficient to replay a session.
  }

  /// POST /api/auth/request-code — emails a 6-digit code to any valid [email].
  Future<void> requestCode(String email) async {
    await _request(
      () => _dio.post('/api/auth/request-code', data: {'email': email}),
      expectedStatus: 200,
    );
  }

  /// POST /api/auth/verify — proves email ownership, then returns either an
  /// existing-account session or authority to finish first-time onboarding.
  ///
  /// Throws [InvalidCodeException] on a wrong/expired code.
  Future<AuthVerification> verifyCode(String email, String code) async {
    final data = await _request(
      () => _dio.post('/api/auth/verify', data: {'email': email, 'code': code}),
      expectedStatus: 200,
    );

    final next = data['next'];
    final expiresAt = data['expiresAt'];
    if (next == 'onboarding') {
      final signupToken = data['signupToken'];
      if (signupToken is String && signupToken.isNotEmpty) {
        return SignupAuthorization(
          token: signupToken,
          expiresAt: expiresAt is String ? expiresAt : null,
        );
      }
    } else if (next == 'session') {
      final token = data['token'];
      final userId = data['userId'];
      if (token is String &&
          token.isNotEmpty &&
          userId is String &&
          userId.isNotEmpty) {
        return AuthSession(
          token: token,
          userId: userId,
          expiresAt: expiresAt is String ? expiresAt : null,
        );
      }
    }

    throw const AuthApiUnavailableException(
      detail: 'Verification response was malformed.',
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() send, {
    required int expectedStatus,
  }) async {
    Response<dynamic> response;
    try {
      response = await send();
    } on DioException catch (e) {
      throw AuthApiUnavailableException(
        statusCode: e.response?.statusCode,
        detail: e.message,
      );
    }

    final status = response.statusCode;
    final data = response.data;

    if (status == expectedStatus &&
        data is Map<String, dynamic> &&
        data['success'] == true) {
      return data;
    }

    throw _errorFrom(status, data);
  }

  AuthApiException _errorFrom(int? status, Object? data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (data['success'] == false && error is Map<String, dynamic>) {
        final code = error['code']?.toString() ?? '';
        final message =
            error['message']?.toString() ?? 'Sign-in request failed.';

        switch (code) {
          case 'invalid_code':
            return InvalidCodeException(statusCode: status);
          case 'validation_error':
            return AuthValidationException(
              message: message,
              statusCode: status,
            );
          case 'rate_limited':
            return AuthRateLimitedException(statusCode: status);
          default:
            // email_send_failed, auth_not_configured, unknown -> unavailable.
            return AuthApiUnavailableException(
              statusCode: status,
              detail: message,
            );
        }
      }
    }

    return AuthApiUnavailableException(
      statusCode: status,
      detail: status == null
          ? 'No response from the sign-in service.'
          : 'Unexpected response ($status) from the sign-in service.',
    );
  }
}
