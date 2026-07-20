import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/uuid_v4.dart';
import '../../data/datasources/local_identity_store.dart';
import '../../data/datasources/profile_api.dart';
import '../../data/models/profile_models.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';

/// The 8 onboarding questions, asked one at a time, in this fixed order.
/// `userId` is generated silently at submit and is never a question.
enum OnboardingField {
  displayName, // Q1, free text
  contact, // Q2, free text — email OR phone (one question, not two)
  relationship, // Q3, quick replies
  careRecipientName, // Q4, free text
  caregivingDuration, // Q5, quick replies
  primaryCaregivingChallenge, // Q6, quick replies
  primarySupportNeed, // Q7, quick replies
  financialStrainSeverity, // Q8, quick replies
}

const int onboardingQuestionCount = 8;

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
    field: OnboardingField.contact,
    prompt: 'How can I reach you? An email or a phone number works.',
    hint: 'you@example.com or +65 9123 4567',
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
  final int questionIndex; // 0-based; progress cue renders "N of 8"
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
/// - Submits POST /api/profile with a silently generated UUIDv4 userId;
///   on 409 duplicate_user_id it regenerates and resubmits ONCE.
/// - Maps backend field errors back to their owning question.
/// - Persists the userId only after a confirmed 201, then hands the new
///   profile to the launch gate.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ProfileApi _api;
  final LocalIdentityStore _identity;
  final void Function(UserProfile profile) _onCompleted;
  final void Function(String? email) _onExistingContact;

  /// [initialContact] pre-seeds the contact answer (the email typed at login),
  /// so Q2 shows it pre-filled — the user confirms or edits it rather than
  /// retyping it.
  ///
  /// [onCompleted] fires after a confirmed create (the account now exists, so
  /// auth can email a code). [onExistingContact] fires when create reports the
  /// contact is already registered — the user should sign in, not re-create.
  OnboardingNotifier(
    this._api,
    this._identity, {
    required void Function(UserProfile profile) onCompleted,
    required void Function(String? email) onExistingContact,
    String? initialContact,
  }) : _onCompleted = onCompleted,
       _onExistingContact = onExistingContact,
       super(
         OnboardingState(
           answers: initialContact == null
               ? const {}
               : {OnboardingField.contact: initialContact},
         ),
       ) {
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

  /// Submit a free-text answer for the current question (Q1, Q2, Q4).
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
      case OnboardingField.contact:
        final normalized = _validateContact(input);
        if (normalized == null) return; // inline error already set
        await _storeAnswerAndAdvance(OnboardingField.contact, normalized);
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
    // user is correcting a single field the backend rejected (e.g.
    // contact_already_exists / a validation_error routed us back to an earlier
    // question). In that correction case, resubmit immediately instead of
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

  /// Client-side contact normalization (R16): the single contact answer is
  /// routed to email or phone. Bare 8-digit numbers get the +65 Singapore
  /// prefix so backend normalization can't silently store a wrong country
  /// code.
  String? _validateContact(String input) {
    if (input.isEmpty) {
      _setInlineError(
        "I'll need either an email or a phone number to reach you.",
      );
      return null;
    }

    if (input.contains('@')) {
      final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailPattern.hasMatch(input)) {
        _setInlineError("That email doesn't look right — mind checking it?");
        return null;
      }
      return input.toLowerCase();
    }

    // Phone: strip spaces and common separators.
    var compact = input.replaceAll(RegExp(r'[\s().-]'), '');
    if (RegExp(r'^\d{8}$').hasMatch(compact)) {
      // Bare 8 digits: assume a Singapore local number.
      compact = '+65$compact';
    }
    final phonePattern = RegExp(r'^\+[1-9]\d{7,14}$');
    if (!phonePattern.hasMatch(compact)) {
      _setInlineError(
        "That phone number doesn't look right. "
        'Include the country code, e.g. +65 9123 4567.',
      );
      return null;
    }
    return compact;
  }

  Future<void> _submitProfile() async {
    final request = _buildRequest(generateUuidV4());
    if (request == null) return;

    state = state.copyWith(
      phase: OnboardingPhase.submitting,
      inlineError: null,
      submitErrorMessage: null,
    );

    try {
      UserProfile profile;
      try {
        profile = await _api.createProfile(request);
      } on DuplicateUserIdException {
        // Practically impossible with a fresh UUID; regenerate and
        // resubmit the identical answers once, silently.
        profile = await _api.createProfile(
          request.copyWith(userId: generateUuidV4()),
        );
      }

      // Persist identity ONLY after the confirmed 201.
      await _identity.saveUserId(profile.userId);
      if (!mounted) return;
      _onCompleted(profile);
    } on ProfileValidationException catch (e) {
      _handleFieldErrors(e.fieldErrors);
    } on ContactAlreadyExistsException {
      final recovered = _completeWithExistingContact(request);
      if (!recovered && mounted) {
        _jumpToQuestion(
          OnboardingField.contact,
          'That contact is already registered. Sign in with the email on that '
          'account, or use a different email.',
        );
      }
    } on DuplicateUserIdException {
      // Second duplicate in a row — fall through to a generic retry.
      _showSubmitError(
        "Something went wrong on our side — let's try that again.",
      );
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

  ProfileCreateRequest? _buildRequest(String userId) {
    final answers = state.answers;
    final contact = answers[OnboardingField.contact] ?? '';
    final isEmail = contact.contains('@');

    final displayName = answers[OnboardingField.displayName];
    final relationship = answers[OnboardingField.relationship];
    final recipientName = answers[OnboardingField.careRecipientName];
    final duration = answers[OnboardingField.caregivingDuration];
    final challenge = answers[OnboardingField.primaryCaregivingChallenge];
    final supportNeed = answers[OnboardingField.primarySupportNeed];
    final strain = answers[OnboardingField.financialStrainSeverity];

    if (displayName == null ||
        contact.isEmpty ||
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
      userId: userId,
      displayName: displayName,
      email: isEmail ? contact : null,
      phone: isEmail ? null : contact,
      relationship: relationship,
      careRecipientName: recipientName,
      caregivingDuration: duration,
      primaryCaregivingChallenge: challenge,
      primarySupportNeed: supportNeed,
      financialStrainSeverity: strain,
    );
  }

  /// The contact already owns an account. There is no way to fetch that
  /// profile without its session, so route the user to sign in with a code.
  /// Only works for an email contact (OTP is email-based); a phone-only
  /// conflict falls through to a "use your email" prompt.
  bool _completeWithExistingContact(ProfileCreateRequest request) {
    if (request.email == null || request.email!.isEmpty) {
      return false;
    }
    _onExistingContact(request.email);
    return true;
  }

  /// Routes backend field errors to the owning question with warm copy.
  /// `required_without_contact` arrives on BOTH email and phone but renders
  /// once, on the contact question.
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

String _contactCopy(String code) {
  switch (code) {
    case 'invalid_email':
      return "That email doesn't look right — mind checking it?";
    case 'invalid_phone':
      return "That phone number doesn't look right. "
          'Include the country code, e.g. +65 9123 4567.';
    default:
      return "I'll need either an email or a phone number to reach you.";
  }
}

/// Backend dotted field path -> owning question + warm copy.
/// Order matters: earlier questions win when several fields fail at once.
final List<_FieldErrorRoute> _fieldErrorRouting = [
  _FieldErrorRoute(
    'displayName',
    OnboardingField.displayName,
    (_) => 'What can I call you? Please share a name.',
  ),
  _FieldErrorRoute('email', OnboardingField.contact, _contactCopy),
  _FieldErrorRoute('phone', OnboardingField.contact, _contactCopy),
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
      return OnboardingNotifier(
        ref.watch(profileApiProvider),
        ref.watch(localIdentityStoreProvider),
        // Account now exists -> email a code and move to verification.
        onCompleted: (profile) =>
            ref.read(authProvider.notifier).completeSignup(profile.email),
        // Contact already registered -> sign in instead of creating a dupe.
        onExistingContact: (email) =>
            ref.read(authProvider.notifier).signInExisting(email),
        // Pre-fill Q2 with the email typed at login (read, not watch: the
        // intake shouldn't restart if auth state changes mid-flow).
        initialContact: ref.read(authProvider).email,
      );
    });
