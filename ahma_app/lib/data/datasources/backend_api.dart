import 'package:dio/dio.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/api_constants.dart';
import '../models/call_model.dart';

class BackendApi {
  late final Dio _dio;

  BackendApi() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvConfig.backendApiUrl,
      headers: {
        'Content-Type': 'application/json',
        if (EnvConfig.backendApiKey.isNotEmpty)
          'X-API-Key': EnvConfig.backendApiKey,
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[Backend API] $obj'),
    ));
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
        'transcript': transcript.map((m) => {
          'role': m.role,
          'text': m.text,
          'timestamp': (m.timestamp ?? DateTime.now()).toIso8601String(),
        }).toList(),
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
      final data = {
        'toolName': toolName,
        'parameters': parameters,
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
}
