import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/call_provider.dart';
import '../../data/models/call_model.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> {
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    // Start call when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Get user info from auth provider
      // final user = ref.read(authProvider);

      ref.read(callProvider.notifier).startCall(
        userName: 'Maria',  // Example: Pass actual user name from auth
        careRecipientName: 'Mother',  // Example: Get from user profile
        caregiverType: 'family',  // Example: family, professional, volunteer
      );
    });
  }

  void _startTalking() {
    setState(() => _isPressing = true);
    ref.read(callProvider.notifier).startAudioCapture();
  }

  void _stopTalking() {
    setState(() => _isPressing = false);
    ref.read(callProvider.notifier).stopAudioCapture();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AHMA Voice Call'),
        backgroundColor: _getStageColor(callState.call?.stage),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Status indicator
              _buildStatusIndicator(callState),
              const SizedBox(height: 32),

              // Current stage indicator
              if (callState.status == CallStatus.active)
                _buildStageIndicator(callState.call?.stage ?? CallStage.assess),
              const SizedBox(height: 32),

              // Transcript (placeholder)
              Expanded(
                child: _buildTranscript(callState),
              ),
              const SizedBox(height: 24),

              // Controls
              _buildControls(callState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(CallState state) {
    String status;
    Icon icon;
    Color color;

    switch (state.status) {
      case CallStatus.connecting:
        status = 'Connecting...';
        icon = const Icon(Icons.sync, size: 48);
        color = Colors.orange;
        break;
      case CallStatus.active:
        status = 'Call in progress';
        icon = const Icon(Icons.mic, size: 48);
        color = Colors.green;
        break;
      case CallStatus.ended:
        status = 'Call ended';
        icon = const Icon(Icons.check_circle, size: 48);
        color = Colors.grey;
        break;
      case CallStatus.error:
        status = 'Error: ${state.error}';
        icon = const Icon(Icons.error, size: 48);
        color = Colors.red;
        break;
      default:
        status = 'Idle';
        icon = const Icon(Icons.phone, size: 48);
        color = Colors.grey;
    }

    return Column(
      children: [
        IconTheme(
          data: IconThemeData(color: color),
          child: icon,
        ),
        const SizedBox(height: 8),
        Text(
          status,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStageIndicator(CallStage stage) {
    final stages = [
      ('Assess', CallStage.assess, Colors.blue),
      ('Support', CallStage.support, Colors.green),
      ('Evaluate', CallStage.evaluate, Colors.purple),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stages.map((s) {
        final isActive = s.$2 == stage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? s.$3 : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  s.$1.substring(0, 1),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.$1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? s.$3 : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTranscript(CallState state) {
    if (state.call?.transcript.isEmpty ?? true) {
      return Center(
        child: Text(
          state.status == CallStatus.active
              ? 'Listening...'
              : 'No messages yet',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.call!.transcript.length,
      itemBuilder: (context, index) {
        final message = state.call!.transcript[index];
        final isUser = message.role == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.teal[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.text),
          ),
        );
      },
    );
  }

  Widget _buildControls(CallState state) {
    final isActive = state.status == CallStatus.active;

    if (!isActive) {
      // Go back button if call ended
      if (state.status == CallStatus.ended || state.status == CallStatus.error) {
        return ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Back to Home'),
        );
      }
      return const SizedBox.shrink();
    }

    // Push-to-Talk UI for active calls
    return Column(
      children: [
        // Instruction text
        Text(
          _isPressing ? 'Release to send' : 'Hold to speak',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),

        // PTT Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => _startTalking(),
              onTapUp: (_) => _stopTalking(),
              onTapCancel: () => _stopTalking(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isPressing ? 120 : 100,
                height: _isPressing ? 120 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPressing ? Colors.red : Colors.blue,
                  boxShadow: _isPressing
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  _isPressing ? Icons.mic : Icons.mic_none,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 40),

            // End call button
            FloatingActionButton(
              onPressed: () async {
                await ref.read(callProvider.notifier).endCall();
              },
              backgroundColor: Colors.grey[700],
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStageColor(CallStage? stage) {
    switch (stage) {
      case CallStage.assess:
        return Colors.blue;
      case CallStage.support:
        return Colors.green;
      case CallStage.evaluate:
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }
}
