import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/call_model.dart';
import '../../data/datasources/ultravox_api.dart';
import '../../data/datasources/ultravox_rtc.dart';
import '../../data/datasources/backend_api.dart';
import '../../core/config/env_config.dart';

/// Call state
class CallState {
  final CallStatus status;
  final CallModel? call;
  final String? error;
  final bool isMuted;

  const CallState({
    this.status = CallStatus.idle,
    this.call,
    this.error,
    this.isMuted = false,
  });

  CallState copyWith({
    CallStatus? status,
    CallModel? call,
    String? error,
    bool? isMuted,
  }) {
    return CallState(
      status: status ?? this.status,
      call: call ?? this.call,
      error: error,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

enum CallStatus {
  idle,
  connecting,
  active,
  ended,
  error,
}

/// Call provider
class CallNotifier extends StateNotifier<CallState> {
  final UltravoxApi _api;
  final UltravoxRtcManager _rtc;
  final BackendApi _backend;

  CallNotifier(this._api, this._rtc, this._backend) : super(const CallState());

  /// Start a voice call
  Future<void> startCall() async {
    try {
      state = state.copyWith(status: CallStatus.connecting);

      // Create AHMA agent call with RAG tools
      final systemPrompt = _buildAhmaSystemPrompt();
      final tools = _buildAhmaTools();

      final call = await _api.createCall(
        systemPrompt: systemPrompt,
        tools: tools,
        metadata: {
          'app': 'ahma_flutter',
          'stage': 'assess',
        },
      );

      // Connect WebRTC
      await _rtc.connect(call.joinUrl);

      state = state.copyWith(
        status: CallStatus.active,
        call: call,
      );

      print('[Call] Started call: ${call.callId}');
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.error,
        error: e.toString(),
      );
      print('[Call] Error starting call: $e');
    }
  }

  /// End the call
  Future<void> endCall() async {
    if (state.call == null) return;

    try {
      // Get final transcript
      final messages = await _api.getCallMessages(state.call!.callId);

      // Disconnect WebRTC
      await _rtc.disconnect();

      // End call via API
      await _api.endCall(state.call!.callId);

      // Update state
      final updatedCall = state.call!.copyWith(transcript: messages);
      state = state.copyWith(
        status: CallStatus.ended,
        call: updatedCall,
      );

      // TODO: Send transcript to Flask backend
      await _sendTranscriptToBackend(updatedCall);

      print('[Call] Ended call: ${state.call!.callId}');
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.error,
        error: e.toString(),
      );
      print('[Call] Error ending call: $e');
    }
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    final newMuted = !state.isMuted;
    await _rtc.setMuted(newMuted);
    state = state.copyWith(isMuted: newMuted);
  }

  /// Build AHMA system prompt with stages
  String _buildAhmaSystemPrompt() {
    return '''
You are AHMA, a compassionate voice assistant for caregivers in Singapore.

Your conversation follows three stages:

STAGE 1 - ASSESS (Start here):
- Warmly greet the caregiver
- Ask how they're doing today
- Listen for signs of stress, exhaustion, or overwhelm
- Understand their current emotional state
- Classify stress level: REGULAR or ELEVATED

STAGE 2 - SUPPORT:
- Provide emotional support with empathy
- For ELEVATED stress: offer coping strategies, breathing exercises
- For REGULAR stress: provide information and guidance
- Use the queryCorpus tool to find relevant resources from Singapore caregiver guides
- IMPORTANT: When using queryCorpus, pass specific, focused queries like:
  - "respite care services for elderly caregivers"
  - "financial assistance for caregivers in Singapore"
  - "mental health support for family caregivers"
  - "caregiver stress management techniques"
- Keep responses concise and conversational

STAGE 3 - EVALUATE:
- Summarize the conversation
- Confirm resources provided
- End with encouragement
- Let them know they can reach out anytime

Important:
- Be warm, empathetic, and concise
- Focus on emotional support first, practical guidance second
- Don't overwhelm with too much information
- Keep responses short (2-3 sentences)
- Always use queryCorpus when caregiver needs specific information or resources
''';
  }

  /// Build AHMA tools (RAG corpus query)
  List<Map<String, dynamic>> _buildAhmaTools() {
    final corpusId = EnvConfig.corpusIdCaregiverGuides;

    return [
      {
        'toolName': 'queryCorpus',
        'parameterOverrides': {
          'corpus_id': corpusId,
          'max_results': 3,
        },
      },
    ];
  }

  /// Send transcript to Flask backend
  Future<void> _sendTranscriptToBackend(CallModel call) async {
    try {
      print('[Call] Sending transcript to backend: ${call.transcript.length} messages');

      // Determine stress level from metadata or default
      final stressLevel = state.call?.stage == CallStage.assess
          ? 'elevated' // If still in assess, might be elevated
          : 'regular';

      final result = await _backend.sendTranscript(
        callId: call.callId,
        userId: 'default_user', // TODO: Get from auth provider
        transcript: call.transcript,
        stressLevel: stressLevel,
        metadata: {
          'finalStage': call.stage.toString(),
        },
      );

      print('[Call] ✅ Backend response: ${result['message']}');
      if (result['actions'] != null) {
        print('[Call] 🎯 Actions taken: ${result['actions']}');
      }

    } catch (e) {
      print('[Call] ⚠️  Backend error (non-critical): $e');
      // Don't fail the call end if backend is unreachable
      // This allows testing without backend running
    }
  }
}

/// Provider
final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(
    UltravoxApi(),
    UltravoxRtcManager(
      onRemoteStream: (remoteTrack) {
        print('[Call] 🔊 Remote audio track received from AHMA');
        // Audio automatically plays through speakers via LiveKit
        // RemoteAudioTrack handles playback automatically
      },
    ),
    BackendApi(),
  );
});
