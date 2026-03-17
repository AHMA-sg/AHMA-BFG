import 'package:dio/dio.dart';
import '../models/call_model.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/api_constants.dart';

class UltravoxApi {
  late final Dio _dio;

  UltravoxApi() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvConfig.ultravoxBaseUrl,
      headers: {
        'X-API-Key': EnvConfig.ultravoxApiKey,
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[Ultravox API] $obj'),
    ));
  }

  /// Create a call with the AHMA agent
  Future<CallModel> createCall({
    String? agentId,
    String? systemPrompt,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? tools,
  }) async {
    try {
      final data = {
        if (agentId != null) 'agentId': agentId,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        'voice': 'Jessica', // Warm female voice
        'temperature': 0.4, // Consistent responses
        'model': 'ultravox-v0.7',
        'medium': {
          'webRtc': {}
        },
        if (tools != null) 'selectedTools': tools,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _dio.post(
        ApiConstants.calls,
        data: data,
      );

      return CallModel.fromJson(response.data);
    } catch (e) {
      print('Error creating call: $e');
      rethrow;
    }
  }

  /// Get call transcript (messages)
  Future<List<Message>> getCallMessages(String callId) async {
    try {
      final response = await _dio.get('${ApiConstants.calls}/$callId/messages');
      // API returns paginated response: {"results": [...], "total": N}
      final results = response.data['results'] as List;
      return results.map((m) => Message.fromJson(m)).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  /// End a call
  Future<void> endCall(String callId) async {
    try {
      await _dio.delete('${ApiConstants.calls}/$callId');
    } catch (e) {
      print('Error ending call: $e');
    }
  }
}
