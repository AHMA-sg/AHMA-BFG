import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'voice_call_screen.dart';
import '../../core/config/env_config.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AHMA'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Header
              const Icon(
                Icons.favorite,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              const Text(
                'AHMA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Assistive Health & Medicine Assistant',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Main action: Start Voice Call
              ElevatedButton(
                onPressed: () async {
                  if (!EnvConfig.isConfigured) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please configure .env file with API keys',
                        ),
                      ),
                    );
                    return;
                  }

                  // Navigate to voice call screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VoiceCallScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Start Voice Call',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How it works:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        '1. Assess',
                        'AHMA will ask how you\'re doing',
                        Colors.blue,
                      ),
                      _buildInfoItem(
                        '2. Support',
                        'Get emotional support and resources',
                        Colors.green,
                      ),
                      _buildInfoItem(
                        '3. Evaluate',
                        'Review next steps and action plan',
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Status indicator
              if (!EnvConfig.isConfigured)
                const Card(
                  color: Colors.orange,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Configuration needed - check .env file',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
