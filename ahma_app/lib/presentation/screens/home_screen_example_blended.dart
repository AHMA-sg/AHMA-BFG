import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/house_animation.dart';
import '../widgets/watercolor_background.dart';
import '../providers/webhook_provider.dart';
import 'ahma_main_screen.dart';

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

    // Initialize webhook server by accessing the provider
    ref.read(webhookHandlerProvider);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

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
          const Positioned.fill(
            child: WatercolorBackground(child: SizedBox.expand()),
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
                // Navigate to AHMA main screen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AhmaMainScreen()),
                );
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
