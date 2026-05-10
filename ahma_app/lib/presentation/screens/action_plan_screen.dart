import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/ahma_theme.dart';
import '../../data/models/action_plan.dart';

class ActionPlanScreen extends StatelessWidget {
  const ActionPlanScreen({super.key, required this.update});

  final BackendUpdate update;

  @override
  Widget build(BuildContext context) {
    final actionPlan = update.actionPlan;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTopBar(context),
                  const SizedBox(height: 14),
                  _buildHeroCard(context, actionPlan),
                  const SizedBox(height: 14),
                  _buildSummaryHighlights(context, actionPlan),
                  const SizedBox(height: 18),
                  if (actionPlan.reasoning.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: 'Action plan summary',
                      subtitle:
                          'A quick read of what AHMA pulled from the call.',
                    ),
                    const SizedBox(height: 12),
                    _buildReasoningCard(context, actionPlan.reasoning),
                    const SizedBox(height: 18),
                  ],
                  if (actionPlan.isEmpty)
                    _buildEmptyState(context)
                  else ...[
                    if (actionPlan.todoistTasks.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        title: 'Action tasks',
                        subtitle:
                            'Practical next steps to keep support moving.',
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        context,
                        accent: AhmaTheme.sageGreen,
                        icon: Icons.task_alt_outlined,
                        children: actionPlan.todoistTasks
                            .map((task) => _buildTaskEntry(context, task))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (actionPlan.calendarEvents.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        title: 'Calendar moments',
                        subtitle: 'Events that may need time or coordination.',
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        context,
                        accent: const Color(0xFF5F8DAA),
                        icon: Icons.event_available_outlined,
                        children: actionPlan.calendarEvents
                            .map((event) => _buildCalendarEntry(context, event))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (actionPlan.resources.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        title: 'Helpful resources',
                        subtitle: 'References surfaced during this call.',
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        context,
                        accent: AhmaTheme.palePink,
                        icon: Icons.library_books_outlined,
                        children: actionPlan.resources
                            .map(
                              (resource) =>
                                  _buildResourceEntry(context, resource),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AHMA',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AhmaTheme.ahmaRed,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Action plan detail',
                  style: AhmaTheme.labelTextStyle.copyWith(
                    color: AhmaTheme.mocha.withValues(alpha: 0.55),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AhmaTheme.ahmaRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AhmaTheme.ahmaRed.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close,
                size: 11,
                color: AhmaTheme.ahmaRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ActionPlan actionPlan) {
    final timestampLabel =
        '${_formatFullDate(update.timestamp)} at ${DateFormat('h:mm a').format(update.timestamp)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            AhmaTheme.cardColor.withValues(alpha: 0.94),
            AhmaTheme.cardColor2.withValues(alpha: 0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AhmaTheme.mocha.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AhmaTheme.mocha.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -12,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorForNeed(
                  update.classification.primaryNeed,
                ).withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadge(
                label: _formatNeed(update.classification.primaryNeed),
                background: _colorForNeed(
                  update.classification.primaryNeed,
                ).withValues(alpha: 0.14),
                foreground: _colorForNeed(update.classification.primaryNeed),
              ),
              const SizedBox(height: 14),
              Text(
                'A focused summary of the action plan created from this AHMA conversation.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 21,
                  height: 1.2,
                  color: AhmaTheme.mocha,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                timestampLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AhmaTheme.sageGreen,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoPill(
                    icon: Icons.checklist_rounded,
                    label:
                        '${actionPlan.totalActions} action${actionPlan.totalActions == 1 ? '' : 's'}',
                  ),
                  _buildInfoPill(
                    icon: Icons.monitor_heart_outlined,
                    label: _formatStressLevel(
                      update.classification.stressLevel,
                    ),
                  ),
                  _buildInfoPill(
                    icon: Icons.add_task_rounded,
                    label:
                        '${update.stats.newActions} new suggestion${update.stats.newActions == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHighlights(BuildContext context, ActionPlan actionPlan) {
    return Row(
      children: [
        Expanded(
          child: _buildHighlightCard(
            context,
            value: '${actionPlan.todoistTasks.length}',
            label: 'Tasks',
            accent: AhmaTheme.sageGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildHighlightCard(
            context,
            value: '${actionPlan.calendarEvents.length}',
            label: 'Events',
            accent: const Color(0xFF5F8DAA),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildHighlightCard(
            context,
            value: '${actionPlan.resources.length}',
            label: 'Resources',
            accent: AhmaTheme.palePink,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(
    BuildContext context, {
    required String value,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AhmaTheme.mocha.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              color: AhmaTheme.mocha,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AhmaTheme.mocha,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 22,
            color: AhmaTheme.mocha,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: AhmaTheme.mocha.withValues(alpha: 0.6),
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildReasoningCard(BuildContext context, String reasoning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AhmaTheme.backgroundInner.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AhmaTheme.mocha.withValues(alpha: 0.06)),
      ),
      child: Text(
        reasoning,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 13,
          color: AhmaTheme.mocha.withValues(alpha: 0.78),
          height: 1.38,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required Color accent,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: accent.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTaskEntry(BuildContext context, TodoistTask task) {
    final parts = <String>[];
    if (task.taskDue.isNotEmpty) {
      parts.add('Due ${task.taskDue}');
    }
    if (task.labels.isNotEmpty) {
      parts.add(task.labels.join(', '));
    }
    if (task.description.isNotEmpty) {
      parts.add(task.description);
    }

    return _buildEntryRow(
      context,
      icon: Icons.radio_button_checked,
      title: task.taskName.isEmpty ? 'Follow-up task' : task.taskName,
      subtitle: parts.join(' • '),
      iconColor: _priorityColor(task.priority),
    );
  }

  Widget _buildCalendarEntry(BuildContext context, CalendarEvent event) {
    return _buildEntryRow(
      context,
      icon: Icons.event_note_outlined,
      title: event.summary.isEmpty ? 'Calendar event' : event.summary,
      subtitle: [
        if (event.startTime.isNotEmpty) _formatEventTime(event.startTime),
        if (event.location.isNotEmpty) event.location,
        if (event.description.isNotEmpty) event.description,
      ].join(' • '),
      iconColor: const Color(0xFF5F8DAA),
    );
  }

  Widget _buildResourceEntry(BuildContext context, Resource resource) {
    final parts = <String>[];
    if (resource.category.isNotEmpty) {
      parts.add(_sentenceCase(resource.category.replaceAll('_', ' ')));
    }
    if (resource.description.isNotEmpty) {
      parts.add(resource.description);
    }
    if (resource.url.isNotEmpty) {
      parts.add(resource.url);
    }

    return _buildEntryRow(
      context,
      icon: Icons.arrow_outward_rounded,
      title: resource.title.isEmpty ? 'Resource link' : resource.title,
      subtitle: parts.join(' • '),
      iconColor: AhmaTheme.palePink,
    );
  }

  Widget _buildEntryRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 16,
              color: iconColor ?? AhmaTheme.mocha.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AhmaTheme.mocha,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      color: AhmaTheme.mocha.withValues(alpha: 0.6),
                      height: 1.28,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AhmaTheme.mocha.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AhmaTheme.sageGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AhmaTheme.sageGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No action items for this call',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              color: AhmaTheme.mocha,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AHMA did not generate any follow-up tasks, events, or resources for this conversation yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              color: AhmaTheme.mocha.withValues(alpha: 0.66),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AhmaTheme.mocha.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AhmaTheme.mocha.withValues(alpha: 0.72)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AhmaTheme.labelTextStyle.copyWith(
                fontSize: 10.5,
                color: AhmaTheme.mocha.withValues(alpha: 0.72),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AhmaTheme.labelTextStyle.copyWith(
          fontSize: 10.5,
          color: foreground,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Today';
    }
    if (difference == 1) {
      return 'Yesterday';
    }
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  String _formatEventTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return DateFormat('EEE, d MMM • h:mm a').format(parsed);
  }

  String _formatNeed(String need) {
    if (need.isEmpty) {
      return 'General support';
    }

    return need
        .split('_')
        .where((word) => word.isNotEmpty)
        .map(_sentenceCase)
        .join(' ');
  }

  String _formatStressLevel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 'High stress';
      case 'elevated':
        return 'Elevated stress';
      case 'regular':
        return 'Regular stress';
      default:
        return _sentenceCase(level);
    }
  }

  String _sentenceCase(String text) {
    if (text.isEmpty) {
      return text;
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  Color _colorForNeed(String need) {
    switch (need.toLowerCase()) {
      case 'mental_health':
        return const Color(0xFF9D6C8C);
      case 'seniors_help':
        return const Color(0xFF5F8DAA);
      case 'children_help':
        return const Color(0xFFC48554);
      case 'disability_help':
        return const Color(0xFF5F8573);
      case 'financial_aid':
        return const Color(0xFF9C7A3B);
      case 'respite':
        return const Color(0xFF6C8070);
      default:
        return AhmaTheme.sageGreen;
    }
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 4:
        return AhmaTheme.ahmaRed;
      case 3:
        return const Color(0xFFB86D52);
      case 2:
        return AhmaTheme.sageGreen;
      default:
        return AhmaTheme.mid;
    }
  }
}
