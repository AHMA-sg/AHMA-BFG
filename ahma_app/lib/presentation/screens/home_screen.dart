import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'voice_call_screen.dart';
import 'house_interior_screen.dart';
import 'next_steps_screen.dart';
import '../../core/config/env_config.dart';
import '../widgets/random_sky_background.dart';
import '../widgets/house_animation.dart';
import '../widgets/hold_to_walk_button.dart';
import '../providers/backend_provider.dart';
import '../providers/webhook_provider.dart';

/// Redesigned home screen with gamified UI - Cinematic camera effect
///
/// Features:
/// - Full screen watercolor animated background
/// - House rises slowly after 2s delay (camera descending from sky)
/// - AHMA logo fades in after house settles
/// - Minimal aesthetic with right-edge button
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    // Initialize webhook handler
    Future.microtask(() {
      ref.read(webhookHandlerProvider);
    });

    // Logo fades in after house settles (2s delay + 2.5s house animation = 4.5s)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Start logo fade after house settles
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
    final houseHeight = screenSize.height * 0.7; // 70% of screen height
    final backendState = ref.watch(backendProvider);

    return Scaffold(
      // Remove app bar for full screen experience
      body: RandomSkyBackground(
        pathHeight: 0.3, // 30% of screen is pale brown path
        child: Stack(
          children: [
            // Layer 1: House animation (70% height, aligned to bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HouseAnimationCinematic(
                height: houseHeight,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HouseInteriorScreen(),
                    ),
                  );
                },
              ),
            ),

            // Layer 2: Top - AHMA logo (fades in after house settles)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: _buildMinimalLogo(context),
              ),
            ),

            // Layer 3: Right edge - Smaller hold-to-walk button
            Positioned(
              right: 24,
              top: screenSize.height / 2 - 60, // Middle right
              child: HoldToWalkButton(
                label: "Let's go\nfor a walk",
                color: Colors.teal.shade700,
                onComplete: () {
                  _startVoiceCall(context);
                },
                size: 120, // Smaller button
              ),
            ),

            // Configuration warning if needed (bottom, above house)
            if (!EnvConfig.isConfigured)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _buildConfigWarning(),
              ),

            // New update notification badge (top left)
            if (backendState.latestUpdate != null)
              Positioned(
                top: 60,
                left: 20,
                child: _buildUpdateBadge(context, backendState.latestUpdate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateBadge(BuildContext context, update) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NextStepsScreen(update: update),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.teal.shade700.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Next Steps Ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${update.stats.actionsInWebhook}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
            fontWeight: FontWeight.w300, // Light weight for minimal aesthetic
            color: Colors.teal.shade800,
            letterSpacing: 8,
            fontFamily: 'SF Pro Display', // Fallback to system sans-serif
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

  Widget _buildConfigWarning() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 16),
            const SizedBox(width: 8),
            Text(
              'Configuration needed',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startVoiceCall(BuildContext context) {
    if (!EnvConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure .env file with API keys'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to voice call screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VoiceCallScreen(),
      ),
    );
  }
}
