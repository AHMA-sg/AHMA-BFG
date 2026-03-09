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
      // Optimized timeouts for real-time voice (faster failure detection)
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
    ));

    // Add minimal logging (full logging causes lag on WSL2)
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,  // Disable body logging for performance
      responseBody: false, // Disable body logging for performance
      error: true,         // Only log errors
      logPrint: (obj) => print('[Ultravox API] $obj'),
    ));
  }

  /// Create a call with the AHMA agent
  Future<CallModel> createCall({
    String? agentId,
    String? systemPrompt,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? tools,
    List<Map<String, dynamic>>? initialMessages,
    Map<String, dynamic>? firstSpeakerSettings,
  }) async {
    try {
      // Use agent endpoint if agentId is provided
      final endpoint = agentId != null
          ? '${ApiConstants.agents}/$agentId/calls'
          : ApiConstants.calls;

      final data = {
        // Don't include agentId in body - it's in the URL path
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        if (metadata != null) 'metadata': metadata,
        if (initialMessages != null) 'initialMessages': initialMessages,
        if (firstSpeakerSettings != null) 'firstSpeakerSettings': firstSpeakerSettings,

        // Only include these for direct calls (no agentId)
        if (agentId == null) ...{
          'voice': 'Jessica',
          'temperature': 0.4,
          'model': 'ultravox-v0.7',
          if (tools != null) 'selectedTools': tools,
        },

        // Medium is required for all calls
        'medium': {
          'webRtc': {}
        },
      };

      final response = await _dio.post(
        endpoint,
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
