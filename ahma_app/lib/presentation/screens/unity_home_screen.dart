import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'house_interior_screen.dart';
import 'next_steps_screen.dart';
import '../providers/backend_provider.dart';
import '../providers/webhook_provider.dart';
import '../../core/config/env_config.dart';

/// Unity integrated home screen
/// 
/// Displays Unity content and handles communication between Unity and Flutter.
class UnityHomeScreen extends ConsumerStatefulWidget {
  const UnityHomeScreen({super.key});

  @override
  ConsumerState<UnityHomeScreen> createState() => _UnityHomeScreenState();
}

class _UnityHomeScreenState extends ConsumerState<UnityHomeScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize webhook handler
    Future.microtask(() {
      ref.read(webhookHandlerProvider);
    });
  }

  void onUnityMessage(String message) {
    print("Unity says: $message");

    if (message == "touch_released") {
      // When the Unity button is released, navigate to house interior
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HouseInteriorScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backendState = ref.watch(backendProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Unity widget takes full screen
          EmbedUnity(
            onMessageFromUnity: onUnityMessage,
          ),
          
          // Configuration warning if needed
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
    );
  }

  Widget _buildConfigWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '⚠️ Backend not configured. Check .env file.',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'New Update',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
