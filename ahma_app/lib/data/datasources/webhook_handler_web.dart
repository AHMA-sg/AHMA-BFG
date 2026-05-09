import '../models/action_plan.dart';

/// No-op webhook handler for Flutter Web builds.
///
/// Browser apps cannot bind a local HTTP server, so backend updates need to use
/// polling, push notifications, or a hosted backend endpoint instead.
class WebhookHandler {
  final int port;
  final String webhookSecret;
  final Function(BackendUpdate) onUpdate;
  final Function()? onServerReady;

  WebhookHandler({
    this.port = 8080,
    required this.webhookSecret,
    required this.onUpdate,
    this.onServerReady,
  });

  Future<void> start() async {
    print('[Webhook] Local webhook server disabled on web');
  }

  Future<void> stop() async {}

  String getWebhookUrl() => '';
}
