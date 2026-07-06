/// Models for the AHMA profile API (backend_v2 on PROFILE_API_URL).
///
/// Wire shapes are pinned by the backend contract:
/// - GET  /api/profile/options            -> ProfileOptions
/// - POST /api/profile                    -> ProfileCreateRequest / UserProfile
/// - GET  /api/profile/:userId            -> UserProfile
/// - GET  /api/profile/:userId/context    -> ProfileContextData
///
/// Option-backed fields carry raw option `value`s (e.g. `emotional_burnout`),
/// never labels. Use [ProfileOptions.labelFor] to render human-readable text.
library;

/// A single backend-provided choice: quick replies render [label] and
/// submit [value].
class ProfileOption {
  final String value;
  final String label;

  const ProfileOption({required this.value, required this.label});

  factory ProfileOption.fromJson(Map<String, dynamic> json) {
    return ProfileOption(
      value: json['value'] as String,
      label: json['label'] as String? ?? json['value'] as String,
    );
  }
}

/// Payload of GET /api/profile/options.
class ProfileOptions {
  /// group name (`caregiverContext` / `careRecipient`) -> field -> choices.
  final Map<String, Map<String, List<ProfileOption>>> groups;

  const ProfileOptions({required this.groups});

  factory ProfileOptions.fromJson(Map<String, dynamic> json) {
    final groups = <String, Map<String, List<ProfileOption>>>{};
    json.forEach((groupName, fields) {
      if (fields is! Map<String, dynamic>) return;
      final parsedFields = <String, List<ProfileOption>>{};
      fields.forEach((fieldName, choices) {
        if (choices is! List) return;
        parsedFields[fieldName] = choices
            .whereType<Map<String, dynamic>>()
            .map(ProfileOption.fromJson)
            .toList();
      });
      groups[groupName] = parsedFields;
    });
    return ProfileOptions(groups: groups);
  }

  List<ProfileOption> optionsFor(String group, String field) {
    return groups[group]?[field] ?? const [];
  }

  /// Maps a raw option value back to its display label (falls back to the
  /// raw value when unknown).
  String labelFor(String group, String field, String value) {
    for (final option in optionsFor(group, field)) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  List<ProfileOption> get relationshipOptions =>
      optionsFor('careRecipient', 'relationship');
  List<ProfileOption> get caregivingDurationOptions =>
      optionsFor('caregiverContext', 'caregivingDuration');
  List<ProfileOption> get primaryChallengeOptions =>
      optionsFor('caregiverContext', 'primaryCaregivingChallenge');
  List<ProfileOption> get primarySupportNeedOptions =>
      optionsFor('caregiverContext', 'primarySupportNeed');
  List<ProfileOption> get financialStrainOptions =>
      optionsFor('caregiverContext', 'financialStrainSeverity');
}

class CareRecipientProfile {
  final String relationship;
  final String displayName;
  final String? ageRange;
  final String? conditionCategory;

  const CareRecipientProfile({
    required this.relationship,
    required this.displayName,
    this.ageRange,
    this.conditionCategory,
  });

  factory CareRecipientProfile.fromJson(Map<String, dynamic> json) {
    return CareRecipientProfile(
      relationship: json['relationship'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      ageRange: json['ageRange'] as String?,
      conditionCategory: json['conditionCategory'] as String?,
    );
  }
}

class CaregiverContextProfile {
  final String caregivingDuration;
  final String primaryCaregivingChallenge;
  final List<String> secondaryCaregivingChallenges;
  final String primarySupportNeed;
  final List<String> secondarySupportNeeds;
  final String financialStrainSeverity;
  final List<String> existingSupportNetwork;

  const CaregiverContextProfile({
    required this.caregivingDuration,
    required this.primaryCaregivingChallenge,
    this.secondaryCaregivingChallenges = const [],
    required this.primarySupportNeed,
    this.secondarySupportNeeds = const [],
    required this.financialStrainSeverity,
    this.existingSupportNetwork = const [],
  });

  factory CaregiverContextProfile.fromJson(Map<String, dynamic> json) {
    List<String> stringList(Object? value) =>
        value is List ? value.whereType<String>().toList() : const [];

    return CaregiverContextProfile(
      caregivingDuration: json['caregivingDuration'] as String? ?? '',
      primaryCaregivingChallenge:
          json['primaryCaregivingChallenge'] as String? ?? '',
      secondaryCaregivingChallenges: stringList(
        json['secondaryCaregivingChallenges'],
      ),
      primarySupportNeed: json['primarySupportNeed'] as String? ?? '',
      secondarySupportNeeds: stringList(json['secondarySupportNeeds']),
      financialStrainSeverity: json['financialStrainSeverity'] as String? ?? '',
      existingSupportNetwork: stringList(json['existingSupportNetwork']),
    );
  }
}

/// Full profile as returned by POST /api/profile and GET /api/profile/:id.
class UserProfile {
  final String userId;
  final String displayName;
  final String? email;
  final String? phone;
  final CareRecipientProfile careRecipient;
  final CaregiverContextProfile caregiverContext;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.displayName,
    this.email,
    this.phone,
    required this.careRecipient,
    required this.caregiverContext,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      careRecipient: CareRecipientProfile.fromJson(
        (json['careRecipient'] as Map<String, dynamic>?) ?? const {},
      ),
      caregiverContext: CaregiverContextProfile.fromJson(
        (json['caregiverContext'] as Map<String, dynamic>?) ?? const {},
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

/// Compact context from GET /api/profile/:userId/context, used to
/// personalize calls (greeting, metadata). Scalar fields other than the two
/// names are raw option values.
class ProfileContextData {
  final String userId;
  final String displayName;
  final String careRecipientName;
  final String careRecipientRelationship;
  final String caregivingDuration;
  final String primaryCaregivingChallenge;
  final String primarySupportNeed;
  final String financialStrainSeverity;

  const ProfileContextData({
    required this.userId,
    required this.displayName,
    required this.careRecipientName,
    required this.careRecipientRelationship,
    required this.caregivingDuration,
    required this.primaryCaregivingChallenge,
    required this.primarySupportNeed,
    required this.financialStrainSeverity,
  });

  factory ProfileContextData.fromJson(Map<String, dynamic> json) {
    return ProfileContextData(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      careRecipientName: json['careRecipientName'] as String? ?? '',
      careRecipientRelationship:
          json['careRecipientRelationship'] as String? ?? '',
      caregivingDuration: json['caregivingDuration'] as String? ?? '',
      primaryCaregivingChallenge:
          json['primaryCaregivingChallenge'] as String? ?? '',
      primarySupportNeed: json['primarySupportNeed'] as String? ?? '',
      financialStrainSeverity: json['financialStrainSeverity'] as String? ?? '',
    );
  }

  /// Flat string map suitable for Ultravox call metadata.
  Map<String, String> toCallMetadata() {
    return {
      'userId': userId,
      'careRecipientRelationship': careRecipientRelationship,
      'caregivingDuration': caregivingDuration,
      'primaryCaregivingChallenge': primaryCaregivingChallenge,
      'primarySupportNeed': primarySupportNeed,
      'financialStrainSeverity': financialStrainSeverity,
    };
  }
}

/// Body for POST /api/profile (create-only, v1 required fields exactly —
/// optional profile fields are intentionally omitted so the backend applies
/// its own defaults).
class ProfileCreateRequest {
  final String userId;
  final String displayName;
  final String? email;
  final String? phone;
  final String relationship;
  final String careRecipientName;
  final String caregivingDuration;
  final String primaryCaregivingChallenge;
  final String primarySupportNeed;
  final String financialStrainSeverity;

  const ProfileCreateRequest({
    required this.userId,
    required this.displayName,
    this.email,
    this.phone,
    required this.relationship,
    required this.careRecipientName,
    required this.caregivingDuration,
    required this.primaryCaregivingChallenge,
    required this.primarySupportNeed,
    required this.financialStrainSeverity,
  });

  ProfileCreateRequest copyWith({String? userId}) {
    return ProfileCreateRequest(
      userId: userId ?? this.userId,
      displayName: displayName,
      email: email,
      phone: phone,
      relationship: relationship,
      careRecipientName: careRecipientName,
      caregivingDuration: caregivingDuration,
      primaryCaregivingChallenge: primaryCaregivingChallenge,
      primarySupportNeed: primarySupportNeed,
      financialStrainSeverity: financialStrainSeverity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      // Always send BOTH contact keys (null for the unused one): the
      // backend repository binds :email/:phone unconditionally in its
      // INSERT, so omitting a key entirely causes a 500. Explicit null
      // stores the same state and validates the same way.
      'email': email,
      'phone': phone,
      'careRecipient': {
        'relationship': relationship,
        'displayName': careRecipientName,
      },
      'caregiverContext': {
        'caregivingDuration': caregivingDuration,
        'primaryCaregivingChallenge': primaryCaregivingChallenge,
        'primarySupportNeed': primarySupportNeed,
        'financialStrainSeverity': financialStrainSeverity,
      },
    };
  }
}
