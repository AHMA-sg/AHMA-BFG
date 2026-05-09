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

  // Ultravox API
  static String get ultravoxApiKey => _ultravoxApiKey.isNotEmpty
      ? _ultravoxApiKey
      : dotenv.env['ULTRAVOX_API_KEY'] ?? '';
  static String get ultravoxBaseUrl => _ultravoxBaseUrl.isNotEmpty
      ? _ultravoxBaseUrl
      : dotenv.env['ULTRAVOX_BASE_URL'] ?? 'https://api.ultravox.ai/api';

  // AHMA Backend (Flask)
  static String get backendApiUrl => _backendApiUrl.isNotEmpty
      ? _backendApiUrl
      : dotenv.env['BACKEND_API_URL'] ?? 'http://localhost:5001';
  static String get backendApiKey => _backendApiKey.isNotEmpty
      ? _backendApiKey
      : dotenv.env['BACKEND_API_KEY'] ?? '';

  // Ultravox RAG Corpus
  static String get corpusIdCaregiverGuides =>
      _corpusIdCaregiverGuides.isNotEmpty
      ? _corpusIdCaregiverGuides
      : dotenv.env['CORPUS_ID_CAREGIVER_GUIDES'] ?? '';

  // Pre-created AHMA Agent ID
  static String get ahmaAgentId => _ahmaAgentId.isNotEmpty
      ? _ahmaAgentId
      : dotenv.env['AHMA_AGENT_ID'] ?? '';

  // Webhook configuration
  static String get webhookSecret => _webhookSecret.isNotEmpty
      ? _webhookSecret
      : dotenv.env['WEBHOOK_SECRET'] ?? 'default_secret';
  static int get webhookPort =>
      int.tryParse(
        _webhookPort.isNotEmpty
            ? _webhookPort
            : dotenv.env['WEBHOOK_PORT'] ?? '8080',
      ) ??
      8080;

  // Validate configuration
  static bool get isConfigured {
    return ultravoxApiKey.isNotEmpty &&
        corpusIdCaregiverGuides.isNotEmpty &&
        ahmaAgentId.isNotEmpty;
  }
}
