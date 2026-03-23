import 'package:flutter/material.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';

/// Unity endless runner game integration
///
/// REQUIREMENTS:
/// 1. Unity project must be exported for flutter_unity_widget
/// 2. Unity must implement message listeners:
///    - StartGame() - begins scrolling
///    - PauseGame() - pauses when switching to transcript
///    - StopGame() - stops and returns to idle
/// 3. Unity must send position updates:
///    - SendMessageToFlutter("OnCatPosition", xPosition)
///
/// TODO: Implement once Unity project is ready
class UnityEndlessRunner extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onGameReady;

  const UnityEndlessRunner({
    super.key,
    this.isActive = true,
    this.onGameReady,
  });

  @override
  State<UnityEndlessRunner> createState() => _UnityEndlessRunnerState();
}

class _UnityEndlessRunnerState extends State<UnityEndlessRunner> {
  // late UnityWidgetController _unityController;

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual UnityWidget when ready
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videogame_asset, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Unity Game\n(Coming Soon)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*
  // Example implementation with flutter_unity_widget:

  @override
  Widget build(BuildContext context) {
    return UnityWidget(
      onUnityCreated: _onUnityCreated,
      onUnityMessage: _onUnityMessage,
      fullscreen: false,
    );
  }

  void _onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
    widget.onGameReady?.call();

    if (widget.isActive) {
      _startGame();
    }
  }

  void _onUnityMessage(message) {
    // Handle messages from Unity
    if (message is Map && message['event'] == 'OnCatPosition') {
      final position = message['position'] as double;
      // Update cat position in Flutter
    }
  }

  void _startGame() {
    _unityController.postMessage(
      'GameManager',
      'StartGame',
      '',
    );
  }

  void _pauseGame() {
    _unityController.postMessage(
      'GameManager',
      'PauseGame',
      '',
    );
  }

  void _stopGame() {
    _unityController.postMessage(
      'GameManager',
      'StopGame',
      '',
    );
  }

  @override
  void didUpdateWidget(UnityEndlessRunner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startGame();
      } else {
        _pauseGame();
      }
    }
  }

  @override
  void dispose() {
    _unityController.dispose();
    super.dispose();
  }
  */
}
