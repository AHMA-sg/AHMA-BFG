import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../models/action_plan.dart';

/// Webhook handler for receiving backend updates
class WebhookHandler {
  HttpServer? _server;
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

  /// Start the webhook server
  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('[Webhook] Server listening on port $port');

      // Notify that server is ready
      if (onServerReady != null) {
        onServerReady!();
      }

      await for (HttpRequest request in _server!) {
        await _handleRequest(request);
      }
    } catch (e) {
      print('[Webhook] Error starting server: $e');
    }
  }

  /// Stop the webhook server
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    print('[Webhook] Server stopped');
  }

  /// Handle incoming webhook request
  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Only POST requests allowed')
        ..close();
      return;
    }

    if (request.uri.path != '/webhook') {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found')
        ..close();
      return;
    }

    try {
      // Read body
      final bodyBytes = await request.toList();
      final body = utf8.decode(bodyBytes.expand((x) => x).toList());

      // Get headers
      final signature = request.headers.value('x-ahma-signature');
      final timestamp = request.headers.value('x-ahma-timestamp');

      if (signature == null || timestamp == null) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Missing signature or timestamp')
          ..close();
        return;
      }

      // Debug: print full body
      print('[Webhook] 📝 Full body received:\n$body\n');

      // Verify signature
      if (!_verifySignature(body, timestamp, signature)) {
        print('[Webhook] ⚠️  Invalid signature');
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Invalid signature')
          ..close();
        return;
      }

      // Check timestamp (prevent replay attacks - within 5 minutes)
      if (!_isRecentTimestamp(timestamp)) {
        print('[Webhook] ⚠️  Expired timestamp');
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Expired request')
          ..close();
        return;
      }

      // Parse webhook payload
      final json = jsonDecode(body) as Map<String, dynamic>;
      final update = BackendUpdate.fromJson(json);

      print('[Webhook] ✅ Received update for call: ${update.callId}');

      // Process update
      onUpdate(update);

      // Return 204 No Content
      request.response
        ..statusCode = HttpStatus.noContent
        ..close();

    } catch (e) {
      print('[Webhook] Error processing request: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal server error')
        ..close();
    }
  }

  /// Verify HMAC signature
  bool _verifySignature(String body, String timestamp, String signature) {
    final message = '$body$timestamp';
    final hmac = Hmac(sha256, utf8.encode(webhookSecret));
    final digest = hmac.convert(utf8.encode(message));
    final expectedSignature = digest.toString();

    print('[Webhook] 🔐 Flutter computed:');
    print('[Webhook] 🔐   Secret: "$webhookSecret"');
    print('[Webhook] 🔐   Body length: ${body.length}');
    print('[Webhook] 🔐   Timestamp: $timestamp');
    print('[Webhook] 🔐   Expected signature: $expectedSignature');
    print('[Webhook] 🔐   Received signature: $signature');
    print('[Webhook] 🔐   Match: ${expectedSignature == signature}');

    return expectedSignature == signature;
  }

  /// Check if timestamp is recent (within 5 minutes)
  bool _isRecentTimestamp(String timestamp) {
    try {
      // Parse as UTC if no timezone indicator (backend sends UTC without 'Z')
      DateTime requestTime;
      if (timestamp.endsWith('Z') || timestamp.contains('+')) {
        requestTime = DateTime.parse(timestamp);
      } else {
        // No timezone indicator, assume UTC
        requestTime = DateTime.parse(timestamp + 'Z');
      }

      final now = DateTime.now().toUtc();
      final diff = now.difference(requestTime).abs();

      print('[Webhook] ⏰ Timestamp check:');
      print('[Webhook]    Request time (UTC): $requestTime');
      print('[Webhook]    Current time (UTC): $now');
      print('[Webhook]    Difference: ${diff.inSeconds} seconds');
      print('[Webhook]    Valid: ${diff.inMinutes <= 5}');

      return diff.inMinutes <= 5;
    } catch (e) {
      print('[Webhook] ❌ Timestamp parse error: $e');
      return false;
    }
  }

  /// Get webhook URL for registration with backend
  String getWebhookUrl() {
    // For local testing
    // TODO: In production, use ngrok or proper webhook URL
    return 'http://localhost:$port/webhook';
  }
}
