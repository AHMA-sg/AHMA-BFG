import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/webhook_handler_web.dart'
    if (dart.library.io) '../../data/datasources/webhook_handler.dart';
import '../../core/config/env_config.dart';
import 'backend_provider.dart';

/// Webhook handler provider
final webhookHandlerProvider = Provider<WebhookHandler>((ref) {
  final handler = WebhookHandler(
    port: EnvConfig.webhookPort,
    webhookSecret: EnvConfig.webhookSecret,
    onUpdate: (update) {
      // Forward update to backend provider
      ref.read(backendProvider.notifier).processUpdate(update);
    },
    onServerReady: () {
      // Register webhook URL with backend once server is ready
      _registerWebhookWithBackend();
    },
  );

  // Start the webhook server (runs in background)
  handler.start().catchError((e) {
    print('[Webhook] Failed to start server: $e');
  });

  // Clean up on dispose
  ref.onDispose(() {
    handler.stop();
  });

  return handler;
});

/// Register webhook URL with backend
Future<void> _registerWebhookWithBackend() async {
  try {
    final webhookUrl = 'http://localhost:${EnvConfig.webhookPort}/webhook';
    final backendUrl = EnvConfig.backendApiUrl;

    print('[Webhook] 📱 Attempting to register webhook...');
    print('[Webhook]    URL: $webhookUrl');
    print('[Webhook]    Backend: $backendUrl');

    final dio = Dio();
    final response = await dio.post(
      '$backendUrl/api/flutter/webhook/register',
      data: {
        'userId': 'default_user', // TODO: Get from auth provider
        'webhookUrl': webhookUrl,
      },
    );

    if (response.statusCode == 200) {
      print('[Webhook] ✅ Webhook registered successfully');
    } else {
      print('[Webhook] ⚠️  Registration failed: ${response.statusCode}');
    }
  } catch (e) {
    print('[Webhook] ❌ Error registering webhook: $e');
    print(
      '[Webhook]    Make sure backend is running on ${EnvConfig.backendApiUrl}',
    );
  }
}
