import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'presentation/screens/home_screen.dart';
import 'core/config/env_config.dart';

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
  // Only request permissions on mobile platforms
  // Linux/Desktop: Browser/OS handles permissions automatically
  if (Platform.isAndroid || Platform.isIOS) {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      debugPrint('Microphone permission denied');
    }
  } else {
    debugPrint('Running on desktop - microphone permissions handled by OS');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AHMA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
