import 'dart:async';
import 'dart:convert';
import 'package:livekit_client/livekit_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/config/audio_config.dart';

/// WebRTC manager for Ultravox using LiveKit
class UltravoxRtcManager {
  Room? _room;
  WebSocketChannel? _signalingChannel;
  LocalAudioTrack? _localAudioTrack;
  EventsListener<RoomEvent>? _roomListener;

  final Function(String)? onMessage;
  final Function(RemoteAudioTrack)? onRemoteStream;

  UltravoxRtcManager({
    this.onMessage,
    this.onRemoteStream,
  });

  /// Connect to Ultravox call via LiveKit
  Future<void> connect(String joinUrl) async {
    try {
      print('[WebRTC] Connecting to: $joinUrl');

      // Connect to signaling to get LiveKit room info
      await _connectSignaling(joinUrl);

      print('[WebRTC] Connection setup complete');

    } catch (e) {
      print('[WebRTC] Connection error: $e');
      rethrow;
    }
  }

  /// Connect to Ultravox signaling via WebSocket
  Future<void> _connectSignaling(String joinUrl) async {
    try {
      // Convert HTTPS joinUrl to WSS
      final wsUrl = joinUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
      print('[WebRTC] Connecting to signaling: $wsUrl');

      _signalingChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for signaling messages (non-blocking to prevent queue buildup)
      _signalingChannel!.stream.listen(
        (message) {  // Removed async to avoid blocking stream
          print('[WebRTC] 📨 Received signaling message: $message');
          final data = jsonDecode(message);
          print('[WebRTC] 📨 Parsed message type: ${data['type']}');

          // Handle asynchronously without blocking stream
          _handleSignalingMessage(data).catchError((e) {
            print('[WebRTC] Error handling message: $e');
          });
        },
        onError: (error) {
          print('[WebRTC] Signaling error: $error');
        },
        onDone: () {
          print('[WebRTC] Signaling channel closed');
        },
      );

    } catch (e) {
      print('[WebRTC] Signaling error: $e');
      rethrow;
    }
  }

  /// Handle signaling messages from Ultravox
  Future<void> _handleSignalingMessage(Map<String, dynamic> message) async {
    try {
      final type = message['type'];

      if (type == 'room_info') {
        // Received LiveKit room info
        final roomUrl = message['roomUrl'] as String;
        final token = message['token'] as String;

        print('[WebRTC] Received LiveKit room info');
        print('[WebRTC] Room URL: $roomUrl');

        // Connect to LiveKit room
        await _connectToLiveKitRoom(roomUrl, token);

      } else {
        // Other message types
        if (onMessage != null) {
          onMessage!(jsonEncode(message));
        }
      }
    } catch (e) {
      print('[WebRTC] Error handling signaling message: $e');
    }
  }

  /// Connect to LiveKit room
  Future<void> _connectToLiveKitRoom(String roomUrl, String token) async {
    try {
      print('[LiveKit] Connecting to room: $roomUrl');

      // Create room with WSL2-compatible options
      _room = Room(
        roomOptions: const RoomOptions(
          // Disabled for WSL2 compatibility (requires network monitoring)
          adaptiveStream: false,
          dynacast: false,
          // Note: Audio options are applied when creating LocalAudioTrack below
        ),
      );

      // Set up event listeners ONCE
      _setupRoomEventListeners();

      // Connect to room
      await _room!.connect(roomUrl, token);

      print('[LiveKit] Connected to room');

      // Enable microphone and publish local audio (starts muted for PTT)
      await _enableMicrophone();

    } catch (e) {
      print('[LiveKit] Error connecting to room: $e');
      rethrow;
    }
  }

  /// Enable microphone and publish local audio track
  Future<void> _enableMicrophone() async {
    try {
      print('[LiveKit] Enabling microphone...');

      // Create local audio track with optimized settings
      _localAudioTrack = await LocalAudioTrack.create(
        AudioCaptureOptions(
          echoCancellation: AudioConfig.echoCancellation,
          noiseSuppression: AudioConfig.noiseSuppression,
          autoGainControl: AudioConfig.autoGainControl,
          // Note: LiveKit handles sample rate internally based on device capabilities
        ),
      );

      print('[LiveKit] Local audio track created');

      // Publish to room
      await _room!.localParticipant?.publishAudioTrack(_localAudioTrack!);
      print('[LiveKit] Published local audio track');

      // Start muted for Push-to-Talk mode
      await _localAudioTrack!.disable();
      print('[LiveKit] Started in muted state (PTT mode)');

    } catch (e) {
      print('[LiveKit] Error enabling microphone: $e');
    }
  }

  /// Set up LiveKit room event listeners (called once)
  void _setupRoomEventListeners() {
    if (_room == null) return;

    // Dispose any existing listener first
    _roomListener?.dispose();

    // Create event listener once
    _roomListener = _room!.createListener();

    // Listen for track subscribed events
    _roomListener!.on<TrackSubscribedEvent>((event) {
      print('[LiveKit] Track subscribed: ${event.track.kind}');

      if (event.track is RemoteAudioTrack) {
        final remoteAudioTrack = event.track as RemoteAudioTrack;
        print('[LiveKit] 🔊 Received remote audio track from ${event.participant.identity}');

        // Notify callback
        if (onRemoteStream != null) {
          onRemoteStream!(remoteAudioTrack);
        }
      }
    });

    // Listen for disconnection
    _roomListener!.on<RoomDisconnectedEvent>((event) {
      print('[LiveKit] Room disconnected: ${event.reason}');
    });

    // Listen for reconnection attempts
    _roomListener!.on<RoomReconnectingEvent>((event) {
      print('[LiveKit] Room reconnecting...');
    });

    // Listen for successful reconnection
    _roomListener!.on<RoomReconnectedEvent>((event) {
      print('[LiveKit] Room reconnected');
    });
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    print('[WebRTC] Disconnecting...');

    // Dispose event listener first
    await _roomListener?.dispose();
    _roomListener = null;

    // Close signaling channel
    await _signalingChannel?.sink.close();
    _signalingChannel = null;

    // Stop local audio track
    await _localAudioTrack?.stop();
    _localAudioTrack = null;

    // Disconnect and dispose room
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;

    print('[WebRTC] Disconnected and cleaned up');
  }

  /// Mute/unmute microphone
  Future<void> setMuted(bool muted) async {
    if (_localAudioTrack != null) {
      if (muted) {
        await _localAudioTrack!.disable();
      } else {
        await _localAudioTrack!.enable();
      }
      print('[WebRTC] Muted: $muted');
    }
  }

  /// Enable microphone (for Push-to-Talk)
  Future<void> enableMicrophone() async {
    if (_localAudioTrack != null) {
      await _localAudioTrack!.enable();
      print('[WebRTC] Microphone enabled (PTT pressed)');
    }
  }

  /// Disable microphone (for Push-to-Talk)
  Future<void> disableMicrophone() async {
    if (_localAudioTrack != null) {
      await _localAudioTrack!.disable();
      print('[WebRTC] Microphone disabled (PTT released)');
    }
  }

  bool get isConnected => _room != null && _room!.connectionState == ConnectionState.connected;
}
