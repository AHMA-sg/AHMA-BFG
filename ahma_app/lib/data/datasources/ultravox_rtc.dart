import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:livekit_client/livekit_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config/audio_config.dart';
import '../models/navigate_tool.dart';
import '../models/client_tool_result.dart';

/// WebRTC manager for Ultravox using LiveKit
class UltravoxRtcManager {
  Room? _room;
  WebSocketChannel? _signalingChannel;
  LocalAudioTrack? _localAudioTrack;
  EventsListener<RoomEvent>? _roomListener;

  final Function(String)? onMessage;
  final Function(RemoteAudioTrack)? onRemoteStream;
  final Function(Map<String, dynamic>)? onToolCall;

  UltravoxRtcManager({this.onMessage, this.onRemoteStream, this.onToolCall});

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
      final wsUrl = joinUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      print('[WebRTC] Connecting to signaling: $wsUrl');

      _signalingChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for signaling messages (non-blocking to prevent queue buildup)
      _signalingChannel!.stream.listen(
        (message) {
          // Removed async to avoid blocking stream
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
      print('[WebRTC] 📨 Signaling message type: $type');

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
        print('[WebRTC] ℹ️  Other message type: $type');
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

      // Check if microphone permission is granted
      try {
        final permissionStatus = await Permission.microphone.status;
        print('[LiveKit] Microphone permission status: $permissionStatus');

        if (permissionStatus.isDenied) {
          final status = await Permission.microphone.request();
          print('[LiveKit] Microphone permission requested: $status');
          if (status.isDenied) {
            throw Exception('Microphone permission denied');
          }
        }
      } catch (e) {
        print('[LiveKit] Permission handler not available: $e');
        print('[LiveKit] Note: LiveKit will handle permissions internally');
        // Continue without permission_handler - LiveKit will handle permissions
      }

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

      // Check if track is properly created
      if (_localAudioTrack == null) {
        throw Exception('Failed to create local audio track');
      }

      // Publish to room
      await _room!.localParticipant?.publishAudioTrack(_localAudioTrack!);
      print('[LiveKit] Published local audio track');

      // Start muted for Push-to-Talk mode
      await _localAudioTrack!.disable();
      print('[LiveKit] Started in muted state (PTT mode)');

      // Verify track is published
      print('[LiveKit] Local audio track published successfully');
    } catch (e) {
      print('[LiveKit] Error enabling microphone: $e');
      rethrow;
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
        print(
          '[LiveKit] 🔊 Received remote audio track from ${event.participant.identity}',
        );

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

    // Listen for data messages (tool calls come through LiveKit data channel)
    _roomListener!.on<DataReceivedEvent>((event) {
      print('[LiveKit] 📨 Data received: ${event.data}');
      try {
        final dataString = String.fromCharCodes(event.data);
        print('[LiveKit] 📝 Decoded data: $dataString');
        final data = jsonDecode(dataString);

        print('[LiveKit] 🔍 Data type check: ${data['type']}');
        print('[LiveKit] 🔍 Available keys: ${data.keys.toList()}');

        if (data['type'] == 'client_tool_invocation') {
          print('[LiveKit] 🔧 Client tool invocation received');
          _handleClientToolInvocation(data);
        } else {
          print('[LiveKit] ℹ️  Other data type: ${data['type']}');
        }
      } catch (e) {
        print('[LiveKit] ❌ Error parsing data message: $e');
        print('[LiveKit] 📄 Raw data bytes: ${event.data}');
      }
    });
  }

  /// Handle client tool invocations sent over the LiveKit data channel.
  Future<void> _handleClientToolInvocation(Map<String, dynamic> data) async {
    try {
      print('[LiveKit] 🔧 _handleClientToolInvocation called with: $data');

      final toolName = data['toolName'] as String?;
      final parameters = data['parameters'] as Map<String, dynamic>? ?? {};
      final invocationId = data['invocationId'] as String?;

      print(
        '[LiveKit] 🔧 Executing client tool: $toolName with params: $parameters',
      );
      print('[LiveKit] 🔧 Invocation ID: $invocationId');

      if (toolName == 'navigate') {
        print('[LiveKit] 🔧 Handling navigate client tool');

        final result = await NavigateTool.handleNavigate(parameters);
        print('[LiveKit] 📍 Navigate tool result: $result');

        _sendClientToolResult(result, invocationId, toolName: toolName);

        // Notify callback for UI updates
        if (onToolCall != null) {
          onToolCall!(data);
        }
      } else {
        print('[LiveKit] ⚠️  Unknown client tool: $toolName');

        // Send error result
        final errorResult = ClientToolResult(
          result: 'Unknown tool: $toolName',
          responseType: 'error',
        );
        _sendClientToolResult(errorResult, invocationId, toolName: toolName);
      }
    } catch (e) {
      print('[LiveKit] ❌ Error handling client tool invocation: $e');

      final errorResult = ClientToolResult(
        result: 'Error executing client tool: $e',
        responseType: 'error',
      );

      _sendClientToolResult(
        errorResult,
        data['invocationId'],
        toolName: data['toolName'] as String?,
      );
    }
  }

  /// Send client tool result back to Ultravox via LiveKit data channel.
  void _sendClientToolResult(
    ClientToolResult result,
    String? invocationId, {
    String? toolName,
  }) {
    if (_room == null) {
      print(
        '[LiveKit] ⚠️  No LiveKit room available to send client tool result',
      );
      return;
    }

    // result.result is already a JSON string for new-stage; jsonEncode
    // will escape it properly so the server receives a string value.
    final response = {
      'type': 'client_tool_result',
      'result': result.result,
      'responseType': result.responseType,
      if (invocationId != null) 'invocationId': invocationId,
      if (toolName != null) 'toolName': toolName,
    };
    final finalResponse = jsonEncode(response);

    print('[LiveKit] 🔍 Final response to send: $finalResponse');

    final data = Uint8List.fromList(utf8.encode(finalResponse));
    _room!.localParticipant?.publishData(data, reliable: true);

    print('[LiveKit] 📤 Sent client tool result via LiveKit');
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

  bool get isConnected =>
      _room != null && _room!.connectionState == ConnectionState.connected;
}
