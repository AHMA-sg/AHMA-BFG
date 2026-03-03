/// Simple call model for POC
class CallModel {
  final String callId;
  final String? agentId;
  final String joinUrl;
  final DateTime created;
  final CallStage stage;
  final List<Message> transcript;

  CallModel({
    required this.callId,
    this.agentId,
    required this.joinUrl,
    required this.created,
    this.stage = CallStage.assess,
    this.transcript = const [],
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      callId: json['callId'] as String,
      agentId: json['agentId'] as String?,
      joinUrl: json['joinUrl'] as String,
      created: DateTime.parse(json['created'] as String),
      transcript: [],
    );
  }

  CallModel copyWith({
    CallStage? stage,
    List<Message>? transcript,
  }) {
    return CallModel(
      callId: callId,
      agentId: agentId,
      joinUrl: joinUrl,
      created: created,
      stage: stage ?? this.stage,
      transcript: transcript ?? this.transcript,
    );
  }
}

enum CallStage {
  assess,    // Stage 1: Assess caregiver state
  support,   // Stage 2: Provide support
  evaluate,  // Stage 3: Evaluate & next steps
}

class Message {
  final String role; // 'user' or 'assistant'
  final String text; // Empty string for voice messages without transcription
  final DateTime? timestamp;

  Message({
    required this.role,
    required this.text,
    this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse role - API returns MESSAGE_ROLE_USER, MESSAGE_ROLE_AGENT
    String rawRole = json['role'] as String;
    String normalizedRole = rawRole
        .replaceAll('MESSAGE_ROLE_', '')
        .toLowerCase()
        .replaceAll('agent', 'assistant'); // agent -> assistant

    return Message(
      role: normalizedRole,
      text: json['text'] as String? ?? '', // Handle null text for voice messages
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}
