import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/env_config.dart';
import '../models/profile_models.dart';

/// Base error for the profile API.
///
/// [ProfileNotFoundException] is thrown ONLY for an HTTP 404 whose JSON body
/// carries `error.code == "profile_not_found"`. Every other failure —
/// connection refused, timeout, 5xx, HTML/non-JSON 404, JSON parse failure —
/// surfaces as [ProfileApiUnavailableException] (or a specific typed error),
/// so callers never treat "backend down" as "profile deleted".
class ProfileApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  /// Backend field errors: dotted field path -> list of error codes
  /// (e.g. `{"careRecipient.displayName": ["required"]}`).
  final Map<String, List<String>> fieldErrors;

  const ProfileApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  @override
  String toString() => 'ProfileApiException($code, $statusCode): $message';
}

/// JSON 404 `profile_not_found` — the only signal that a profile truly
/// does not exist.
class ProfileNotFoundException extends ProfileApiException {
  const ProfileNotFoundException({super.statusCode})
    : super(code: 'profile_not_found', message: 'Profile not found.');
}

/// 400 `validation_error` with per-field detail.
class ProfileValidationException extends ProfileApiException {
  const ProfileValidationException({
    required super.message,
    super.statusCode,
    super.fieldErrors,
  }) : super(code: 'validation_error');
}

/// 409 `duplicate_user_id` — retried once with a fresh UUID by the caller.
class DuplicateUserIdException extends ProfileApiException {
  const DuplicateUserIdException({super.statusCode, super.fieldErrors})
    : super(
        code: 'duplicate_user_id',
        message: 'A profile already exists for that userId.',
      );
}

/// 409 `contact_already_exists` — email/phone already registered locally.
class ContactAlreadyExistsException extends ProfileApiException {
  const ContactAlreadyExistsException({super.statusCode, super.fieldErrors})
    : super(
        code: 'contact_already_exists',
        message: 'A profile already exists for that contact.',
      );
}

/// Network failure, timeout, 5xx, or a response that is not the profile
/// API's JSON envelope. Always non-destructive and retriable.
class ProfileApiUnavailableException extends ProfileApiException {
  const ProfileApiUnavailableException({super.statusCode, String? detail})
    : super(
        code: 'profile_api_unavailable',
        message: detail ?? 'Cannot reach the profile service.',
      );
}

/// 401 `unauthorized` — the Bearer token is missing, invalid, or expired.
/// The caller's signal that the session is stale and must be re-established.
class ProfileUnauthorizedException extends ProfileApiException {
  const ProfileUnauthorizedException({super.statusCode})
    : super(code: 'unauthorized', message: 'Session expired. Sign in again.');
}

/// Dio client for the AHMA profile API (backend_v2 on PROFILE_API_URL,
/// default http://localhost:5002). Separate from the legacy :5001 backend.
class ProfileApi {
  late final Dio _dio;

  /// Session-token source. When it yields a value, every request carries
  /// `Authorization: Bearer <token>`. The `/me` routes require it; `create`
  /// and `options` are open and tolerate its absence.
  final Future<String?> Function()? _bearerToken;

  ProfileApi({Dio? dio, Future<String?> Function()? bearerToken})
    : _bearerToken = bearerToken {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: EnvConfig.profileApiUrl,
            headers: {'Content-Type': 'application/json'},
            // Render's free tier can take 30-60 seconds to wake. Keep the
            // browser request alive long enough for that first response.
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 75),
            // Map HTTP errors ourselves so 4xx/5xx bodies stay inspectable.
            validateStatus: (_) => true,
          ),
        );

    if (_bearerToken != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await _bearerToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
        ),
      );
    }

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[Profile API] $obj'),
        ),
      );
    }
  }

  /// GET /api/profile/options
  Future<ProfileOptions> getOptions() async {
    final data = await _request(
      () => _dio.get('/api/profile/options'),
      expectedStatus: 200,
      retryOnTransientFailure: true,
    );
    final options = data['options'];
    if (options is! Map<String, dynamic>) {
      throw const ProfileApiUnavailableException(
        detail: 'Profile options response was malformed.',
      );
    }
    return ProfileOptions.fromJson(options);
  }

  /// POST /api/profile (create-only; 201 on success).
  Future<UserProfile> createProfile(ProfileCreateRequest request) async {
    final data = await _request(
      () => _dio.post('/api/profile', data: request.toJson()),
      expectedStatus: 201,
    );
    return _profileFrom(data);
  }

  /// GET /api/profile/me — the caller's own profile, resolved from the JWT
  /// `sub`. Requires a valid Bearer token (401 -> [ProfileUnauthorizedException]).
  Future<UserProfile> getMe() async {
    final data = await _request(
      () => _dio.get('/api/profile/me'),
      expectedStatus: 200,
      retryOnTransientFailure: true,
    );
    return _profileFrom(data);
  }

  /// PATCH /api/profile/me — partial update of the caller's own profile; only
  /// the fields set on [patch] change. Returns the full updated profile.
  Future<UserProfile> updateMe(ProfilePatchRequest patch) async {
    final data = await _request(
      () => _dio.patch('/api/profile/me', data: patch.toJson()),
      expectedStatus: 200,
    );
    return _profileFrom(data);
  }

  /// GET /api/profile/me/context — compact call-time context for the caller.
  Future<ProfileContextData> getMeContext() async {
    final data = await _request(
      () => _dio.get('/api/profile/me/context'),
      expectedStatus: 200,
      retryOnTransientFailure: true,
    );
    final context = data['profileContext'];
    if (context is! Map<String, dynamic>) {
      throw const ProfileApiUnavailableException(
        detail: 'Profile context response was malformed.',
      );
    }
    return ProfileContextData.fromJson(context);
  }

  UserProfile _profileFrom(Map<String, dynamic> data) {
    final profile = data['profile'];
    if (profile is! Map<String, dynamic>) {
      throw const ProfileApiUnavailableException(
        detail: 'Profile response was malformed.',
      );
    }
    return UserProfile.fromJson(profile);
  }

  /// Runs a request and returns the success envelope, or throws a typed
  /// [ProfileApiException].
  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() send, {
    required int expectedStatus,
    bool retryOnTransientFailure = false,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      Response<dynamic> response;
      try {
        response = await send();
      } on DioException catch (e) {
        if (retryOnTransientFailure && attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        throw ProfileApiUnavailableException(
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

      if (retryOnTransientFailure &&
          attempt == 0 &&
          const {502, 503, 504}.contains(status)) {
        await Future<void>.delayed(const Duration(seconds: 1));
        continue;
      }

      throw _errorFrom(status, data);
    }

    throw const ProfileApiUnavailableException();
  }

  ProfileApiException _errorFrom(int? status, Object? data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (data['success'] == false && error is Map<String, dynamic>) {
        final code = error['code']?.toString() ?? '';
        final message =
            error['message']?.toString() ?? 'Profile request failed.';
        final fields = _parseFields(error['fields']);

        switch (code) {
          case 'profile_not_found':
            return ProfileNotFoundException(statusCode: status);
          case 'unauthorized':
            return ProfileUnauthorizedException(statusCode: status);
          case 'validation_error':
            return ProfileValidationException(
              message: message,
              statusCode: status,
              fieldErrors: fields,
            );
          case 'duplicate_user_id':
            return DuplicateUserIdException(
              statusCode: status,
              fieldErrors: fields,
            );
          case 'contact_already_exists':
            return ContactAlreadyExistsException(
              statusCode: status,
              fieldErrors: fields,
            );
          default:
            return ProfileApiException(
              code: code.isEmpty ? 'unknown_error' : code,
              message: message,
              statusCode: status,
              fieldErrors: fields,
            );
        }
      }
    }

    // Non-JSON body (e.g. an HTML 404 from something else on this port),
    // 5xx, or an envelope we don't recognize: unavailable, never destructive.
    return ProfileApiUnavailableException(
      statusCode: status,
      detail: status == null
          ? 'No response from the profile service.'
          : 'Unexpected response ($status) from the profile service.',
    );
  }

  static Map<String, List<String>> _parseFields(Object? raw) {
    if (raw is! Map<String, dynamic>) return const {};
    final fields = <String, List<String>>{};
    raw.forEach((path, codes) {
      if (codes is List) {
        fields[path] = codes.map((c) => c.toString()).toList();
      }
    });
    return fields;
  }
}
