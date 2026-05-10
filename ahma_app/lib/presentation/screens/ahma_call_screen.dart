import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/ahma_theme.dart';
import '../providers/call_provider.dart';
import 'profile_screen.dart';

/// AHMA Call Screen
///
/// Features:
/// - Push-to-talk button with kopi fill animation
/// - End call button
class AhmaCallScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToProfile;

  const AhmaCallScreen({super.key, this.onBackToProfile});

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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'AHMA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AhmaTheme.ahmaRed,
                letterSpacing: 0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: _handleBackToProfile,
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
                Icons.arrow_back_rounded,
                size: 14,
                color: AhmaTheme.ahmaRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackToProfile() async {
    if (_callStarted && ref.read(callProvider).status != CallStatus.ended) {
      await ref.read(callProvider.notifier).endCall();
    }

    if (!mounted) return;

    if (widget.onBackToProfile != null) {
      widget.onBackToProfile!();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
      (route) => false,
    );
  }

  Widget _buildMainContent(CallState callState) {
    return Center(child: _buildPushToTalkArea(callState));
  }

  Widget _buildPushToTalkArea(CallState callState) {
    final isActive = callState.status == CallStatus.active;
    final isConnecting = callState.status == CallStatus.connecting;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Push-to-talk button
        GestureDetector(
          onTapDown: (!_callStarted || isActive)
              ? (_) => _startRecording()
              : null,
          onTapUp: (!_callStarted || isActive) ? (_) => _stopRecording() : null,
          onTapCancel: (!_callStarted || isActive)
              ? () => _stopRecording()
              : null,
          child: _buildPrimaryActionOrb(callState),
        ),
        const SizedBox(height: 8),

        // Connection bar or kopi fill animation
        if (isConnecting) _buildConnectionBar(),
        if (isActive) _buildKopiFillBar(),
      ],
    );
  }

  Widget _buildPrimaryActionOrb(CallState callState) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getOrbOuterColor(callState),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getOrbMiddleColor(callState),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 146,
            height: 146,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getOrbInnerColor(callState),
              boxShadow: [
                BoxShadow(
                  color: AhmaTheme.mocha.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getOrbPrompt(callState),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: _getOrbPromptColor(callState),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildButtonIcon(callState),
              ],
            ),
          ),
        ],
      ),
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
    setState(() {
      _isPressing = true;
    });

    if (!_callStarted) {
      // Show phone-on icon immediately
      setState(() {
        _showPhoneOn = true;
      });

      // Start the call after 2 seconds
      _callStartTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _isPressing) {
          setState(() {
            _callStarted = true;
          });
          _connectionBarController.forward();

          ref
              .read(callProvider.notifier)
              .startCall(
                userName: 'Sam', // Example: Pass actual user name from auth
                careRecipientName: 'Grandpa', // Example: Get from user profile
                caregiverType:
                    'family', // Example: family, professional, volunteer
              );
        }
      });
    } else {
      // Start audio capture for existing call
      _kopiFillController.repeat(reverse: true);
      ref.read(callProvider.notifier).startAudioCapture();
    }
  }

  void _stopRecording() {
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

  Color _getOrbOuterColor(CallState callState) {
    if (!_callStarted) {
      return _isPressing
          ? AhmaTheme.sageGreen.withOpacity(0.20)
          : Colors.white.withOpacity(0.08);
    }

    switch (callState.status) {
      case CallStatus.connecting:
        return AhmaTheme.sageGreen.withOpacity(0.18);
      case CallStatus.active:
        return _isPressing
            ? AhmaTheme.sageGreen.withOpacity(0.22)
            : Colors.white.withOpacity(0.08);
      default:
        return Colors.white.withOpacity(0.06);
    }
  }

  Color _getOrbMiddleColor(CallState callState) {
    if (!_callStarted) {
      return _isPressing
          ? AhmaTheme.sageGreen.withOpacity(0.14)
          : Colors.white.withOpacity(0.12);
    }

    switch (callState.status) {
      case CallStatus.connecting:
        return AhmaTheme.sageGreen.withOpacity(0.14);
      case CallStatus.active:
        return _isPressing
            ? AhmaTheme.sageGreen.withOpacity(0.18)
            : Colors.white.withOpacity(0.12);
      default:
        return Colors.white.withOpacity(0.10);
    }
  }

  Color _getOrbInnerColor(CallState callState) {
    if (!_callStarted) {
      return const Color(0xFFFAF5EE);
    }

    switch (callState.status) {
      case CallStatus.connecting:
        return const Color(0xFFF1F6EC);
      case CallStatus.active:
        return _isPressing ? const Color(0xFFE6F0DB) : const Color(0xFFFAF5EE);
      default:
        return const Color(0xFFF4EFE8);
    }
  }

  String _getOrbPrompt(CallState callState) {
    if (!_callStarted) {
      return 'hold to call';
    }

    switch (callState.status) {
      case CallStatus.connecting:
        return 'connecting';
      case CallStatus.active:
        return _isPressing ? 'release' : 'hold to speak';
      default:
        return 'call ended';
    }
  }

  Color _getOrbPromptColor(CallState callState) {
    if (!_callStarted) {
      return AhmaTheme.sageGreen;
    }

    switch (callState.status) {
      case CallStatus.connecting:
      case CallStatus.active:
        return AhmaTheme.sageGreen;
      default:
        return AhmaTheme.mocha.withOpacity(0.6);
    }
  }

  Widget _buildButtonIcon(CallState callState) {
    if (!_callStarted) {
      // Show phone-off icon before call starts, phone-on when pressing
      if (_showPhoneOn) {
        return Image.asset('resources/Phone-on.png', width: 38, height: 38);
      } else {
        return Image.asset('resources/Phone-off.png', width: 36, height: 36);
      }
    }

    switch (callState.status) {
      case CallStatus.connecting:
        // Show phone-on icon while connecting
        return Image.asset('resources/Phone-on.png', width: 36, height: 36);
      case CallStatus.active:
        // Show phone-off icon when not pressing, phone-on when pressing
        if (_isPressing) {
          return Image.asset('resources/Phone-on.png', width: 36, height: 36);
        } else {
          return Image.asset('resources/Phone-off.png', width: 36, height: 36);
        }
      default:
        return Icon(
          Icons.phone_disabled,
          size: 28,
          color: Colors.white.withOpacity(0.4),
        );
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
