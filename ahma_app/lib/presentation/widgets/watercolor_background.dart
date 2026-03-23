import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated watercolor-style background with morphing gradients
///
/// Uses animated gradients to simulate watercolor effects. Can be replaced
/// with Lottie/Rive animation files when available.
class WatercolorBackground extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Duration duration;

  const WatercolorBackground({
    super.key,
    this.primaryColor = const Color(0xFFB8E6E1), // Soft teal
    this.secondaryColor = const Color(0xFFE8B4D9), // Soft pink
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<WatercolorBackground> createState() => _WatercolorBackgroundState();
}

class _WatercolorBackgroundState extends State<WatercolorBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  widget.primaryColor,
                  widget.secondaryColor,
                  _animation.value,
                )!,
                Color.lerp(
                  widget.secondaryColor,
                  widget.primaryColor,
                  _animation.value,
                )!,
                Color.lerp(
                  widget.primaryColor.withOpacity(0.6),
                  widget.secondaryColor.withOpacity(0.6),
                  _animation.value,
                )!,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
              transform: GradientRotation(_animation.value * math.pi / 4),
            ),
          ),
        );
      },
    );
  }
}

/// For future implementation with Lottie animations:
///
/// import 'package:lottie/lottie.dart';
///
/// class WatercolorBackgroundLottie extends StatelessWidget {
///   final String animationPath;
///
///   const WatercolorBackgroundLottie({
///     super.key,
///     this.animationPath = 'resources/animations/watercolor-bg.json',
///   });
///
///   @override
///   Widget build(BuildContext context) {
///     return SizedBox.expand(
///       child: Lottie.asset(
///         animationPath,
///         fit: BoxFit.cover,
///         repeat: true,
///         options: LottieOptions(
///           enableMergePaths: true,
///         ),
///       ),
///     );
///   }
/// }
