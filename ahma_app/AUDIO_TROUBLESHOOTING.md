# Audio Troubleshooting Guide

## Issue: "On call other side can't hear"

This guide addresses the common issue where the other side (AHMA agent) cannot hear the user during voice calls.

## Root Causes and Fixes

### 1. Microphone Permission Issues

**Problem**: The app doesn't have microphone permissions, preventing audio capture.

**Fix Applied**:
- Added microphone permission checking in `UltravoxRtcManager._enableMicrophone()`
- Automatic permission request if denied
- Better error handling and logging

**Code Location**: `lib/data/datasources/ultravox_rtc.dart`

### 2. Audio Track Publishing Issues

**Problem**: Local audio track not properly published to the WebRTC room.

**Fix Applied**:
- Added verification that audio track is created successfully
- Added logging for track publishing status
- Improved error handling with rethrow for proper propagation

**Code Location**: `lib/data/datasources/ultravox_rtc.dart`

### 3. Push-to-Talk Logic Issues

**Problem**: Audio capture not properly enabled/disabled during PTT.

**Fix Applied**:
- Enhanced `startAudioCapture()` and `stopAudioCapture()` methods
- Added WebRTC connection state checking
- Better debugging output for audio state changes

**Code Location**: `lib/presentation/providers/call_provider.dart`

### 4. Audio Configuration Issues

**Problem**: Suboptimal audio settings causing transmission issues.

**Current Settings** (in `lib/core/config/audio_config.dart`):
```dart
class AudioConfig {
  static const int sampleRate = 16000; // Lower for less lag
  static const int bufferSize = 2000; // Smaller buffer = less latency
  static const bool echoCancellation = false;  // Disabled - Ultravox handles this
  static const bool noiseSuppression = false;  // Disabled for less processing lag
  static const bool autoGainControl = true;    // Keep for consistent volume
}
```

## Testing and Debugging

### Audio Test Widget

A comprehensive audio testing utility has been added:

**Location**: `lib/utils/audio_tester.dart`

**Features**:
- Microphone permission testing
- Audio track creation testing
- Audio track control testing (PTT simulation)
- Comprehensive test results with pass/fail indicators

**How to Use**:
1. Open the home screen
2. Click the headset icon in the top-right corner
3. Run the audio test
4. Check results for any failed components

### Debug Logging

Enhanced logging has been added throughout the audio pipeline:

- `[AudioTest]` - Audio testing results
- `[LiveKit]` - WebRTC and LiveKit operations
- `[WebRTC]` - WebRTC connection and audio operations
- `[Call]` - Call state and audio capture operations

## Common Solutions

### 1. Check Microphone Permissions

**iOS**: Settings → Privacy → Microphone → Enable for AHMA app
**Android**: Settings → Apps → AHMA → Permissions → Enable Microphone
**Desktop**: System preferences → Security & Privacy → Microphone

### 2. Test Audio Hardware

Use the built-in audio test widget to verify:
- Microphone permission is granted
- Audio track can be created
- Audio track can be enabled/disabled

### 3. Check Network Connection

Poor network connectivity can cause audio transmission issues:
- Ensure stable internet connection
- Check for firewall blocking WebRTC traffic
- Verify WebSocket connections are working

### 4. Verify Audio Configuration

If issues persist, try adjusting audio settings in `audio_config.dart`:
- Increase `bufferSize` for more stable audio (may increase latency)
- Enable `echoCancellation` and `noiseSuppression` for better quality
- Adjust `sampleRate` based on device capabilities

## Platform-Specific Issues

### iOS
- Ensure microphone permission is explicitly granted
- Check that microphone is not being used by other apps
- Verify app has background audio capability if needed

### Android
- Check that microphone permission is not denied permanently
- Ensure no other apps are using the microphone
- Verify audio focus is properly handled

### Desktop (macOS/Windows/Linux)
- Check system audio settings
- Verify microphone is selected as default input device
- Ensure no other applications are using the microphone

## Next Steps

1. **Run Audio Test**: Use the audio test widget to identify specific issues
2. **Check Logs**: Look for error messages in the debug console
3. **Verify Permissions**: Ensure microphone permissions are granted
4. **Test Hardware**: Try with different microphones if available
5. **Network Check**: Verify stable internet connection
6. **Contact Support**: If issues persist, provide debug logs for further analysis

## Files Modified

- `lib/data/datasources/ultravox_rtc.dart` - Enhanced microphone permission and audio track handling
- `lib/presentation/providers/call_provider.dart` - Improved audio capture debugging
- `lib/utils/audio_tester.dart` - New audio testing utility
- `lib/presentation/screens/home_screen.dart` - Added audio test button