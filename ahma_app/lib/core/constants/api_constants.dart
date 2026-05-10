class ApiConstants {
  // Ultravox endpoints
  static const String agents = '/agents';
  static const String calls = '/calls';
  static const String tools = '/tools';
  static const String corpora = '/corpora';

  // AHMA Backend endpoints
  static const String backendHealth = '/health';
  static const String backendChat = '/api/ahma/chat';
  static const String backendTranscript = '/api/ultravox/transcript';
  static const String backendToolRequest = '/api/ultravox/tool-request';

  // Audio configuration
  static const int sampleRate = 48000; // 48kHz
  static const int bufferSizeMs = 60; // 60ms buffer
}
