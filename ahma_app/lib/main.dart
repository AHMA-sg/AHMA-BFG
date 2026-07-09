import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'presentation/screens/unity_home_screen.dart';
import 'presentation/screens/ahma_main_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/profile_gate.dart';
import 'presentation/providers/auth_provider.dart';
import 'core/config/env_config.dart';
import 'core/config/env_file_loader.dart';
import 'core/theme/ahma_theme.dart';
import 'data/datasources/google_services_store.dart';

// Toggle between Unity and example blended home screens
// Set to true for Unity, false for example blended
const bool USE_UNITY_HOME_SCREEN = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env.example', isOptional: true);
  final exampleEnv = Map<String, String>.from(dotenv.env);
  final hasInjectedCallEnv =
      EnvConfig.ultravoxApiKey.isNotEmpty && EnvConfig.ahmaAgentId.isNotEmpty;
  if (hasInjectedCallEnv) {
    debugPrint('[Env] Using injected Dart defines for call configuration');
  } else {
    final localEnv = await loadLocalEnvFile();
    if (localEnv.isNotEmpty) {
      dotenv.testLoad(fileInput: '', mergeWith: {...exampleEnv, ...localEnv});
    }
  }

  // Request microphone permission (required for voice calls)
  await _requestPermissions();
  await GoogleServicesStore().captureOAuthRedirectFromCurrentUrl();

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

  static const double _minimumTextScaleFactor = 1.0;
  // Layouts must tolerate at least 1.3x — the floor for supporting OS-level
  // large-text accessibility settings. Do not lower this to protect a layout;
  // fix the layout instead.
  static const double _maximumTextScaleFactor = 1.3;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AHMA',
      debugShowCheckedModeBanner: false,
      theme: AhmaTheme.lightTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final currentScaleFactor = mediaQuery.textScaler.scale(16) / 16;
        final effectiveScaleFactor = currentScaleFactor.clamp(
          _minimumTextScaleFactor,
          _maximumTextScaleFactor,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(effectiveScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Auth sits above the profile gate: no session -> login screen;
      // with a session, the gate verifies the identity against the profile
      // backend (or runs onboarding) before the main AHMA experience.
      home: const RootGate(),
    );
  }
}

/// Routes by auth status. The profile gate is only mounted once a session
/// exists, so each login re-runs the full launch verification.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authProvider.select((auth) => auth.status));

    switch (status) {
      case AuthStatus.restoring:
        return const Scaffold(
          backgroundColor: AhmaTheme.background,
          body: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AhmaTheme.sageGreen),
              ),
            ),
          ),
        );
      case AuthStatus.loggedOut:
      case AuthStatus.signingIn:
        return const LoginScreen();
      case AuthStatus.loggedIn:
        return ProfileGate(
          app: USE_UNITY_HOME_SCREEN
              ? const UnityHomeScreen()
              : const AhmaMainScreen(),
        );
    }
  }
}
