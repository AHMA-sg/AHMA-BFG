import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'presentation/screens/unity_home_screen.dart';
import 'presentation/screens/home_screen_example_blended.dart';
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

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestPermissions() async {
  try {
    if (kIsWeb) {
      debugPrint('Running on web - microphone permissions handled by browser');
      return;
    }

    // Request microphone permission on all platforms
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.microphone.request();
      if (status.isDenied) {
        debugPrint('Microphone permission denied');
      }
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      // macOS also needs explicit microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied) {
        debugPrint('Microphone permission denied on macOS');
      } else if (status.isGranted) {
        debugPrint('Microphone permission granted on macOS');
      }
    } else {
      debugPrint(
        'Running on other platform - microphone permissions handled by OS',
      );
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
