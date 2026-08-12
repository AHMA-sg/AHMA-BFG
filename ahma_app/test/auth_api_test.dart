import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ahma_app/data/datasources/auth_api.dart';

void main() {
  test('verify routes an existing email to a session', () async {
    final dio = Dio()
      ..httpClientAdapter = _JsonAdapter({
        'success': true,
        'next': 'session',
        'token': 'session-token',
        'userId': 'user-id',
        'expiresAt': '2026-09-01T00:00:00Z',
      });

    final result = await AuthApi(
      dio: dio,
    ).verifyCode('returning@example.com', '123456');

    expect(result, isA<AuthSession>());
    final session = result as AuthSession;
    expect(session.token, 'session-token');
    expect(session.userId, 'user-id');
  });

  test('verify routes a new email to onboarding', () async {
    final dio = Dio()
      ..httpClientAdapter = _JsonAdapter({
        'success': true,
        'next': 'onboarding',
        'signupToken': 'signup-token',
        'expiresAt': '2026-08-12T01:00:00Z',
      });

    final result = await AuthApi(
      dio: dio,
    ).verifyCode('new@example.com', '123456');

    expect(result, isA<SignupAuthorization>());
    expect((result as SignupAuthorization).token, 'signup-token');
  });
}

class _JsonAdapter implements HttpClientAdapter {
  final Map<String, dynamic> body;

  _JsonAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
