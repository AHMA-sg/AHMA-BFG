import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/ahma_theme.dart';
import '../../main.dart';
import 'unity_home_screen.dart';
import 'home_screen_example_blended.dart';
import '../providers/call_provider.dart';

/// AHMA Call Screen
///
/// Features:
/// - Push-to-talk button with kopi fill animation
/// - End call button
class AhmaCallScreen extends ConsumerStatefulWidget {
  const AhmaCallScreen({super.key});

  @override
  ConsumerState<AhmaCallScreen> createState() => _AhmaCallScreenState();
}

class _AhmaCallScreenState extends ConsumerState<AhmaCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _kopiFillController;
  late AnimationController _connectionBarController;
  late Animation<double> _kopiFillAnimation;
  late Animation<double> _connectionBarAnimation;
  bool _isPressing = false;
  bool _callStarted = false;
  bool _showPhoneOn = false;
  Timer? _callStartTimer;

  @override
  void initState() {
    super.initState();

    // Kopi fill animation
    _kopiFillController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _kopiFillAnimation = Tween<double>(begin: 8.0, end: 34.0).animate(
      CurvedAnimation(parent: _kopiFillController, curve: Curves.easeInOut),
    );

    // Connection bar animation
    _connectionBarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _connectionBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _connectionBarController,
        curve: Curves.easeInOut,
      ),
    );

    // Call will be started manually when user presses and holds button
  }

  @override
  void dispose() {
    _kopiFillController.dispose();
    _connectionBarController.dispose();
    _callStartTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Transparent to show watercolor background
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with logo and end button
            _buildTopBar(),

            // Main content
            Expanded(child: _buildMainContent(callState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // End call button
          GestureDetector(
            onTap: () async {
              // Disconnect the call if it's active
              if (_callStarted &&
                  ref.read(callProvider).status != CallStatus.ended) {
                await ref.read(callProvider.notifier).endCall();
                if (!mounted) return;
              }

              // Navigate back to appropriate home screen based on manual toggle
              if (USE_UNITY_HOME_SCREEN) {
                // Unity home screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const UnityHomeScreen()),
                  (route) => false,
                );
              } else {
                // Example blended home screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const HomeScreenBlendedExample(),
                  ),
                  (route) => false,
                );
              }
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AhmaTheme.ahmaRed.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AhmaTheme.ahmaRed.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close,
                size: 11,
                color: AhmaTheme.ahmaRed,
              ),
            ),
          ),

          // Logo
          Text(
            'AHMA',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AhmaTheme.ahmaRed,
              letterSpacing: 0.8,
            ),
          ),

          // Empty space for balance
          const SizedBox(width: 26),
        ],
      ),
    );
  }

  Widget _buildMainContent(CallState callState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Center(child: _buildPushToTalkArea(callState)),
    );
  }

  Widget _buildPushToTalkArea(CallState callState) {
    final isActive = callState.status == CallStatus.active;
    final isConnecting = callState.status == CallStatus.connecting;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Push-to-talk button
        GestureDetector(
          onTapDown: (_) => _startRecording(),
          onTapUp: (_) => _stopRecording(),
          onTapCancel: _stopRecording,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring (40% larger)
              Container(
                width: 92.4, // 40% larger: 66 * 1.4
                height: 92.4, // 40% larger: 66 * 1.4
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getRingColor(callState),
                    width: 1.4, // 40% larger: 1 * 1.4
                  ),
                ),
              ),

              // Phone or Mic icon
              _buildButtonIcon(callState),
            ],
          ),
        ),

        const SizedBox(height: 5),

        // Hint text
        Text(
          _getHintText(callState),
          style: AhmaTheme.labelTextStyle.copyWith(
            fontSize: 12.0, // 50% larger: 8 * 1.5
            color: _getTextColor(callState),
            letterSpacing: 0.7,
          ),
        ),

        const SizedBox(height: 8),

        // Connection bar or kopi fill animation
        if (isConnecting) _buildConnectionBar(),
        if (isActive) _buildKopiFillBar(),
      ],
    );
  }

  Widget _buildKopiFillBar() {
    return SizedBox(
      width: 86,
      height: 18,
      child: CustomPaint(painter: _KopiFillPainter(_kopiFillAnimation.value)),
    );
  }

  void _startRecording() {
    final status = ref.read(callProvider).status;
    if (_callStarted && status != CallStatus.active) {
      return;
    }

    setState(() {
      _isPressing = true;
    });

    if (!_callStarted) {
      // Show phone-on icon immediately
      setState(() {
        _showPhoneOn = true;
      });

      // Start the call after 2 seconds
      _callStartTimer = Timer(const Duration(seconds: 2), () async {
        if (mounted && _isPressing) {
          setState(() {
            _callStarted = true;
          });
          _connectionBarController.forward();

          await ref
              .read(callProvider.notifier)
              .startCall(
                userName: 'Abhi', // Example: Pass actual user name from auth
                careRecipientName: 'Grandpa', // Example: Get from user profile
                caregiverType:
                    'family', // Example: family, professional, volunteer
              );

          if (!mounted) return;

          if (ref.read(callProvider).status == CallStatus.error) {
            setState(() {
              _callStarted = false;
              _showPhoneOn = false;
            });
            _connectionBarController.reset();
          }
        }
      });
    } else {
      // Start audio capture for existing call
      _kopiFillController.repeat(reverse: true);
      ref.read(callProvider.notifier).startAudioCapture();
    }
  }

  void _stopRecording() {
    if (!_isPressing && !_showPhoneOn) {
      return;
    }

    setState(() {
      _isPressing = false;
      _showPhoneOn = false;
    });

    // Cancel the call start timer if user releases before 2 seconds
    _callStartTimer?.cancel();
    _callStartTimer = null;

    if (_callStarted && ref.read(callProvider).status == CallStatus.active) {
      _kopiFillController.stop();
      _kopiFillController.reset();
      ref.read(callProvider.notifier).stopAudioCapture();
    }
  }

  Color _getRingColor(CallState callState) {
    if (!_callStarted) {
      return _isPressing
          ? AhmaTheme.sageGreen.withOpacity(0.25)
          : AhmaTheme.mocha.withOpacity(0.1);
    }

    switch (callState.status) {
      case CallStatus.connecting:
      case CallStatus.active:
        return AhmaTheme.sageGreen.withOpacity(0.25);
      default:
        return AhmaTheme.mocha.withOpacity(0.1);
    }
  }

  Widget _buildButtonIcon(CallState callState) {
    if (!_callStarted) {
      // Show phone-off icon before call starts, phone-on when pressing
      if (_showPhoneOn) {
        return Image.asset(
          'resources/Phone-on.png',
          width: 52.8, // 60% larger: 33 * 1.6
          height: 52.8, // 60% larger: 33 * 1.6
        );
      } else {
        return Image.asset(
          'resources/Phone-off.png',
          width: 49.92, // 60% larger: 31.2 * 1.6
          height: 49.92, // 60% larger: 31.2 * 1.6
        );
      }
    }

    switch (callState.status) {
      case CallStatus.connecting:
        // Show phone-on icon while connecting
        return Image.asset(
          'resources/Phone-on.png',
          width: 49.92, // 60% larger: 31.2 * 1.6
          height: 49.92, // 60% larger: 31.2 * 1.6
        );
      case CallStatus.active:
        // Show phone-off icon when not pressing, phone-on when pressing
        if (_isPressing) {
          return Image.asset(
            'resources/Phone-on.png',
            width: 49.92, // 60% larger: 31.2 * 1.6
            height: 49.92, // 60% larger: 31.2 * 1.6
          );
        } else {
          return Image.asset(
            'resources/Phone-off.png',
            width: 49.92, // 60% larger: 31.2 * 1.6
            height: 49.92, // 60% larger: 31.2 * 1.6
          );
        }
      default:
        return Icon(
          Icons.phone_disabled,
          size: 20,
          color: Colors.white.withOpacity(0.4),
        );
    }
  }

  String _getHintText(CallState callState) {
    if (!_callStarted) {
      return 'press & hold to call';
    }

    switch (callState.status) {
      case CallStatus.connecting:
        return 'connecting...';
      case CallStatus.active:
        return _isPressing ? 'release to send' : 'hold to speak';
      default:
        return 'call ended';
    }
  }

  Color _getTextColor(CallState callState) {
    if (!_callStarted) {
      return AhmaTheme.mocha.withOpacity(0.35);
    }

    switch (callState.status) {
      case CallStatus.connecting:
      case CallStatus.active:
        return AhmaTheme.mocha.withOpacity(0.35);
      default:
        return AhmaTheme.mocha.withOpacity(0.2);
    }
  }

  Widget _buildConnectionBar() {
    return AnimatedBuilder(
      animation: _connectionBarAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 86,
          height: 18,
          child: CustomPaint(
            painter: _ConnectionBarPainter(_connectionBarAnimation.value),
          ),
        );
      },
    );
  }
}

class _ConnectionBarPainter extends CustomPainter {
  final double progress;

  _ConnectionBarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Background bar
    final bgPaint = Paint()
      ..color = AhmaTheme.mocha.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, size.height * 0.33, 72, size.height * 0.33),
      const Radius.circular(3),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Green connection fill bar
    final fillPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final fillWidth = 72.0 * progress;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, size.height * 0.33, fillWidth, size.height * 0.33),
      const Radius.circular(3),
    );
    canvas.drawRRect(fillRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _ConnectionBarPainter ||
        oldDelegate.progress != progress;
  }
}

class _TeaCupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 0.7
      ..color = AhmaTheme.mocha.withOpacity(0.85);

    // Cup shadow
    final shadowPaint = Paint()
      ..color = AhmaTheme.mid.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.82),
      width: size.width * 0.58,
      height: size.height * 0.06,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    // Cup body
    final cupPath = Path()
      ..moveTo(size.width * 0.24, size.height * 0.42)
      ..lineTo(size.width * 0.27, size.height * 0.79)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.86,
        size.width * 0.71,
        size.height * 0.79,
      )
      ..lineTo(size.width * 0.76, size.height * 0.42)
      ..close();

    canvas.drawPath(cupPath, paint);

    // Tea inside
    final teaPaint = Paint()
      ..color = AhmaTheme.mocha.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final teaPath = Path()
      ..moveTo(size.width * 0.27, size.height * 0.51)
      ..lineTo(size.width * 0.28, size.height * 0.77)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.82,
        size.width * 0.70,
        size.height * 0.77,
      )
      ..lineTo(size.width * 0.72, size.height * 0.51)
      ..close();

    canvas.drawPath(teaPath, teaPaint);

    // Tea surface
    final surfacePaint = Paint()
      ..color = AhmaTheme.palePink.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final surfaceRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.51),
      width: size.width * 0.39,
      height: size.height * 0.05,
    );
    canvas.drawOval(surfaceRect, surfacePaint);

    // Steam lines
    final steamPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.4)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left steam
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.36),
      Offset(size.width * 0.41, size.height * 0.24),
      steamPaint,
    );

    // Middle steam
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.33),
      Offset(size.width * 0.5, size.height * 0.21),
      steamPaint,
    );

    // Right steam
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.36),
      Offset(size.width * 0.59, size.height * 0.24),
      steamPaint,
    );

    // Handle
    final handlePaint = Paint()
      ..color = AhmaTheme.mocha.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(size.width * 0.76, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.48,
        size.width * 0.86,
        size.height * 0.59,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.70,
        size.width * 0.76,
        size.height * 0.70,
      );

    canvas.drawPath(handlePath, handlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KopiFillPainter extends CustomPainter {
  final double fillWidth;

  _KopiFillPainter(this.fillWidth);

  @override
  void paint(Canvas canvas, Size size) {
    // Background bar
    final bgPaint = Paint()
      ..color = AhmaTheme.mocha.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, size.height * 0.33, 72, size.height * 0.33),
      const Radius.circular(3),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Fill bar
    final fillPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, size.height * 0.33, fillWidth, size.height * 0.33),
      const Radius.circular(3),
    );
    canvas.drawRRect(fillRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _KopiFillPainter ||
        oldDelegate.fillWidth != fillWidth;
  }
}
