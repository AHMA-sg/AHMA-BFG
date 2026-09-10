import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ahma_app/data/datasources/profile_api.dart';
import 'package:ahma_app/data/models/profile_models.dart';

void main() {
  test(
    'profile creation sends signup token and parses returned session',
    () async {
      final adapter = _ProfileCreateAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final request = ProfileCreateRequest(
        displayName: 'Sam',
        relationship: 'parent',
        careRecipientName: 'Mum',
        caregivingDuration: '1_to_3_years',
        primaryCaregivingChallenge: 'emotional_burnout',
        primarySupportNeed: 'respite_options',
        financialStrainSeverity: 'moderate',
      );

      final result = await ProfileApi(
        dio: dio,
        bearerToken: () async => 'existing-session-token',
      ).createProfile(request, signupToken: 'verified-email-token');

      expect(adapter.authorization, 'Bearer verified-email-token');
      expect(result.userId, 'user-id');
      expect(result.token, 'session-token');
      expect(result.profile.email, 'new@example.com');
      expect(request.toJson(), isNot(contains('email')));
      expect(request.toJson(), isNot(contains('userId')));
    },
  );
}

class _ProfileCreateAdapter implements HttpClientAdapter {
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorization = options.headers['Authorization'] as String?;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'token': 'session-token',
        'userId': 'user-id',
        'expiresAt': '2026-09-01T00:00:00Z',
        'profile': {
          'userId': 'user-id',
          'displayName': 'Sam',
          'email': 'new@example.com',
          'phone': null,
          'careRecipient': {
            'relationship': 'parent',
            'displayName': 'Mum',
            'ageRange': null,
            'conditionCategory': null,
          },
          'caregiverContext': {
            'caregivingDuration': '1_to_3_years',
            'primaryCaregivingChallenge': 'emotional_burnout',
            'secondaryCaregivingChallenges': [],
            'primarySupportNeed': 'respite_options',
            'secondarySupportNeeds': [],
            'financialStrainSeverity': 'moderate',
            'existingSupportNetwork': [],
          },
          'createdAt': '2026-08-12T00:00:00Z',
          'updatedAt': '2026-08-12T00:00:00Z',
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
