import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/blended_background.dart';
import '../widgets/house_animation.dart';
import '../widgets/hold_to_walk_button.dart';

/// Example of using BlendedBackground in HomeScreen
///
/// USAGE: Place your watercolor PNGs in resources/ folder and update imagePath
class HomeScreenBlendedExample extends ConsumerStatefulWidget {
  const HomeScreenBlendedExample({super.key});

  @override
  ConsumerState<HomeScreenBlendedExample> createState() =>
      _HomeScreenBlendedExampleState();
}

class _HomeScreenBlendedExampleState
    extends ConsumerState<HomeScreenBlendedExample>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        _logoController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final houseHeight = screenSize.height * 0.7;

    return Scaffold(
      body: Stack(
        children: [
          // OPTION 1: Static blended background
          const Positioned.fill(
            child: BlendedBackground(
              backgroundColor: Color(0xFFFFF4E6), // Base cream color
              layers: [
                // Base watercolor texture
                BackgroundLayer(
                  imagePath: 'resources/bg-watercolor-base.png',
                  opacity: 1.0,
                  blendMode: BlendMode.srcOver,
                ),
                // Teal overlay with multiply blend (creates depth)
                BackgroundLayer(
                  imagePath: 'resources/bg-watercolor-teal.png',
                  opacity: 0.5,
                  blendMode: BlendMode.multiply,
                ),
                // Soft accent layer
                BackgroundLayer(
                  imagePath: 'resources/bg-watercolor-accent.png',
                  opacity: 0.3,
                  blendMode: BlendMode.softLight,
                ),
              ],
            ),
          ),

          // OPTION 2: Animated blended background (layers fade in)
          // Uncomment to use instead:
          /*
          const Positioned.fill(
            child: AnimatedBlendedBackground(
              backgroundColor: Color(0xFFFFF4E6),
              animationDuration: Duration(seconds: 4),
              layers: [
                BackgroundLayer(
                  imagePath: 'resources/bg-layer-1.png',
                  opacity: 1.0,
                ),
                BackgroundLayer(
                  imagePath: 'resources/bg-layer-2.png',
                  opacity: 0.6,
                  blendMode: BlendMode.multiply,
                ),
              ],
            ),
          ),
          */

          // House at bottom (70% height)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HouseAnimationCinematic(
              height: houseHeight,
              onTap: () {
                // Navigate to house interior
              },
            ),
          ),

          // AHMA logo (fades in)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _logoOpacity,
              child: _buildMinimalLogo(context),
            ),
          ),

          // Button on right edge
          Positioned(
            right: 24,
            top: screenSize.height / 2 - 60,
            child: HoldToWalkButton(
              label: "Let's go\nfor a walk",
              color: Colors.teal.shade700,
              onComplete: () {
                // Start voice call
              },
              size: 120,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalLogo(BuildContext context) {
    return Column(
      children: [
        Text(
          'AHMA',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.teal.shade800,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'your caring companion',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: Colors.grey.shade600,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
