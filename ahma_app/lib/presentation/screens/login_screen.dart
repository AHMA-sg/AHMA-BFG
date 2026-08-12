import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../providers/auth_provider.dart';

/// Unified entry point: verify an email, then continue to its existing account
/// or first-time profile onboarding.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carry a known email (e.g. after a failed verify) back into the field.
    final email = ref.read(authProvider).email;
    if (email != null) _emailController.text = email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendCode() {
    ref.read(authProvider.notifier).requestCode(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final busy = auth.status == AuthStatus.requestingCode;

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
                    "Enter your email to continue. We'll send a one-time code, "
                    'then sign you in or help set up your profile.',
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
                    onSubmitted: (_) => _sendCode(),
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
                    onPressed: busy ? null : _sendCode,
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
                        : const Text('Continue with email'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We'll email a 6-digit code to confirm it's you. The same "
                    'email signs you back in on any device.',
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
