import 'package:flutter/material.dart';
import '../../data/models/action_plan.dart';
import 'package:intl/intl.dart';

class NextStepsScreen extends StatelessWidget {
  final BackendUpdate update;

  const NextStepsScreen({
    super.key,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Steps'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(context),

              const SizedBox(height: 24),

              // Actions List
              if (update.actionPlan.isEmpty)
                _buildEmptyState()
              else
                ..._buildActionsList(context),

              const SizedBox(height: 24),

              // Reasoning Section
              if (update.actionPlan.reasoning.isNotEmpty)
                _buildReasoningCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForNeed(update.classification.primaryNeed),
                  size: 32,
                  color: Colors.teal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Personalized Action Plan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generated ${_formatTimestamp(update.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStat('Total Actions', update.stats.actionsInWebhook),
                const SizedBox(width: 24),
                _buildStat('Category', _formatNeed(update.classification.primaryNeed)),
                const SizedBox(width: 24),
                _buildStat('Stress', _formatStressLevel(update.classification.stressLevel)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, dynamic value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionsList(BuildContext context) {
    final actions = <Widget>[];

    // Calendar Events
    if (update.actionPlan.calendarEvents.isNotEmpty) {
      actions.add(const SizedBox(height: 8));
      actions.add(_buildSectionHeader('Calendar Events', Icons.calendar_today, Colors.blue));
      for (final event in update.actionPlan.calendarEvents) {
        actions.add(_buildCalendarEventCard(context, event));
      }
    }

    // Tasks
    if (update.actionPlan.todoistTasks.isNotEmpty) {
      actions.add(const SizedBox(height: 16));
      actions.add(_buildSectionHeader('Tasks', Icons.check_circle, Colors.green));
      for (final task in update.actionPlan.todoistTasks) {
        actions.add(_buildTaskCard(context, task));
      }
    }

    // Resources
    if (update.actionPlan.resources.isNotEmpty) {
      actions.add(const SizedBox(height: 16));
      actions.add(_buildSectionHeader('Resources', Icons.book, Colors.purple));
      for (final resource in update.actionPlan.resources) {
        actions.add(_buildResourceCard(context, resource));
      }
    }

    return actions;
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarEventCard(BuildContext context, CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.event, color: Colors.white, size: 20),
        ),
        title: Text(
          event.summary,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(_formatDateTime(event.startTime)),
              ],
            ),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(event.location)),
                ],
              ),
            ],
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TodoistTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(task.priority),
          child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
        ),
        title: Text(
          task.taskName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.alarm, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Due: ${task.taskDue}'),
              ],
            ),
            if (task.labels.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: task.labels
                    .map((label) => Chip(
                          label: Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, Resource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.library_books, color: Colors.white, size: 20),
        ),
        title: Text(
          resource.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              resource.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (resource.url.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.link, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      resource.url,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        isThreeLine: true,
        onTap: resource.url.isNotEmpty
            ? () {
                // TODO: Open URL in browser
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${resource.url}')),
                );
              }
            : null,
      ),
    );
  }

  Widget _buildReasoningCard(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Why these actions?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              update.actionPlan.reasoning,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No actions available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t generate any specific actions from your conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForNeed(String need) {
    switch (need) {
      case 'seniors_help':
        return Icons.elderly;
      case 'children_help':
        return Icons.child_care;
      case 'disability_help':
        return Icons.accessible;
      case 'mental_health':
        return Icons.psychology;
      default:
        return Icons.help;
    }
  }

  String _formatNeed(String need) {
    return need.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatStressLevel(String level) {
    return level[0].toUpperCase() + level.substring(1);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 4:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 1:
      default:
        return Colors.grey;
    }
  }
}
