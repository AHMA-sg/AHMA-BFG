import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/call_model.dart';
import '../../data/models/action_plan.dart';
import '../../data/datasources/ultravox_api.dart';
import '../../data/datasources/ultravox_rtc.dart';
import '../../data/datasources/backend_api.dart';
import '../../core/config/env_config.dart';
import 'backend_provider.dart';

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

enum CallStatus { idle, connecting, active, ended, error }

/// Call provider
class CallNotifier extends StateNotifier<CallState> {
  final UltravoxApi _api;
  final UltravoxRtcManager _rtc;
  final BackendApi _backend;
  final Future<void> Function(BackendUpdate update) _processBackendUpdate;

  CallNotifier(this._api, this._rtc, this._backend, this._processBackendUpdate)
    : super(const CallState());

  /// Start a voice call
  Future<void> startCall({
    String? userName,
    String? careRecipientName,
    String? caregiverType,
  }) async {
    try {
      state = state.copyWith(status: CallStatus.connecting);

      // Use pre-created AHMA agent (faster call setup)
      final agentId = EnvConfig.ahmaAgentId;

      // Build personalized greeting with context embedded
      final greeting = _buildPersonalizedGreeting(
        userName,
        careRecipientName,
        caregiverType,
      );

      final call = await _api.createCall(
        agentId: agentId,
        metadata: {
          'app': 'ahma_flutter',
          'stage': 'assess',
          if (userName != null) 'userName': userName,
          if (careRecipientName != null) 'careRecipientName': careRecipientName,
          if (caregiverType != null) 'caregiverType': caregiverType,
        },
        firstSpeakerSettings: {
          'agent': {'text': greeting},
        },
        // Note: initialMessages is for conversation history (USER/AGENT messages)
        // Context is passed via greeting and metadata instead
      );

      // Connect WebRTC
      await _rtc.connect(call.joinUrl);

      state = state.copyWith(status: CallStatus.active, call: call);

      print('[Call] Started call: ${call.callId}');
      if (userName != null) {
        print('[Call] 👤 User: $userName');
      }
    } catch (e) {
      state = state.copyWith(status: CallStatus.error, error: e.toString());
      print('[Call] Error starting call: $e');
    }
  }

  /// Build personalized greeting with embedded context
  String _buildPersonalizedGreeting(
    String? userName,
    String? careRecipientName,
    String? caregiverType,
  ) {
    if (userName != null && careRecipientName != null) {
      // Full context greeting
      return 'Hello $userName, this is AHMA. I understand you\'re caring for your $careRecipientName. How are you doing today?';
    } else if (userName != null) {
      // Name only
      return 'Hello $userName, this is AHMA. How are you doing today?';
    } else {
      // Generic greeting
      return 'Hello, this is AHMA. How are you doing today?';
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
      state = state.copyWith(status: CallStatus.ended, call: updatedCall);

      // TODO: Send transcript to Flask backend
      await _sendTranscriptToBackend(updatedCall);

      print('[Call] Ended call: ${state.call!.callId}');
    } catch (e) {
      state = state.copyWith(status: CallStatus.error, error: e.toString());
      print('[Call] Error ending call: $e');
    }
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    final newMuted = !state.isMuted;
    await _rtc.setMuted(newMuted);
    state = state.copyWith(isMuted: newMuted);
  }

  /// Start audio capture (PTT pressed)
  void startAudioCapture() {
    try {
      print('[Call] 🎤 Starting audio capture (PTT pressed)');

      // Check if WebRTC is connected
      if (!_rtc.isConnected) {
        print('[Call] ⚠️  WebRTC not connected, cannot start audio capture');
        return;
      }

      // Use muting instead of enable/disable for better performance
      _rtc.setMuted(false);
      state = state.copyWith(isMuted: false);
      print('[Call] ✅ Audio unmuted (PTT pressed)');
    } catch (e) {
      print('[Call] ❌ Error starting audio capture: $e');
    }
  }

  /// Stop audio capture (PTT released)
  void stopAudioCapture() {
    try {
      print('[Call] 🎤 Stopping audio capture (PTT released)');

      // Use muting instead of enable/disable for better performance
      _rtc.setMuted(true);
      state = state.copyWith(isMuted: true);
      print('[Call] ✅ Audio muted (PTT released)');
    } catch (e) {
      print('[Call] ❌ Error stopping audio capture: $e');
    }
  }

  // Note: Tools are now configured in the pre-created agent (AHMA_AGENT_ID)
  // No need to build tools on every call - saves latency!

  /// Send transcript to Flask backend
  Future<void> _sendTranscriptToBackend(CallModel call) async {
    try {
      print(
        '[Call] Sending transcript to backend: ${call.transcript.length} messages',
      );

      // Determine stress level from metadata or default
      final stressLevel = state.call?.stage == CallStage.assess
          ? 'elevated' // If still in assess, might be elevated
          : 'regular';

      final result = await _backend.sendTranscript(
        callId: call.callId,
        userId: 'default_user', // TODO: Get from auth provider
        transcript: call.transcript,
        stressLevel: stressLevel,
        metadata: {'finalStage': call.stage.toString()},
      );

      print('[Call] ✅ Backend response: ${result['message']}');
      final updateJson = result['update'];
      if (updateJson is Map<String, dynamic>) {
        await _processBackendUpdate(BackendUpdate.fromJson(updateJson));
        print('[Call] ✅ Action plan update processed from backend response');
      }

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
    (update) => ref.read(backendProvider.notifier).processUpdate(update),
  );
});
