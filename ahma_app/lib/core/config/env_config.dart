import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Ultravox API
  static String get ultravoxApiKey => dotenv.env['ULTRAVOX_API_KEY'] ?? '';
  static String get ultravoxBaseUrl =>
      dotenv.env['ULTRAVOX_BASE_URL'] ?? 'https://api.ultravox.ai/api';

  // AHMA Backend (Flask)
  static String get backendApiUrl =>
      dotenv.env['BACKEND_API_URL'] ?? 'http://localhost:5001';
  static String get backendApiKey => dotenv.env['BACKEND_API_KEY'] ?? '';

  // Ultravox RAG Corpus
  static String get corpusIdCaregiverGuides =>
      dotenv.env['CORPUS_ID_CAREGIVER_GUIDES'] ?? '';

  // Pre-created AHMA Agent ID
  static String get ahmaAgentId =>
      dotenv.env['AHMA_AGENT_ID'] ?? '';

  // Webhook configuration
  static String get webhookSecret =>
      dotenv.env['WEBHOOK_SECRET'] ?? 'default_secret';
  static int get webhookPort =>
      int.tryParse(dotenv.env['WEBHOOK_PORT'] ?? '8080') ?? 8080;

  // Validate configuration
  static bool get isConfigured {
    return ultravoxApiKey.isNotEmpty &&
           corpusIdCaregiverGuides.isNotEmpty &&
           ahmaAgentId.isNotEmpty;
  }
}
