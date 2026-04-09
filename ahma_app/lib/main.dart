import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'presentation/screens/unity_home_screen.dart';
import 'presentation/screens/home_screen_example_blended.dart';
import 'core/config/env_config.dart';
import 'core/theme/ahma_theme.dart';

// Toggle between Unity and example blended home screens
// Set to true for Unity, false for example blended
const bool USE_UNITY_HOME_SCREEN = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Request microphone permission (required for voice calls)
  await _requestPermissions();

  // Start webhook server (runs in background)
  _startWebhookServer();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

void _startWebhookServer() {
  // Note: The webhook handler needs access to the ProviderContainer
  // to update the backend provider. For now, we'll start it separately
  // and wire it up through a global instance or callback.
  // In production, consider using a more robust webhook delivery mechanism.

  // This is a simplified version for testing
  // TODO: In production, use ngrok or proper webhook URL with HTTPS

  debugPrint('[Main] Webhook server will be initialized after provider setup');
  debugPrint('[Main] Webhook URL: http://localhost:${EnvConfig.webhookPort}/webhook');
}

Future<void> _requestPermissions() async {
  try {
    // Request microphone permission on all platforms
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.microphone.request();
      if (status.isDenied) {
        debugPrint('Microphone permission denied');
      }
    } else if (Platform.isMacOS) {
      // macOS also needs explicit microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied) {
        debugPrint('Microphone permission denied on macOS');
      } else if (status.isGranted) {
        debugPrint('Microphone permission granted on macOS');
      }
    } else {
      debugPrint('Running on other platform - microphone permissions handled by OS');
    }
  } catch (e) {
    debugPrint('Permission request failed: $e');
    // Continue without permissions - will request later when needed
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AHMA',
      debugShowCheckedModeBanner: false,
      theme: AhmaTheme.lightTheme,
      home: USE_UNITY_HOME_SCREEN 
        ? const UnityHomeScreen() 
        : const HomeScreenBlendedExample(),
    );
  }
}
