/// Audio configuration for WebRTC
class AudioConfig {
  // Sample rate (Hz) - lower = less lag but lower quality
  static const int sampleRate =
      16000; // Default: 48000, Lower: 16000 for less lag

  // Audio buffer settings
  static const int bufferSize = 2000; // Smaller buffer = less latency

  // Process microphone audio on-device before it is sent to Ultravox.
  // Acoustic echo cancellation needs access to the device playback signal,
  // so it cannot be delegated reliably to the server.
  static const bool echoCancellation = true;
  static const bool noiseSuppression = true;
  static const bool autoGainControl = true; // Keep for consistent volume

  // WebRTC specific
  static const int jitterBufferTarget =
      50; // ms - lower = less lag, more jitter
  static const int jitterBufferMax = 200; // ms
}
