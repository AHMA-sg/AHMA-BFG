import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Request microphone permission (required for voice calls)
  await _requestPermissions();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
