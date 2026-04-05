import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

/// Animated house that rises from bottom and settles in the center
///
/// Features:
/// - Slides up from bottom with elastic bounce
/// - Tap to navigate to house interior
/// - Hero animation tag for smooth transitions
class HouseAnimation extends StatelessWidget {
  final VoidCallback? onTap;
  final String imagePath;
  final double height;

  const HouseAnimation({
    super.key,
    this.onTap,
    this.imagePath = 'resources/Sh1.png',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'house-hero',
        child: SlideInUp(
          duration: const Duration(milliseconds: 1200),
          from: 300, // Slide from 300px below
          child: ElasticIn(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 1000),
            child: Image.asset(
              imagePath,
              height: height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cinematic version - Camera descending from sky to house
/// 2 second delay, slow rise, gentle settle
class HouseAnimationCinematic extends StatefulWidget {
  final VoidCallback? onTap;
  final String imagePath;
  final double height;

  const HouseAnimationCinematic({
    super.key,
    this.onTap,
    this.imagePath = 'resources/Sh1.png',
    this.height = 200,
  });

  @override
  State<HouseAnimationCinematic> createState() => _HouseAnimationCinematicState();
}

class _HouseAnimationCinematicState extends State<HouseAnimationCinematic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Slower, cinematic
    );

    // Slow camera descent - house rises from below
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start below screen
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth, cinematic ease
      ),
    );

    // Subtle scale for depth effect
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Start animation after 2 second delay (camera focusing)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: 'house-hero',
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              widget.imagePath,
              height: widget.height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Original version - kept for reference
class HouseAnimationCustom extends StatefulWidget {
  final VoidCallback? onTap;
  final String imagePath;
  final double height;

  const HouseAnimationCustom({
    super.key,
    this.onTap,
    this.imagePath = 'resources/Sh1.png',
    this.height = 200,
  });

  @override
  State<HouseAnimationCustom> createState() => _HouseAnimationCustomState();
}

class _HouseAnimationCustomState extends State<HouseAnimationCustom>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2), // Start 2x screen height below
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Gentle bounce on settle
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: 'house-hero',
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _bounceAnimation,
            child: Image.asset(
              widget.imagePath,
              height: widget.height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
