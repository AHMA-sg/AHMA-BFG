import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../../data/models/profile_models.dart';
import '../providers/onboarding_provider.dart';

/// Conversational profile onboarding (variant B).
///
/// AHMA asks the 8 required questions one at a time with a warm
/// care-companion tone: quick replies for option fields (labels rendered,
/// values submitted), a lightweight text input for the free-text answers,
/// a visible "Question N of 8" progress cue, and inline recoverable errors.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _textController = TextEditingController();
  int _lastQuestionIndex = -1;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    // Restore the stored answer when (re)entering a text question, so
    // "going back" or being routed to a failed question keeps the answer
    // editable instead of blanking it.
    if (state.phase == OnboardingPhase.question &&
        state.questionIndex != _lastQuestionIndex) {
      _lastQuestionIndex = state.questionIndex;
      final field = state.currentQuestion.field;
      _textController.text = state.answers[field] ?? '';
    }

    return Scaffold(
      backgroundColor: AhmaTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, OnboardingState state) {
    switch (state.phase) {
      case OnboardingPhase.loadingOptions:
        return const _CenteredStatus(
          spinner: true,
          message: 'Getting things ready for you…',
        );
      case OnboardingPhase.optionsError:
        return _CenteredStatus(
          icon: Icons.cloud_off_rounded,
          message:
              "We couldn't load what we need to get started. "
              'The service may still be waking up, which can take up to a '
              'minute. Please try again.',
          actionLabel: 'Try again',
          onAction: () => ref.read(onboardingProvider.notifier).loadOptions(),
        );
      case OnboardingPhase.submitting:
        return const _CenteredStatus(
          spinner: true,
          message: 'Saving your details…',
        );
      case OnboardingPhase.submitError:
        return _CenteredStatus(
          icon: Icons.cloud_off_rounded,
          message:
              state.submitErrorMessage ??
              "Something went wrong — let's try that again.",
          actionLabel: 'Try again',
          onAction: () => ref.read(onboardingProvider.notifier).retrySubmit(),
        );
      case OnboardingPhase.question:
        return _buildQuestion(context, state);
    }
  }

  Widget _buildQuestion(BuildContext context, OnboardingState state) {
    final question = state.currentQuestion;
    final questionNumber = state.questionIndex + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressHeader(
          questionNumber: questionNumber,
          totalQuestions: onboardingQuestionCount,
        ),
        const SizedBox(height: 28),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestionBubble(prompt: question.prompt),
                if (state.inlineError != null) ...[
                  const SizedBox(height: 14),
                  _InlineError(message: state.inlineError!),
                ],
                const SizedBox(height: 24),
                if (question.isQuickReply)
                  _QuickReplies(
                    options: state.quickRepliesFor(question),
                    onSelected: (option) => ref
                        .read(onboardingProvider.notifier)
                        .selectQuickReply(option),
                  )
                else
                  _TextAnswerField(
                    controller: _textController,
                    hint: question.hint,
                    keyboardType: question.field == OnboardingField.contact
                        ? TextInputType.emailAddress
                        : TextInputType.name,
                    onSubmit: (value) =>
                        ref.read(onboardingProvider.notifier).submitText(value),
                  ),
              ],
            ),
          ),
        ),
        if (state.questionIndex > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => ref.read(onboardingProvider.notifier).goBack(),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AhmaTheme.sageGreen,
                minimumSize: const Size(48, 48),
                textStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int questionNumber;
  final int totalQuestions;

  const _ProgressHeader({
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'AHMA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AhmaTheme.ahmaRed,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Question $questionNumber of $totalQuestions',
              style: AhmaTheme.labelTextStyle.copyWith(
                fontSize: 13,
                color: AhmaTheme.sageGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: questionNumber / totalQuestions,
            minHeight: 6,
            backgroundColor: AhmaTheme.mid.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AhmaTheme.sageGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  final String prompt;

  const _QuestionBubble({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: const Color(0xFFE8D7C5), width: 1.3),
      ),
      child: Text(
        prompt,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 22,
          color: AhmaTheme.mocha,
          height: 1.3,
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

class _QuickReplies extends StatelessWidget {
  final List<ProfileOption> options;
  final ValueChanged<ProfileOption> onSelected;

  const _QuickReplies({required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in options)
          Material(
            color: Colors.white.withValues(alpha: 0.75),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: AhmaTheme.sageGreen.withValues(alpha: 0.45),
                width: 1.3,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onSelected(option),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    color: AhmaTheme.mocha,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TextAnswerField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;
  final ValueChanged<String> onSubmit;

  const _TextAnswerField({
    required this.controller,
    this.hint,
    required this.keyboardType,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmit,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 17,
              color: AhmaTheme.mocha,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                color: AhmaTheme.mocha.withValues(alpha: 0.38),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          height: 52,
          child: Material(
            color: AhmaTheme.sageGreen,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSubmit(controller.text),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  final bool spinner;
  final IconData? icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredStatus({
    this.spinner = false,
    this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (spinner)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AhmaTheme.sageGreen,
                  ),
                ),
              )
            else if (icon != null)
              Icon(icon, size: 44, color: AhmaTheme.sageGreen),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 52),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
