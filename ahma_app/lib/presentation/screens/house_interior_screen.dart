import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/backend_provider.dart';
import 'next_steps_screen.dart';

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
class _NextStepsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Show list of action plans
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: backendState.updates.length,
      itemBuilder: (context, index) {
        final update = backendState.updates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
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
                  '${update.actionPlan.calendarEvents.length} events • '
                  '${update.actionPlan.todoistTasks.length} tasks • '
                  '${update.actionPlan.resources.length} resources',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            isThreeLine: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NextStepsScreen(update: update),
                ),
              );
            },
          ),
        );
      },
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
