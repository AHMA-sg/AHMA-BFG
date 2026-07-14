import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../providers/auth_provider.dart';

/// Enter the 6-digit code emailed by `POST /api/auth/request-code`. Verifying
/// it (`/api/auth/verify`) mints the session JWT.
class CodeVerifyScreen extends ConsumerStatefulWidget {
  const CodeVerifyScreen({super.key});

  @override
  ConsumerState<CodeVerifyScreen> createState() => _CodeVerifyScreenState();
}

class _CodeVerifyScreenState extends ConsumerState<CodeVerifyScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verify() {
    ref.read(authProvider.notifier).verifyCode(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final busy = auth.status == AuthStatus.verifying;
    final email = auth.email ?? 'your email';

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
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AhmaTheme.ahmaRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      text: 'Enter the 6-digit code we sent to ',
                      children: [
                        TextSpan(
                          text: email,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      color: AhmaTheme.mocha.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                  if (auth.infoMessage != null) ...[
                    const SizedBox(height: 16),
                    _InlineNote(message: auth.infoMessage!),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _verify(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w600,
                      color: AhmaTheme.mocha,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _InlineError(message: auth.errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: busy ? null : _verify,
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
                        : const Text('Verify & sign in'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => ref.read(authProvider.notifier).resendCode(),
                        child: const Text('Resend code'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () =>
                                  ref.read(authProvider.notifier).backToLogin(),
                        child: const Text('Use a different email'),
                      ),
                    ],
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

class _InlineNote extends StatelessWidget {
  final String message;

  const _InlineNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AhmaTheme.sageGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AhmaTheme.sageGreen.withValues(alpha: 0.45)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 14,
          color: AhmaTheme.mocha,
          height: 1.35,
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
