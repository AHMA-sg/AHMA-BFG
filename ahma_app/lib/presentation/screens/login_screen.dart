import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../providers/auth_provider.dart';

/// Simulated login — the first screen of the app.
///
/// There is no real authentication: the email is the stub credential. It is
/// resolved against the profile backend (POST /api/profile/resolve) — a
/// known email lands straight in its profile, an unknown one routes into
/// onboarding with the email pre-filled. The provider buttons funnel into
/// the same path with fabricated demo addresses.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _continueWithEmail() {
    ref.read(authProvider.notifier).signIn(_emailController.text);
  }

  void _continueWithProvider(String demoEmail) {
    _emailController.text = demoEmail;
    ref.read(authProvider.notifier).signIn(demoEmail);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final busy = auth.status == AuthStatus.signingIn;

    return Scaffold(
      backgroundColor: AhmaTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AHMA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: AhmaTheme.ahmaRed,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your AI care resource companion',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      color: AhmaTheme.mocha.withValues(alpha: 0.64),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Sign in to continue — we'll bring you right back to "
                    'your care profile.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      color: AhmaTheme.mocha,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continueWithEmail(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      color: AhmaTheme.mocha,
                    ),
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      hintStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            fontSize: 16,
                            color: AhmaTheme.mocha.withValues(alpha: 0.38),
                          ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _InlineError(message: auth.errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: busy ? null : _continueWithEmail,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: AhmaTheme.labelTextStyle.copyWith(
                            fontSize: 12,
                            color: AhmaTheme.mocha.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ProviderButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Sign in with Google',
                    enabled: !busy,
                    onPressed: () =>
                        _continueWithProvider('google.demo@ahma.dev'),
                  ),
                  const SizedBox(height: 12),
                  _ProviderButton(
                    icon: Icons.apple_rounded,
                    label: 'Sign in with Apple',
                    enabled: !busy,
                    onPressed: () =>
                        _continueWithProvider('apple.demo@ahma.dev'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Demo sign-in: no password needed. Your email links you '
                    'to your care profile — the same email signs you back '
                    'in on any device.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 12.5,
                      color: AhmaTheme.mocha.withValues(alpha: 0.55),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 24, color: AhmaTheme.mocha),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AhmaTheme.mocha,
        side: BorderSide(color: AhmaTheme.sageGreen.withValues(alpha: 0.45)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontSize: 16),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AhmaTheme.palePink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AhmaTheme.palePink.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 18,
            color: AhmaTheme.palePink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                color: AhmaTheme.mocha,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
