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
      dotenv.env['DYSON_AGENT_ID'] ?? '';

  // Validate configuration
  static bool get isConfigured {
    return ultravoxApiKey.isNotEmpty && corpusIdCaregiverGuides.isNotEmpty;
  }
}
