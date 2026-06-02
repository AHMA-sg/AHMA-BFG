/// Audio configuration for WebRTC
class AudioConfig {
  // Sample rate (Hz) - lower = less lag but lower quality
  static const int sampleRate =
      16000; // Default: 48000, Lower: 16000 for less lag

  // Audio buffer settings
  static const int bufferSize = 2000; // Smaller buffer = less latency

  // Echo cancellation settings (reduced for less lag)
  // Note: Ultravox handles echo cancellation on the server side
  static const bool echoCancellation =
      false; // Disabled - Ultravox handles this
  static const bool noiseSuppression =
      false; // Disabled for less processing lag
  static const bool autoGainControl = true; // Keep for consistent volume

  // Playback settings
  // 1.0 is normal. Native WebRTC supports values above 1.0 for gain.
  // Keep this modest to avoid distortion/clipping.
  static const double remoteAudioVolume = 2.0;

  // Route calls through the loudspeaker by default on mobile devices.
  static const bool speakerphoneOn = true;
  static const bool forceSpeakerOutput = true;

  // WebRTC specific
  static const int jitterBufferTarget =
      50; // ms - lower = less lag, more jitter
  static const int jitterBufferMax = 200; // ms
}
