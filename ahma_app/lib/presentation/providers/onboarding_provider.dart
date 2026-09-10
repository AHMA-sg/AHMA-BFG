import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/profile_api.dart';
import '../../data/models/profile_models.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';

/// The 7 onboarding questions, asked after the user's email is verified.
enum OnboardingField {
  displayName, // Q1, free text
  relationship, // Q2, quick replies
  careRecipientName, // Q3, free text
  caregivingDuration, // Q4, quick replies
  primaryCaregivingChallenge, // Q5, quick replies
  primarySupportNeed, // Q6, quick replies
  financialStrainSeverity, // Q7, quick replies
}

const int onboardingQuestionCount = 7;

class OnboardingQuestion {
  final OnboardingField field;
  final String prompt;
  final String? hint;
  final bool isQuickReply;

  const OnboardingQuestion({
    required this.field,
    required this.prompt,
    this.hint,
    required this.isQuickReply,
  });
}

const List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    field: OnboardingField.displayName,
    prompt: "Hi, I'm AHMA. What can I call you?",
    hint: 'Your name',
    isQuickReply: false,
  ),
  OnboardingQuestion(
    field: OnboardingField.relationship,
    prompt: 'Who are you caring for?',
    isQuickReply: true,
  ),
  OnboardingQuestion(
    field: OnboardingField.careRecipientName,
    prompt: "What's their name?",
    hint: 'Their name',
    isQuickReply: false,
  ),
  OnboardingQuestion(
    field: OnboardingField.caregivingDuration,
    prompt: 'How long have you been caring for them?',
    isQuickReply: true,
  ),
  OnboardingQuestion(
    field: OnboardingField.primaryCaregivingChallenge,
    prompt: "What's the hardest part of caregiving right now?",
    isQuickReply: true,
  ),
  OnboardingQuestion(
    field: OnboardingField.primarySupportNeed,
    prompt: 'What kind of support would help you most?',
    isQuickReply: true,
  ),
  OnboardingQuestion(
    field: OnboardingField.financialStrainSeverity,
    prompt: 'How much financial strain are you feeling?',
    isQuickReply: true,
  ),
];

enum OnboardingPhase {
  loadingOptions,
  optionsError, // retriable — never fabricate options
  question,
  submitting,
  submitError, // retriable network/server failure at submit
}

class OnboardingState {
  final OnboardingPhase phase;
  final ProfileOptions? options;
  final int questionIndex; // 0-based; progress cue renders "N of 7"
  final Map<OnboardingField, String> answers;

  /// Warm inline error for the CURRENT question, or null.
  final String? inlineError;

  /// Message for the retriable submit-failure state.
  final String? submitErrorMessage;

  const OnboardingState({
    this.phase = OnboardingPhase.loadingOptions,
    this.options,
    this.questionIndex = 0,
    this.answers = const {},
    this.inlineError,
    this.submitErrorMessage,
  });

  OnboardingQuestion get currentQuestion => onboardingQuestions[questionIndex];

  bool get isLastQuestion => questionIndex == onboardingQuestionCount - 1;

  List<ProfileOption> quickRepliesFor(OnboardingQuestion question) {
    final opts = options;
    if (opts == null) return const [];
    switch (question.field) {
      case OnboardingField.relationship:
        return opts.relationshipOptions;
      case OnboardingField.caregivingDuration:
        return opts.caregivingDurationOptions;
      case OnboardingField.primaryCaregivingChallenge:
        return opts.primaryChallengeOptions;
      case OnboardingField.primarySupportNeed:
        return opts.primarySupportNeedOptions;
      case OnboardingField.financialStrainSeverity:
        return opts.financialStrainOptions;
      default:
        return const [];
    }
  }

  OnboardingState copyWith({
    OnboardingPhase? phase,
    ProfileOptions? options,
    int? questionIndex,
    Map<OnboardingField, String>? answers,
    String? inlineError,
    String? submitErrorMessage,
  }) {
    return OnboardingState(
      phase: phase ?? this.phase,
      options: options ?? this.options,
      questionIndex: questionIndex ?? this.questionIndex,
      answers: answers ?? this.answers,
      inlineError: inlineError,
      submitErrorMessage: submitErrorMessage,
    );
  }
}

/// Conversational intake controller.
///
/// - Loads quick-reply choices from GET /api/profile/options (retriable).
/// - Validates free-text answers inline with warm, recoverable copy.
/// - Submits POST /api/profile with the verified-email signup credential.
/// - Maps backend field errors back to their owning question.
/// - Hands the returned session to auth only after a confirmed 201.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ProfileApi _api;
  final Future<void> Function(ProfileCreationResult result) _onCompleted;
  final void Function() _onAuthorizationExpired;
  final String _signupToken;

  OnboardingNotifier(
    this._api, {
    required Future<void> Function(ProfileCreationResult result) onCompleted,
    required void Function() onAuthorizationExpired,
    required String signupToken,
  }) : _onCompleted = onCompleted,
       _onAuthorizationExpired = onAuthorizationExpired,
       _signupToken = signupToken,
       super(const OnboardingState()) {
    loadOptions();
  }

  Future<void> loadOptions() async {
    state = state.copyWith(
      phase: OnboardingPhase.loadingOptions,
      inlineError: null,
      submitErrorMessage: null,
    );
    try {
      final options = await _api.getOptions();
      if (!mounted) return;
      state = state.copyWith(phase: OnboardingPhase.question, options: options);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(phase: OnboardingPhase.optionsError);
    }
  }

  /// Submit a free-text answer for the current question.
  Future<void> submitText(String rawInput) async {
    final question = state.currentQuestion;
    final input = rawInput.trim();

    switch (question.field) {
      case OnboardingField.displayName:
        if (input.isEmpty) {
          _setInlineError('What can I call you? Please share a name.');
          return;
        }
        await _storeAnswerAndAdvance(OnboardingField.displayName, input);
      case OnboardingField.careRecipientName:
        if (input.isEmpty) {
          _setInlineError("What's their name?");
          return;
        }
        await _storeAnswerAndAdvance(OnboardingField.careRecipientName, input);
      default:
        // Quick-reply questions never submit free text.
        break;
    }
  }

  /// Submit a quick-reply answer (stores the option VALUE, renders label).
  Future<void> selectQuickReply(ProfileOption option) async {
    final question = state.currentQuestion;
    if (!question.isQuickReply) return;
    await _storeAnswerAndAdvance(question.field, option.value);
  }

  void goBack() {
    if (state.questionIndex == 0 || state.phase != OnboardingPhase.question) {
      return;
    }
    state = state.copyWith(
      questionIndex: state.questionIndex - 1,
      inlineError: null,
    );
  }

  /// Retry a failed submit with the same answers.
  Future<void> retrySubmit() => _submitProfile();

  Future<void> _storeAnswerAndAdvance(
    OnboardingField field,
    String value,
  ) async {
    final answers = Map<OnboardingField, String>.from(state.answers);
    answers[field] = value;

    // Submit when the intake is complete: either we just answered the last
    // question on the initial pass, or every field is already filled and the
    // user is correcting a field after backend validation routed them to an
    // earlier question. In that case, resubmit immediately instead of
    // making the user re-tap through the already-answered later questions.
    final isComplete = OnboardingField.values.every(
      (f) => answers.containsKey(f),
    );

    if (state.isLastQuestion || isComplete) {
      state = state.copyWith(answers: answers, inlineError: null);
      await _submitProfile();
    } else {
      state = state.copyWith(
        answers: answers,
        questionIndex: state.questionIndex + 1,
        inlineError: null,
      );
    }
  }

  Future<void> _submitProfile() async {
    final request = _buildRequest();
    if (request == null) return;

    state = state.copyWith(
      phase: OnboardingPhase.submitting,
      inlineError: null,
      submitErrorMessage: null,
    );

    try {
      final result = await _api.createProfile(
        request,
        signupToken: _signupToken,
      );

      if (!mounted) return;
      await _onCompleted(result);
    } on ProfileValidationException catch (e) {
      _handleFieldErrors(e.fieldErrors);
    } on ProfileUnauthorizedException {
      _onAuthorizationExpired();
    } on ProfileApiUnavailableException {
      _showSubmitError(
        "We couldn't reach the profile service. Your answers are safe — "
        'try again in a moment.',
      );
    } on ProfileApiException {
      _showSubmitError("Something went wrong — let's try that again.");
    } catch (_) {
      _showSubmitError("Something went wrong — let's try that again.");
    }
  }

  ProfileCreateRequest? _buildRequest() {
    final answers = state.answers;

    final displayName = answers[OnboardingField.displayName];
    final relationship = answers[OnboardingField.relationship];
    final recipientName = answers[OnboardingField.careRecipientName];
    final duration = answers[OnboardingField.caregivingDuration];
    final challenge = answers[OnboardingField.primaryCaregivingChallenge];
    final supportNeed = answers[OnboardingField.primarySupportNeed];
    final strain = answers[OnboardingField.financialStrainSeverity];

    if (displayName == null ||
        relationship == null ||
        recipientName == null ||
        duration == null ||
        challenge == null ||
        supportNeed == null ||
        strain == null) {
      // Should be unreachable — every question stores before advancing.
      _showSubmitError("Something went wrong — let's try that again.");
      return null;
    }

    return ProfileCreateRequest(
      displayName: displayName,
      relationship: relationship,
      careRecipientName: recipientName,
      caregivingDuration: duration,
      primaryCaregivingChallenge: challenge,
      primarySupportNeed: supportNeed,
      financialStrainSeverity: strain,
    );
  }

  /// Routes backend field errors to the owning question with warm copy.
  void _handleFieldErrors(Map<String, List<String>> fieldErrors) {
    for (final entry in _fieldErrorRouting) {
      final codes = fieldErrors[entry.path];
      if (codes == null || codes.isEmpty) continue;
      _jumpToQuestion(entry.field, entry.copyFor(codes.first));
      return;
    }

    // userId / requestBody / unknown paths: not tied to a question.
    _showSubmitError("Something went wrong — let's try that again.");
  }

  void _jumpToQuestion(OnboardingField field, String message) {
    final index = onboardingQuestions.indexWhere((q) => q.field == field);
    state = state.copyWith(
      phase: OnboardingPhase.question,
      questionIndex: index < 0 ? state.questionIndex : index,
      inlineError: message,
      submitErrorMessage: null,
    );
  }

  void _showSubmitError(String message) {
    state = state.copyWith(
      phase: OnboardingPhase.submitError,
      submitErrorMessage: message,
      inlineError: null,
    );
  }

  void _setInlineError(String message) {
    state = state.copyWith(
      phase: OnboardingPhase.question,
      inlineError: message,
    );
  }
}

class _FieldErrorRoute {
  final String path;
  final OnboardingField field;
  final String Function(String code) copyFor;

  const _FieldErrorRoute(this.path, this.field, this.copyFor);
}

/// Backend dotted field path -> owning question + warm copy.
/// Order matters: earlier questions win when several fields fail at once.
final List<_FieldErrorRoute> _fieldErrorRouting = [
  _FieldErrorRoute(
    'displayName',
    OnboardingField.displayName,
    (_) => 'What can I call you? Please share a name.',
  ),
  _FieldErrorRoute(
    'careRecipient.relationship',
    OnboardingField.relationship,
    (_) => 'Who are you caring for? Pick one that fits best.',
  ),
  _FieldErrorRoute(
    'careRecipient.displayName',
    OnboardingField.careRecipientName,
    (_) => "What's their name?",
  ),
  _FieldErrorRoute(
    'caregiverContext.caregivingDuration',
    OnboardingField.caregivingDuration,
    (_) => 'How long have you been caring for them?',
  ),
  _FieldErrorRoute(
    'caregiverContext.primaryCaregivingChallenge',
    OnboardingField.primaryCaregivingChallenge,
    (_) => "What's the hardest part right now?",
  ),
  _FieldErrorRoute(
    'caregiverContext.primarySupportNeed',
    OnboardingField.primarySupportNeed,
    (_) => 'What kind of support would help most?',
  ),
  _FieldErrorRoute(
    'caregiverContext.financialStrainSeverity',
    OnboardingField.financialStrainSeverity,
    (_) => 'How much financial strain are you feeling?',
  ),
];

final onboardingProvider =
    StateNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>((
      ref,
    ) {
      final auth = ref.read(authProvider);
      return OnboardingNotifier(
        ref.watch(profileApiProvider),
        onCompleted: (result) =>
            ref.read(authProvider.notifier).completeOnboarding(result),
        onAuthorizationExpired: () =>
            ref.read(authProvider.notifier).signupExpired(),
        signupToken: auth.signupToken!,
      );
    });
