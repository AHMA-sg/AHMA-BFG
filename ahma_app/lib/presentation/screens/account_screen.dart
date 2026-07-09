import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../../core/utils/contact_format.dart';
import '../../data/datasources/backend_api.dart';
import '../../data/datasources/profile_api.dart';
import '../../data/models/profile_models.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Account page, reached from the dashboard's top-right avatar.
///
/// Renders the in-memory profile from the launch gate with human-readable
/// option labels, supports editing every v1 field via a partial PATCH
/// (only changed fields are sent), and hosts the log-out action.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _recipientNameController = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  String? _relationship;
  String? _caregivingDuration;
  String? _primaryChallenge;
  String? _primarySupportNeed;
  String? _financialStrain;
  bool _checkingGoogle = true;
  bool _calendarConnected = false;
  bool _gmailConnected = false;
  bool _gmailConfigured = false;
  String? _googleStatusMessage;

  /// Backend dotted field path -> inline message.
  Map<String, String> _fieldErrors = {};
  String? _formError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _recipientNameController.dispose();
    super.dispose();
  }

  void _startEditing(UserProfile profile) {
    setState(() {
      _editing = true;
      _fieldErrors = {};
      _formError = null;
      _nameController.text = profile.displayName;
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phone ?? '';
      _recipientNameController.text = profile.careRecipient.displayName;
      _relationship = _valueOrNull(profile.careRecipient.relationship);
      _caregivingDuration = _valueOrNull(
        profile.caregiverContext.caregivingDuration,
      );
      _primaryChallenge = _valueOrNull(
        profile.caregiverContext.primaryCaregivingChallenge,
      );
      _primarySupportNeed = _valueOrNull(
        profile.caregiverContext.primarySupportNeed,
      );
      _financialStrain = _valueOrNull(
        profile.caregiverContext.financialStrainSeverity,
      );
    });
  }

  static String? _valueOrNull(String value) => value.isEmpty ? null : value;

  Future<void> _refreshGoogleStatus(UserProfile profile) async {
    setState(() {
      _checkingGoogle = true;
      _googleStatusMessage = null;
    });

    try {
      final backend = BackendApi();
      final calendar = await backend.getCalendarStatus(userId: profile.userId);
      final gmail = await backend.getGmailStatus();
      if (!mounted) return;
      setState(() {
        _checkingGoogle = false;
        _calendarConnected = calendar.connected;
        _gmailConnected = gmail.connected;
        _gmailConfigured = gmail.configured;
        _googleStatusMessage =
            calendar.message ?? gmail.message ?? _googleStatusMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingGoogle = false;
        _googleStatusMessage =
            "We couldn't check Google services. Try again in a moment.";
      });
    }
  }

  Future<void> _connectCalendar(UserProfile profile) async {
    try {
      await BackendApi().startGoogleOAuth(
        service: 'calendar',
        userId: profile.userId,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _googleStatusMessage =
            "We couldn't start Google Calendar sign-in. Check backend OAuth setup.";
      });
    }
  }

  Future<void> _disconnectCalendar(UserProfile profile) async {
    await BackendApi().disconnectCalendar(userId: profile.userId);
    if (!mounted) return;
    setState(() {
      _calendarConnected = false;
      _googleStatusMessage = 'Google Calendar disconnected on this device.';
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _saving = false;
      _fieldErrors = {};
      _formError = null;
    });
  }

  Future<void> _save(UserProfile profile) async {
    final errors = <String, String>{};
    final patch = ProfilePatchRequest();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      errors['displayName'] = 'Please share a name.';
    } else if (name != profile.displayName) {
      patch.setDisplayName(name);
    }

    final rawEmail = _emailController.text.trim();
    final rawPhone = _phoneController.text.trim();
    if (rawEmail.isEmpty && rawPhone.isEmpty) {
      errors['email'] =
          'Keep at least one way to reach you — an email or a phone number.';
    }
    String? email;
    if (rawEmail.isNotEmpty) {
      email = normalizeEmail(rawEmail);
      if (email == null) {
        errors['email'] = "That email doesn't look right — mind checking it?";
      }
    }
    String? phone;
    if (rawPhone.isNotEmpty) {
      phone = normalizePhone(rawPhone);
      if (phone == null) {
        errors['phone'] =
            "That phone number doesn't look right. "
            'Include the country code, e.g. +65 9123 4567.';
      }
    }

    final recipientName = _recipientNameController.text.trim();
    if (recipientName.isEmpty) {
      errors['careRecipient.displayName'] = "What's their name?";
    }

    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
        _formError = null;
      });
      return;
    }

    if (email != profile.email) patch.setEmail(email);
    if (phone != profile.phone) patch.setPhone(phone);
    if (recipientName != profile.careRecipient.displayName) {
      patch.setCareRecipientField('displayName', recipientName);
    }
    final relationship = _relationship;
    if (relationship != null &&
        relationship != profile.careRecipient.relationship) {
      patch.setCareRecipientField('relationship', relationship);
    }
    final contextChanges = <String, String?>{
      'caregivingDuration': _caregivingDuration,
      'primaryCaregivingChallenge': _primaryChallenge,
      'primarySupportNeed': _primarySupportNeed,
      'financialStrainSeverity': _financialStrain,
    };
    final currentContext = <String, String>{
      'caregivingDuration': profile.caregiverContext.caregivingDuration,
      'primaryCaregivingChallenge':
          profile.caregiverContext.primaryCaregivingChallenge,
      'primarySupportNeed': profile.caregiverContext.primarySupportNeed,
      'financialStrainSeverity':
          profile.caregiverContext.financialStrainSeverity,
    };
    contextChanges.forEach((field, value) {
      if (value != null && value != currentContext[field]) {
        patch.setCaregiverContextField(field, value);
      }
    });

    if (patch.isEmpty) {
      _cancelEditing();
      return;
    }

    setState(() {
      _saving = true;
      _fieldErrors = {};
      _formError = null;
    });

    try {
      await ref.read(profileGateProvider.notifier).updateProfile(patch);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your details are saved.')));
    } on ProfileValidationException catch (e) {
      _showBackendFieldErrors(e.fieldErrors);
    } on ContactAlreadyExistsException catch (e) {
      _showBackendFieldErrors(
        e.fieldErrors.isEmpty ? const {'email': []} : e.fieldErrors,
        fallbackMessage:
            'That contact is already registered to another profile.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError =
            "We couldn't save your changes — check your connection and "
            'try again.';
      });
    }
  }

  void _showBackendFieldErrors(
    Map<String, List<String>> fieldErrors, {
    String? fallbackMessage,
  }) {
    if (!mounted) return;
    final mapped = <String, String>{};
    fieldErrors.forEach((path, codes) {
      mapped[path] =
          fallbackMessage ??
          _copyForFieldError(codes.isEmpty ? '' : codes.first);
    });
    setState(() {
      _saving = false;
      _fieldErrors = mapped;
      _formError = mapped.isEmpty
          ? (fallbackMessage ?? "Something went wrong — let's try again.")
          : null;
    });
  }

  static String _copyForFieldError(String code) {
    switch (code) {
      case 'invalid_email':
        return "That email doesn't look right — mind checking it?";
      case 'invalid_phone':
        return "That phone number doesn't look right. "
            'Include the country code, e.g. +65 9123 4567.';
      case 'required_without_contact':
        return 'Keep at least one way to reach you — an email or a phone '
            'number.';
      case 'required':
        return 'This one is needed.';
      case 'invalid_option':
        return 'Pick one of the listed choices.';
      default:
        return "This doesn't look right — mind checking it?";
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You can sign back in with the same email to return to this '
          'profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;
    // The root gate now shows the login screen underneath; unwind this
    // pushed route so it is visible.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileGateProvider).profile;
    final optionsAsync = ref.watch(profileOptionsProvider);

    if (profile != null && _checkingGoogle) {
      Future.microtask(() => _refreshGoogleStatus(profile));
    }

    return Scaffold(
      backgroundColor: AhmaTheme.background,
      appBar: AppBar(
        backgroundColor: AhmaTheme.background,
        elevation: 0,
        foregroundColor: AhmaTheme.mocha,
        title: Text(
          'Your account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 20,
            color: AhmaTheme.mocha,
          ),
        ),
        actions: [
          if (profile != null && !_editing)
            TextButton.icon(
              onPressed: optionsAsync.hasValue
                  ? () => _startEditing(profile)
                  : null,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(foregroundColor: AhmaTheme.sageGreen),
            ),
          if (_editing)
            TextButton(
              onPressed: _saving ? null : _cancelEditing,
              style: TextButton.styleFrom(foregroundColor: AhmaTheme.sageGreen),
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: profile == null
          ? const Center(child: Text('No profile loaded.'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _editing
                      ? _buildEditForm(context, profile, optionsAsync)
                      : _buildDetails(context, profile, optionsAsync),
                ),
              ),
            ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    UserProfile profile,
    AsyncValue<ProfileOptions> optionsAsync,
  ) {
    // Labels fall back to raw option values while options load or if the
    // fetch failed; editing is disabled until options are available.
    final options = optionsAsync.valueOrNull;
    String label(String group, String field, String value) =>
        options?.labelFor(group, field, value) ?? value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (optionsAsync.hasError)
          _NoticeBanner(
            message:
                "We couldn't load the choice labels, so some values may "
                'look technical.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(profileOptionsProvider),
          ),
        _SectionCard(
          title: 'About you',
          children: [
            _InfoRow(label: 'Name', value: profile.displayName),
            _InfoRow(label: 'Email', value: profile.email ?? '—'),
            _InfoRow(label: 'Phone', value: profile.phone ?? '—'),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Caring for',
          children: [
            _InfoRow(label: 'Name', value: profile.careRecipient.displayName),
            _InfoRow(
              label: 'Relationship',
              value: label(
                'careRecipient',
                'relationship',
                profile.careRecipient.relationship,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Your caregiving context',
          children: [
            _InfoRow(
              label: 'Caregiving for',
              value: label(
                'caregiverContext',
                'caregivingDuration',
                profile.caregiverContext.caregivingDuration,
              ),
            ),
            _InfoRow(
              label: 'Hardest part right now',
              value: label(
                'caregiverContext',
                'primaryCaregivingChallenge',
                profile.caregiverContext.primaryCaregivingChallenge,
              ),
            ),
            _InfoRow(
              label: 'Support that would help most',
              value: label(
                'caregiverContext',
                'primarySupportNeed',
                profile.caregiverContext.primarySupportNeed,
              ),
            ),
            _InfoRow(
              label: 'Financial strain',
              value: label(
                'caregiverContext',
                'financialStrainSeverity',
                profile.caregiverContext.financialStrainSeverity,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Connected services',
          children: [
            _InfoRow(
              label: 'Google Calendar',
              value: _checkingGoogle
                  ? 'Checking...'
                  : (_calendarConnected ? 'Connected' : 'Not connected'),
            ),
            _InfoRow(
              label: 'AHMA Gmail',
              value: _checkingGoogle
                  ? 'Checking...'
                  : (_gmailConnected
                        ? 'Connected'
                        : (_gmailConfigured
                              ? 'Needs reconnection'
                              : 'Not set up')),
            ),
            if (_googleStatusMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(
                  _googleStatusMessage!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13.5,
                    color: AhmaTheme.mocha.withValues(alpha: 0.68),
                    height: 1.3,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _checkingGoogle
                        ? null
                        : (_calendarConnected
                              ? () => _disconnectCalendar(profile)
                              : () => _connectCalendar(profile)),
                    icon: Icon(
                      _calendarConnected
                          ? Icons.link_off_rounded
                          : Icons.calendar_month_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _calendarConnected
                          ? 'Disconnect Calendar'
                          : 'Connect Calendar',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AhmaTheme.sageGreen,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh Google service status',
                    onPressed: _checkingGoogle
                        ? null
                        : () => _refreshGoogleStatus(profile),
                    icon: const Icon(Icons.refresh_rounded),
                    color: AhmaTheme.sageGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: AhmaTheme.ahmaRed,
            side: BorderSide(color: AhmaTheme.ahmaRed.withValues(alpha: 0.5)),
            textStyle: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    UserProfile profile,
    AsyncValue<ProfileOptions> optionsAsync,
  ) {
    final options = optionsAsync.valueOrNull;
    if (options == null) {
      // Edit is only reachable once options load, but guard anyway.
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_formError != null) ...[
          _NoticeBanner(message: _formError!),
          const SizedBox(height: 6),
        ],
        _SectionCard(
          title: 'About you',
          children: [
            _LabeledTextField(
              label: 'Name',
              controller: _nameController,
              enabled: !_saving,
              errorText: _fieldErrors['displayName'],
            ),
            _LabeledTextField(
              label: 'Email',
              controller: _emailController,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              hint: 'you@example.com',
              errorText: _fieldErrors['email'],
            ),
            _LabeledTextField(
              label: 'Phone',
              controller: _phoneController,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              hint: '+65 9123 4567',
              errorText: _fieldErrors['phone'],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Caring for',
          children: [
            _LabeledTextField(
              label: 'Name',
              controller: _recipientNameController,
              enabled: !_saving,
              errorText: _fieldErrors['careRecipient.displayName'],
            ),
            _LabeledDropdown(
              label: 'Relationship',
              value: _relationship,
              options: options.relationshipOptions,
              enabled: !_saving,
              errorText: _fieldErrors['careRecipient.relationship'],
              onChanged: (value) => setState(() => _relationship = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Your caregiving context',
          children: [
            _LabeledDropdown(
              label: 'Caregiving for',
              value: _caregivingDuration,
              options: options.caregivingDurationOptions,
              enabled: !_saving,
              errorText: _fieldErrors['caregiverContext.caregivingDuration'],
              onChanged: (value) => setState(() => _caregivingDuration = value),
            ),
            _LabeledDropdown(
              label: 'Hardest part right now',
              value: _primaryChallenge,
              options: options.primaryChallengeOptions,
              enabled: !_saving,
              errorText:
                  _fieldErrors['caregiverContext.primaryCaregivingChallenge'],
              onChanged: (value) => setState(() => _primaryChallenge = value),
            ),
            _LabeledDropdown(
              label: 'Support that would help most',
              value: _primarySupportNeed,
              options: options.primarySupportNeedOptions,
              enabled: !_saving,
              errorText: _fieldErrors['caregiverContext.primarySupportNeed'],
              onChanged: (value) => setState(() => _primarySupportNeed = value),
            ),
            _LabeledDropdown(
              label: 'Financial strain',
              value: _financialStrain,
              options: options.financialStrainOptions,
              enabled: !_saving,
              errorText:
                  _fieldErrors['caregiverContext.financialStrainSeverity'],
              onChanged: (value) => setState(() => _financialStrain = value),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(profile),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save changes'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8D7C5), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AhmaTheme.labelTextStyle.copyWith(
              fontSize: 11,
              color: AhmaTheme.sageGreen,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                color: AhmaTheme.mocha.withValues(alpha: 0.62),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15.5,
                color: AhmaTheme.mocha,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? hint;
  final String? errorText;

  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.hint,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AhmaTheme.mocha.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            autocorrect: false,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: AhmaTheme.mocha,
            ),
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              errorMaxLines: 3,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<ProfileOption> options;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.enabled,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final knownValues = options.map((o) => o.value).toSet();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AhmaTheme.mocha.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: knownValues.contains(value) ? value : null,
            isExpanded: true,
            items: [
              for (final option in options)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: enabled ? onChanged : null,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: AhmaTheme.mocha,
            ),
            decoration: InputDecoration(
              errorText: errorText,
              errorMaxLines: 3,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NoticeBanner({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AhmaTheme.palePink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AhmaTheme.palePink.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                color: AhmaTheme.mocha,
                height: 1.35,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AhmaTheme.sageGreen),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
