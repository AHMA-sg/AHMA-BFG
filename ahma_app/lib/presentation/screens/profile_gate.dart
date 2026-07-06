import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../providers/profile_provider.dart';
import 'onboarding_screen.dart';

/// Launch gate that sits above both home-screen variants.
///
/// - checking     -> lightweight splash while the saved userId is verified
/// - onboarding   -> conversational profile intake
/// - unreachable  -> retriable error (identity kept — R11)
/// - ready        -> the main AHMA experience ([app])
class ProfileGate extends ConsumerWidget {
  /// The main app experience shown once a profile is confirmed.
  final Widget app;

  const ProfileGate({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(profileGateProvider);

    switch (gate.status) {
      case ProfileGateStatus.checking:
        return const _GateSplash();
      case ProfileGateStatus.onboarding:
        return const OnboardingScreen();
      case ProfileGateStatus.unreachable:
        return _GateUnreachable(
          message:
              gate.message ?? "We can't reach the profile service right now.",
          onRetry: () => ref.read(profileGateProvider.notifier).retry(),
        );
      case ProfileGateStatus.ready:
        return app;
    }
  }
}

class _GateSplash extends StatelessWidget {
  const _GateSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AhmaTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'AHMA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: AhmaTheme.ahmaRed,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AhmaTheme.sageGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateUnreachable extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GateUnreachable({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AhmaTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AhmaTheme.sageGreen,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    color: AhmaTheme.mocha,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 52),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
