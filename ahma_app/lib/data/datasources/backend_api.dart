import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/web_redirect.dart';
import '../models/call_model.dart';
import 'google_services_store.dart';

class BackendApi {
  late final Dio _dio;
  final GoogleServicesStore _googleStore = GoogleServicesStore();

  BackendApi() {
    final baseUrl = _resolveBaseUrl();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          if (EnvConfig.backendApiKey.isNotEmpty)
            'X-API-Key': EnvConfig.backendApiKey,
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[Backend API] $obj'),
      ),
    );
  }

  String _resolveBaseUrl() {
    final configuredUrl = EnvConfig.backendApiUrl.trim();

    if (!kIsWeb) {
      return configuredUrl;
    }

    final host = Uri.base.host;
    final isLocalPage = host == 'localhost' || host == '127.0.0.1';
    final isLocalBackend =
        configuredUrl.startsWith('http://localhost') ||
        configuredUrl.startsWith('http://127.0.0.1');

    if (!isLocalPage && isLocalBackend) {
      print(
        '[Backend API] Ignoring localhost BACKEND_API_URL on deployed web; using same-origin /api',
      );
      return '';
    }

    return configuredUrl;
  }

  Future<BackendHealthCheckResult> healthCheck() async {
    try {
      final path = _healthCheckPath();
      final response = await _dio.get(
        path,
        options: Options(
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final statusCode = response.statusCode;
      final ok = statusCode != null && statusCode >= 200 && statusCode < 300;

      return BackendHealthCheckResult(
        statusCode: statusCode,
        ok: ok,
        label: statusCode == null ? 'No response' : _labelForStatus(statusCode),
        detail: _detailFromResponse(response.data),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      return BackendHealthCheckResult(
        statusCode: statusCode,
        ok: false,
        label: statusCode == null
            ? 'Network error'
            : _labelForStatus(statusCode),
        detail: e.response?.data == null
            ? e.message
            : _detailFromResponse(e.response?.data),
      );
    } catch (e) {
      return BackendHealthCheckResult(
        ok: false,
        label: 'Unexpected error',
        detail: e.toString(),
      );
    }
  }

  String _healthCheckPath() {
    if (!kIsWeb) {
      return ApiConstants.backendHealth;
    }

    final host = Uri.base.host;
    final isLocalPage = host == 'localhost' || host == '127.0.0.1';
    final configuredUrl = EnvConfig.backendApiUrl.trim();
    final isLocalBackend =
        configuredUrl.startsWith('http://localhost') ||
        configuredUrl.startsWith('http://127.0.0.1');

    if (!isLocalPage && (configuredUrl.isEmpty || isLocalBackend)) {
      return '/api/backend-health';
    }

    return ApiConstants.backendHealth;
  }

  static String? _detailFromResponse(Object? data) {
    if (data == null) {
      return null;
    }

    String text;
    if (data is Map) {
      text = (data['message'] ?? data['error'] ?? data['status'] ?? data)
          .toString();
    } else {
      text = data.toString();
    }

    if (text.length > 160) {
      return '${text.substring(0, 160)}...';
    }

    return text;
  }

  static String _labelForStatus(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 202:
        return 'Accepted';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        if (statusCode >= 200 && statusCode < 300) {
          return 'OK';
        }
        if (statusCode >= 400 && statusCode < 500) {
          return 'Client Error';
        }
        if (statusCode >= 500) {
          return 'Server Error';
        }
        return 'HTTP Status';
    }
  }

  /// Create an Ultravox agent call through the backend/proxy.
  ///
  /// Flutter Web cannot reliably call Ultravox REST directly because browsers
  /// enforce CORS and would expose the API key. The backend owns the API key.
  Future<CallModel> createUltravoxCall({
    required String agentId,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? firstSpeakerSettings,
  }) async {
    try {
      final data = {
        if (metadata != null) 'metadata': metadata,
        if (firstSpeakerSettings != null)
          'firstSpeakerSettings': firstSpeakerSettings,
        'medium': {'webRtc': {}},
      };

      final response = await _dio.post(
        '/api/ultravox/agents/$agentId/calls',
        data: data,
      );

      return CallModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = _detailFromResponse(e.response?.data) ?? e.message;
      final message = [
        'Call proxy error',
        if (status != null) ' ($status)',
        if (detail != null && detail.isNotEmpty) ': $detail',
      ].join();
      print('Error creating proxied Ultravox call: $message');
      throw StateError(message);
    } catch (e) {
      print('Error creating proxied Ultravox call: $e');
      rethrow;
    }
  }

  Future<List<Message>> getUltravoxCallMessages(String callId) async {
    try {
      final response = await _dio.get('/api/ultravox/calls/$callId/messages');
      final results = response.data['results'] as List;
      return results.map((m) => Message.fromJson(m)).toList();
    } catch (e) {
      print('Error getting proxied Ultravox messages: $e');
      return [];
    }
  }

  Future<void> endUltravoxCall(String callId) async {
    try {
      await _dio.delete('/api/ultravox/calls/$callId');
    } catch (e) {
      print('Error ending proxied Ultravox call: $e');
    }
  }

  /// Send transcript to backend after call ends
  Future<Map<String, dynamic>> sendTranscript({
    required String callId,
    required String userId,
    required List<Message> transcript,
    required String stressLevel,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = {
        'callId': callId,
        'userId': userId,
        'transcript': transcript
            .map(
              (m) => {
                'role': m.role,
                'text': m.text,
                'timestamp': (m.timestamp ?? DateTime.now()).toIso8601String(),
              },
            )
            .toList(),
        'stressLevel': stressLevel,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _dio.post(
        ApiConstants.backendTranscript,
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error sending transcript: $e');
      rethrow;
    }
  }

  /// Send tool request to backend during call
  Future<Map<String, dynamic>> sendToolRequest({
    required String toolName,
    required Map<String, dynamic> parameters,
    String? callId,
  }) async {
    try {
      final toolParameters = Map<String, dynamic>.from(parameters);

      final data = {
        'toolName': toolName,
        'parameters': toolParameters,
        if (callId != null) 'callId': callId,
      };

      final response = await _dio.post(
        ApiConstants.backendToolRequest,
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error sending tool request: $e');
      rethrow;
    }
  }

  Future<void> startGoogleOAuth({
    required String service,
    required String userId,
  }) async {
    final returnUri = Uri.base.replace(fragment: '');
    final response = await _dio.post(
      ApiConstants.googleAuthUrl,
      data: {
        'service': service,
        'userId': userId,
        'returnUrl': returnUri.toString(),
      },
    );

    final authorizationUrl = response.data['authorizationUrl'] as String?;
    if (authorizationUrl == null || authorizationUrl.isEmpty) {
      throw StateError('Backend did not return a Google authorization URL.');
    }

    redirectToUrl(authorizationUrl);
  }

  Future<GoogleCalendarStatus> getCalendarStatus({
    required String userId,
  }) async {
    final response = await _dio.post(
      ApiConstants.googleCalendarStatus,
      data: {'userId': userId},
      options: Options(validateStatus: (_) => true),
    );

    final data = response.data as Map<String, dynamic>;
    final connected = data['connected'] == true;

    return GoogleCalendarStatus(
      connected: connected,
      message: data['message']?.toString() ?? data['error']?.toString(),
    );
  }

  Future<Map<String, dynamic>> createCalendarEvent({
    required String userId,
    required Map<String, dynamic> event,
  }) async {
    final response = await _dio.post(
      ApiConstants.googleCalendarEventsCreate,
      data: {'userId': userId, 'event': event},
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> disconnectCalendar({
    required String userId,
  }) async {
    final response = await _dio.post(
      ApiConstants.googleCalendarDisconnect,
      data: {'userId': userId},
    );
    await _googleStore.clearCalendarCredentials();
    return response.data as Map<String, dynamic>;
  }

  Future<GoogleGmailStatus> getGmailStatus() async {
    final response = await _dio.get(
      ApiConstants.googleGmailStatus,
      options: Options(validateStatus: (_) => true),
    );
    final data = response.data as Map<String, dynamic>;
    return GoogleGmailStatus(
      configured: data['configured'] == true,
      connected: data['connected'] == true,
      message: data['message']?.toString() ?? data['error']?.toString(),
    );
  }

  Future<Map<String, dynamic>> sendGmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    final response = await _dio.post(
      ApiConstants.googleGmailSend,
      data: {'to': to, 'subject': subject, 'body': body},
    );
    return response.data as Map<String, dynamic>;
  }
}

class BackendHealthCheckResult {
  final int? statusCode;
  final bool ok;
  final String label;
  final String? detail;

  const BackendHealthCheckResult({
    this.statusCode,
    required this.ok,
    required this.label,
    this.detail,
  });

  String get displayStatus {
    if (statusCode == null) {
      return label;
    }

    return '$statusCode $label';
  }
}

class GoogleCalendarStatus {
  final bool connected;
  final String? message;

  const GoogleCalendarStatus({required this.connected, this.message});
}

class GoogleGmailStatus {
  final bool configured;
  final bool connected;
  final String? message;

  const GoogleGmailStatus({
    required this.configured,
    required this.connected,
    this.message,
  });
}
