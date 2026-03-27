import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/action_plan.dart';
import '../providers/backend_provider.dart';
import 'next_steps_screen.dart';

/// Action Plans History Screen
///
/// Displays all past action plans grouped by date.
/// Users can:
/// - Browse action plans chronologically
/// - Tap to view full details
/// - Search by date
/// - Navigate to specific calls
class ActionPlansHistoryScreen extends ConsumerWidget {
  const ActionPlansHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Plan History'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reload from database
              ref.read(backendProvider.notifier).reload();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<BackendUpdate>>>(
        future: ref.read(backendProvider.notifier).getGroupedByDate(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading action plans',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final groupedPlans = snapshot.data ?? {};

          if (groupedPlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No action plans yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a voice call to generate your first action plan',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final dates = groupedPlans.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Most recent first

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final plans = groupedPlans[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  _buildDateHeader(context, date),

                  // Action plans for this date
                  ...plans.map((plan) => _buildActionPlanCard(context, plan)),

                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (date.isAtSameMomentAs(today) ||
        (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day)) {
      label = 'Today';
    } else if (date.isAtSameMomentAs(yesterday) ||
        (date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day)) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
      ),
    );
  }

  Widget _buildActionPlanCard(BuildContext context, BackendUpdate plan) {
    final timestamp = DateTime.parse(plan.timestamp);
    final timeStr = DateFormat('h:mm a').format(timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForNeed(plan.classification.primaryNeed),
          child: Icon(
            _getIconForNeed(plan.classification.primaryNeed),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _formatNeed(plan.classification.primaryNeed),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(timeStr),
            const SizedBox(height: 4),
            Text(
              '${plan.stats.actionsInWebhook} action${plan.stats.actionsInWebhook == 1 ? '' : 's'} • ${_formatStressLevel(plan.classification.stressLevel)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to full action plan view
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NextStepsScreen(update: plan),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForNeed(String need) {
    switch (need.toLowerCase()) {
      case 'seniors_help':
        return Icons.elderly;
      case 'mental_health':
        return Icons.favorite;
      case 'children_help':
        return Icons.child_care;
      case 'disability_help':
        return Icons.accessible;
      case 'respite':
        return Icons.self_improvement;
      case 'financial_aid':
        return Icons.attach_money;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForNeed(String need) {
    switch (need.toLowerCase()) {
      case 'seniors_help':
        return Colors.blue;
      case 'mental_health':
        return Colors.purple;
      case 'children_help':
        return Colors.orange;
      case 'disability_help':
        return Colors.green;
      case 'respite':
        return Colors.teal;
      case 'financial_aid':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatNeed(String need) {
    return need
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatStressLevel(String level) {
    switch (level.toLowerCase()) {
      case 'regular':
        return 'Regular stress';
      case 'elevated':
        return 'Elevated stress';
      case 'high':
        return 'High stress';
      default:
        return level;
    }
  }
}
