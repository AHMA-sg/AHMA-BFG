import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Press-and-hold button with circular progress indicator
///
/// Features:
/// - Hold for ~2 seconds to activate
/// - Circular progress ring shows hold progress
/// - Haptic feedback on complete
/// - Customizable label, colors, and size
class HoldToWalkButton extends StatefulWidget {
  final VoidCallback onComplete;
  final String label;
  final Duration holdDuration;
  final Color color;
  final Color progressColor;
  final double size; // Customizable size

  const HoldToWalkButton({
    super.key,
    required this.onComplete,
    this.label = "Let's go for a walk",
    this.holdDuration = const Duration(milliseconds: 2000),
    this.color = Colors.teal,
    this.progressColor = Colors.white,
    this.size = 200, // Default size
  });

  @override
  State<HoldToWalkButton> createState() => _HoldToWalkButtonState();
}

class _HoldToWalkButtonState extends State<HoldToWalkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldComplete();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    setState(() {
      _isHolding = true;
    });
    _progressController.forward();
  }

  void _onHoldCancel() {
    setState(() {
      _isHolding = false;
    });
    _progressController.reverse();
  }

  void _onHoldComplete() {
    setState(() {
      _isHolding = false;
    });
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Scale icon and text based on button size
    final iconSize = widget.size * 0.3;
    final fontSize = widget.size * 0.11;
    final hintFontSize = widget.size * 0.08;

    return GestureDetector(
      onTapDown: (_) => _onHoldStart(),
      onTapUp: (_) => _onHoldCancel(),
      onTapCancel: _onHoldCancel,
      child: AnimatedScale(
        scale: _isHolding ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: widget.size * 0.1,
                spreadRadius: widget.size * 0.025,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ProgressRingPainter(
                      progress: _progressController.value,
                      color: widget.progressColor,
                      strokeWidth: widget.size * 0.04,
                    ),
                  );
                },
              ),
              // Label
              Padding(
                padding: EdgeInsets.all(widget.size * 0.14), // Reduced padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Prevent overflow
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: iconSize,
                      color: widget.progressColor,
                    ),
                    SizedBox(height: widget.size * 0.03), // Reduced spacing
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w300,
                          color: widget.progressColor,
                          letterSpacing: 0.5,
                          height: 1.1, // Tighter line height
                        ),
                      ),
                    ),
                    if (!_isHolding) ...[
                      SizedBox(height: widget.size * 0.015), // Reduced spacing
                      Text(
                        'press & hold',
                        style: TextStyle(
                          fontSize: hintFontSize,
                          fontWeight: FontWeight.w300,
                          color: widget.progressColor.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for circular progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth - 5;

    // Background ring
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at top
        2 * math.pi * progress, // Sweep angle based on progress
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
