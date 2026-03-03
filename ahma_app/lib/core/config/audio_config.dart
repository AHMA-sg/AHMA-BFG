/// Audio configuration for WebRTC
class AudioConfig {
  // Sample rate (Hz) - lower = less lag but lower quality
  static const int sampleRate = 16000; // Default: 48000, Lower: 16000 for less lag

  // Audio buffer settings
  static const int bufferSize = 480; // Smaller buffer = less latency

  // Echo cancellation settings
  static const bool echoCancellation = true;
  static const bool noiseSuppression = true;
  static const bool autoGainControl = true;

  // WebRTC specific
  static const int jitterBufferTarget = 50; // ms - lower = less lag, more jitter
  static const int jitterBufferMax = 200; // ms
}
