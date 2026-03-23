import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/webhook_handler.dart';
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
  );

  // Start the webhook server
  handler.start().catchError((e) {
    print('[Webhook] Failed to start server: $e');
  });

  // Clean up on dispose
  ref.onDispose(() {
    handler.stop();
  });

  return handler;
});
