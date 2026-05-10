import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const String _ultravoxApiKey = String.fromEnvironment(
    'ULTRAVOX_API_KEY',
  );
  static const String _ultravoxBaseUrl = String.fromEnvironment(
    'ULTRAVOX_BASE_URL',
  );
  static const String _backendApiUrl = String.fromEnvironment(
    'BACKEND_API_URL',
  );
  static const String _backendApiKey = String.fromEnvironment(
    'BACKEND_API_KEY',
  );
  static const String _corpusIdCaregiverGuides = String.fromEnvironment(
    'CORPUS_ID_CAREGIVER_GUIDES',
  );
  static const String _ahmaAgentId = String.fromEnvironment('AHMA_AGENT_ID');
  static const String _webhookSecret = String.fromEnvironment('WEBHOOK_SECRET');
  static const String _webhookPort = String.fromEnvironment('WEBHOOK_PORT');

  static bool _hasUsableValue(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('your_') &&
        !trimmed.endsWith('_here');
  }

  static String _value(
    String dartDefineValue,
    String dotenvKey, {
    String fallback = '',
  }) {
    if (_hasUsableValue(dartDefineValue)) {
      return dartDefineValue.trim();
    }

    final dotenvValue = dotenv.env[dotenvKey]?.trim() ?? '';
    if (_hasUsableValue(dotenvValue)) {
      return dotenvValue;
    }

    return fallback;
  }

  // Ultravox API
  static String get ultravoxApiKey =>
      _value(_ultravoxApiKey, 'ULTRAVOX_API_KEY');
  static String get ultravoxBaseUrl => _value(
    _ultravoxBaseUrl,
    'ULTRAVOX_BASE_URL',
    fallback: 'https://api.ultravox.ai/api',
  );

  // AHMA Backend (Flask)
  static String get backendApiUrl => _value(
    _backendApiUrl,
    'BACKEND_API_URL',
    fallback: 'http://localhost:5001',
  );
  static String get backendApiKey => _value(_backendApiKey, 'BACKEND_API_KEY');

  // Ultravox RAG Corpus
  static String get corpusIdCaregiverGuides =>
      _value(_corpusIdCaregiverGuides, 'CORPUS_ID_CAREGIVER_GUIDES');

  // Pre-created AHMA Agent ID
  static String get ahmaAgentId => _value(_ahmaAgentId, 'AHMA_AGENT_ID');

  // Webhook configuration
  static String get webhookSecret =>
      _value(_webhookSecret, 'WEBHOOK_SECRET', fallback: 'default_secret');
  static int get webhookPort =>
      int.tryParse(_value(_webhookPort, 'WEBHOOK_PORT', fallback: '8080')) ??
      8080;

  // Validate configuration
  static bool get isConfigured {
    return ultravoxApiKey.isNotEmpty &&
        corpusIdCaregiverGuides.isNotEmpty &&
        ahmaAgentId.isNotEmpty;
  }
}
