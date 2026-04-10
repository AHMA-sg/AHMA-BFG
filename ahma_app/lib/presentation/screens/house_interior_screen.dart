import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/backend_provider.dart';

/// House interior screen with tabs for managing caregiver tasks
///
/// Tabs:
/// 1. Next Steps - Action items from backend agent
/// 2. Transcripts - Historical call transcripts
/// 3. Plants - Stressor notes metaphor (placeholder)
/// 4. Forum - Community escalation (placeholder)
///
/// TODO: Implement full functionality in Phase 4
class HouseInteriorScreen extends ConsumerStatefulWidget {
  const HouseInteriorScreen({super.key});

  @override
  ConsumerState<HouseInteriorScreen> createState() =>
      _HouseInteriorScreenState();
}

class _HouseInteriorScreenState extends ConsumerState<HouseInteriorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Space'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: 'Next Steps'),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Transcripts'),
            Tab(icon: Icon(Icons.local_florist), text: 'Plants'),
            Tab(icon: Icon(Icons.forum), text: 'Forum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NextStepsTab(),
          _TranscriptsTab(),
          _PlantsTab(),
          _ForumTab(),
        ],
      ),
    );
  }
}

/// Tab 1: Next Steps (action items from backend)
class _NextStepsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NextStepsTab> createState() => _NextStepsTabState();
}

class _NextStepsTabState extends ConsumerState<_NextStepsTab> {
  final Set<String> _expandedItems = <String>{};

  @override
  Widget build(BuildContext context) {
    final backendState = ref.watch(backendProvider);

    if (backendState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (backendState.updates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Next Steps',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Action items will appear here\nafter your calls',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Show list of expandable action plans
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: backendState.updates.length,
      itemBuilder: (context, index) {
        final update = backendState.updates[index];
        final isExpanded = _expandedItems.contains(update.callId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isExpanded ? 4 : 1,
          child: Column(
            children: [
              // Summary row (always visible)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    '${update.stats.actionsInWebhook}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  _formatNeed(update.classification.primaryNeed),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(update.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${update.actionPlan.calendarEvents.length} events, '
                      '${update.actionPlan.todoistTasks.length} tasks, '
                      '${update.actionPlan.resources.length} resources',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                isThreeLine: true,
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedItems.remove(update.callId);
                    } else {
                      _expandedItems.add(update.callId);
                    }
                  });
                },
              ),
              
              // Expanded details (visible when expanded)
              if (isExpanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: _buildActionPlanDetails(update.actionPlan),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionPlanDetails(actionPlan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar Events
        if (actionPlan.calendarEvents.isNotEmpty) ...[
          _buildSectionHeader('Calendar Events', Icons.event),
          const SizedBox(height: 8),
          ...actionPlan.calendarEvents.map((event) => _buildEventItem(event)),
          const SizedBox(height: 16),
        ],
        
        // Todoist Tasks
        if (actionPlan.todoistTasks.isNotEmpty) ...[
          _buildSectionHeader('Tasks', Icons.task),
          const SizedBox(height: 8),
          ...actionPlan.todoistTasks.map((task) => _buildTaskItem(task)),
          const SizedBox(height: 16),
        ],
        
        // Resources
        if (actionPlan.resources.isNotEmpty) ...[
          _buildSectionHeader('Resources', Icons.article),
          const SizedBox(height: 8),
          ...actionPlan.resources.map((resource) => _buildResourceItem(resource)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.summary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (event.location.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Location: ${event.location}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          Text(
            '${event.startTime} - ${event.endTime}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.taskName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (task.taskDue.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Due: ${task.taskDue}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (task.labels.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: task.labels.map((label) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.teal[700]),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceItem(resource) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resource.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (resource.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              resource.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          Text(
            resource.category,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatNeed(String need) {
    return need.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
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
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}

/// Tab 2: Transcripts (historical calls)
class _TranscriptsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Call Transcripts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your conversation history\nwill be stored here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 3: Plants (stressor notes metaphor)
class _PlantsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_florist, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'My Plants',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nurture your wellbeing\nby tending to your stressor topics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🌱 Coming Soon 🌱',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.green[300],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 4: Forum (community escalation)
class _ForumTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Community Forum',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with caregiving organizations\nand get additional support',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '💬 Coming Soon 💬',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.purple[300],
            ),
          ),
        ],
      ),
    );
  }
}
