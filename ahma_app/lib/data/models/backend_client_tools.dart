import 'dart:convert';

import '../datasources/backend_api.dart';
import '../datasources/local_identity_store.dart';
import 'client_tool_result.dart';

/// Client-side Ultravox tools that need AHMA's signed-in backend session.
class BackendClientTools {
  static const String scheduleToolName = 'scheduleEvent';
  static const String contactSupportToolName = 'contactSupport';

  final BackendApi _backend;
  final LocalIdentityStore _identity;

  BackendClientTools({BackendApi? backend, LocalIdentityStore? identity})
    : _backend = backend ?? BackendApi(),
      _identity = identity ?? LocalIdentityStore();

  Future<ClientToolResult> handle(
    String toolName,
    Map<String, dynamic> parameters, {
    String? callId,
  }) async {
    final userId = await _identity.readUserId();
    if (userId == null) {
      return const ClientToolResult(
        result:
            'The user is not signed in. Ask them to sign in before using this tool.',
        responseType: 'tool-response',
      );
    }

    final backendParameters = Map<String, dynamic>.from(parameters)
      ..['userId'] = userId;
    final result = await _backend.sendToolRequest(
      toolName: toolName,
      parameters: backendParameters,
      callId: callId,
    );

    final succeeded = result['success'] == true;
    final responseText = succeeded
        ? _successMessage(toolName, result)
        : _failureMessage(toolName, result);

    return ClientToolResult(
      result: jsonEncode({...result, 'responseText': responseText}),
      responseType: 'tool-response',
    );
  }

  static String _successMessage(String toolName, Map<String, dynamic> result) {
    if (toolName == scheduleToolName) {
      return 'The event was added to the user\'s personal Google Calendar. '
          'Briefly confirm the event details.';
    }
    return 'The message was sent to AHMA support. Tell the user the team '
        'received it and will follow up using their AHMA account details.';
  }

  static String _failureMessage(String toolName, Map<String, dynamic> result) {
    if (result['needsGoogleCalendarAuth'] == true) {
      return 'The user has not connected Google Calendar. Ask them to open '
          'Account, choose Connect Calendar, and then try again.';
    }
    final error = result['error'] ?? result['message'] ?? 'Unknown error';
    return 'The ${toolName == scheduleToolName ? 'calendar event' : 'support message'} '
        'could not be completed: $error. Apologise briefly and do not claim it succeeded.';
  }
}
