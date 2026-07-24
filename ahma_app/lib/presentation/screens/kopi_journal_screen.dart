import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/ahma_theme.dart';
import '../../core/utils/summary_quote.dart';
import '../../data/models/action_plan.dart';
import '../providers/backend_provider.dart';

class WalkEntry {
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isPink;
  final bool isFuture;
  final BackendUpdate? backendUpdate;

  const WalkEntry({
    required this.title,
    required this.subtitle,
    this.isActive = false,
    this.isPink = false,
    this.isFuture = false,
    this.backendUpdate,
  });
}

/// Kopi Journal Screen
///
/// Features:
/// - Spiral timeline with nodes
/// - Collectible items (☕, ✦, ?)
/// - walk count in top bar
/// - Walking turtle theme
class KopiJournalScreen extends ConsumerStatefulWidget {
  const KopiJournalScreen({super.key});

  @override
  ConsumerState<KopiJournalScreen> createState() => _KopiJournalScreenState();
}

class _KopiJournalScreenState extends ConsumerState<KopiJournalScreen> {
  late List<WalkEntry> _walks;
  final Set<int> _expandedPlans = <int>{};
  BackendUpdate? _selectedJourney;
  int _selectedJourneyPage = 0;
  double _detailDragDistance = 0;

  double _phoneScale(BuildContext context) {
    return MediaQuery.of(context).size.width <= 480 ? 0.86 : 1.0;
  }

  @override
  void initState() {
    super.initState();
    _walks = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Transparent to show watercolor background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with logo and walk count
            _buildTopBar(),

            // Main content
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final summaryCount = ref.watch(
      backendProvider.select((state) => state.journeyCount),
    );
    final walkCount = summaryCount;
    final phoneScale = _phoneScale(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20 * phoneScale,
        10 * phoneScale,
        20 * phoneScale,
        6 * phoneScale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Text(
            'AHMA',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 34 * phoneScale,
              fontWeight: FontWeight.w700,
              color: AhmaTheme.ahmaRed,
              letterSpacing: 0.3,
            ),
          ),

          // Journey count — home screen and nav both say "journeys".
          Text(
            '${walkCount} journeys',
            style: AhmaTheme.labelTextStyle.copyWith(
              fontSize: 12.0 * phoneScale,
              color: AhmaTheme.mocha.withValues(alpha: 0.6),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final phoneScale = _phoneScale(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14 * phoneScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with action plans
          Padding(
            padding: EdgeInsets.only(bottom: 10 * phoneScale),
            child: Text(
              'Your journeys',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 15 * phoneScale,
                color: AhmaTheme.mocha.withOpacity(0.8),
              ),
            ),
          ),

          // Action plans are now integrated directly into the spiral trail

          // Spiral nodes
          Expanded(child: _buildSpiralNodes()),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActionPlanItem(BackendUpdate update) {
    final isExpanded = _expandedPlans.contains(update.callId.hashCode);
    final plan = update.actionPlan;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Node dot
        _buildNodeDotForUpdate(update),

        const SizedBox(width: 7),

        // Expandable action plan card
        Expanded(child: _buildActionPlanCard(update, plan, isExpanded)),
      ],
    );
  }

  Widget _buildActionPlanCard(
    BackendUpdate update,
    ActionPlan plan,
    bool isExpanded,
  ) {
    return Container(
      width: isExpanded ? double.infinity : 140,
      height: isExpanded ? null : 60,
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AhmaTheme.mocha.withOpacity(0.07), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(isExpanded ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with expand/collapse indicator
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _addWalkFromActionPlan(update),
                    child: Text(
                      _formatNeed(update.classification.primaryNeed),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 24.0, // 50% larger: 16 * 1.5
                            fontWeight: FontWeight.w300,
                            color: AhmaTheme.mocha,
                            decoration: TextDecoration.underline,
                            decorationColor: AhmaTheme.mocha.withOpacity(0.3),
                          ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _togglePlanExpansion(update.callId.hashCode),
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AhmaTheme.mocha.withOpacity(0.6),
                  ),
                ),
              ],
            ),

            // Description (only show when expanded)
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                plan.reasoning,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 13,
                  color: AhmaTheme.mocha.withOpacity(0.7),
                  height: 1.4,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 12),
              if (plan.calendarEvents.isNotEmpty) ...[
                Text(
                  'Calendar Events:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AhmaTheme.mocha.withOpacity(0.5),
                  ),
                ),
                ...plan.calendarEvents
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AhmaTheme.sageGreen.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                event.summary,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 12,
                                      color: AhmaTheme.mocha.withOpacity(0.8),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
              if (plan.todoistTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Tasks:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AhmaTheme.mocha.withOpacity(0.5),
                  ),
                ),
                ...plan.todoistTasks
                    .map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AhmaTheme.sageGreen.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                task.taskName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 12,
                                      color: AhmaTheme.mocha.withOpacity(0.8),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  void _addWalkFromActionPlan(BackendUpdate update) {
    final timestamp = DateTime.now();
    final timeStr =
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

    // Create a new walk entry based on the action plan
    final newWalk = WalkEntry(
      title: '${_formatNeed(update.classification.primaryNeed)} · $timeStr',
      subtitle:
          '${update.actionPlan.totalActions} action${update.actionPlan.totalActions == 1 ? '' : 's'} · ${update.stats.newActions} new',
      isActive: true,
    );

    setState(() {
      // Add the new walk at the top
      _walks.insert(0, newWalk);
    });

    // Show a snackbar to confirm
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${_formatNeed(update.classification.primaryNeed)} to your journey!',
        ),
        backgroundColor: AhmaTheme.sageGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatNeed(String need) {
    return need
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _togglePlanExpansion(int planId) {
    setState(() {
      if (_expandedPlans.contains(planId)) {
        _expandedPlans.remove(planId);
      } else {
        _expandedPlans.add(planId);
      }
    });
  }

  // ignore: unused_element
  void _toggleActionPlanExpansion(String callId) {
    setState(() {
      final planId = callId.hashCode;
      if (_expandedPlans.contains(planId)) {
        _expandedPlans.remove(planId);
      } else {
        _expandedPlans.add(planId);
      }
    });
  }

  Widget _buildSpiralNodes() {
    final phoneScale = _phoneScale(context);

    return Consumer(
      builder: (context, ref, child) {
        final backendState = ref.watch(backendProvider);
        final actionPlans = backendState.updates;

        // Combine existing walks with action plans
        // Action plans should appear at the top (after stubs) in chronological order
        final allTrailItems = <dynamic>[];

        // Add action plans first (newest at top)
        final sortedActionPlans = List<BackendUpdate>.from(actionPlans);
        sortedActionPlans.sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        ); // Newest first

        for (final update in sortedActionPlans) {
          final dateTime = _formatJourneyDateTime(update.timestamp);

          final actionPlanWalk = WalkEntry(
            title: dateTime,
            subtitle: '',
            isActive: true,
            backendUpdate: update, // Store the update for expansion
          );

          allTrailItems.add(actionPlanWalk);
        }

        // Add existing walks after action plans
        allTrailItems.addAll(_walks);

        if (allTrailItems.isEmpty) {
          return Center(
            child: Text(
              backendState.isLoading
                  ? 'Loading your journeys…'
                  : 'Your conversations will be here whenever you’re ready.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13 * phoneScale,
                color: AhmaTheme.mochaMuted,
              ),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          reverseDuration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _selectedJourney == null
              ? _buildJourneyTimeline(
                  allTrailItems,
                  phoneScale,
                  key: const ValueKey('journey-timeline'),
                )
              : _buildJourneyDetail(
                  _selectedJourney!,
                  phoneScale,
                  key: ValueKey('journey-detail-${_selectedJourney!.callId}'),
                ),
        );
      },
    );
  }

  Widget _buildJourneyTimeline(
    List<dynamic> trailItems,
    double phoneScale, {
    required Key key,
  }) {
    return SelectionContainer.disabled(
      key: key,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 10 * phoneScale,
            bottom: 10 * phoneScale,
            child: Container(
              width: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AhmaTheme.sageGreen,
                    AhmaTheme.palePink,
                    AhmaTheme.mid,
                  ],
                ),
              ),
            ),
          ),
          ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 10 * phoneScale),
            physics: const BouncingScrollPhysics(),
            itemCount: trailItems.length,
            separatorBuilder: (_, _) => SizedBox(height: 10 * phoneScale),
            itemBuilder: (_, index) => _buildTrailItem(trailItems[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyDetail(
    BackendUpdate update,
    double phoneScale, {
    required Key key,
  }) {
    final quote = selectEmpoweringSummaryQuote([update.actionPlan.summary]);
    final hasJourneyNote = quote.isFromSummary;
    final showJourneyNote = hasJourneyNote && _selectedJourneyPage == 0;

    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _detailDragDistance = 0,
      onHorizontalDragUpdate: (details) {
        _detailDragDistance += details.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_detailDragDistance > 60 || velocity > 350) {
          if (_selectedJourneyPage == 1 && hasJourneyNote) {
            setState(() => _selectedJourneyPage = 0);
          } else {
            _closeJourneyDetail();
          }
        } else if ((_detailDragDistance < -60 || velocity < -350) &&
            showJourneyNote) {
          setState(() => _selectedJourneyPage = 1);
        }
        _detailDragDistance = 0;
      },
      child: SelectionContainer.disabled(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            18 * phoneScale,
            8 * phoneScale,
            18 * phoneScale,
            24 * phoneScale,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22 * phoneScale),
                child: CustomPaint(
                  foregroundPainter: _PaperTexturePainter(),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 300 * phoneScale),
                    padding: EdgeInsets.fromLTRB(
                      30 * phoneScale,
                      18 * phoneScale,
                      18 * phoneScale,
                      24 * phoneScale,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F0E4),
                      borderRadius: BorderRadius.circular(22 * phoneScale),
                      border: Border.all(
                        color: AhmaTheme.mocha.withOpacity(0.11),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AhmaTheme.mocha.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatJourneyDateTime(update.timestamp),
                                style: AhmaTheme.labelTextStyle.copyWith(
                                  fontSize: 10.5 * phoneScale,
                                  color: AhmaTheme.sageGreen.withOpacity(0.86),
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Back to journeys',
                              onPressed: _closeJourneyDetail,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20 * phoneScale,
                                color: AhmaTheme.mocha.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(
                                      showJourneyNote ? -0.025 : 0.025,
                                      0,
                                    ),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: showJourneyNote
                              ? _buildJourneyNoteContent(
                                  quote,
                                  phoneScale,
                                  key: const ValueKey('journey-note'),
                                )
                              : _buildFullSummaryContent(
                                  update.actionPlan.summary,
                                  phoneScale,
                                  key: const ValueKey('journey-full-summary'),
                                ),
                        ),
                        SizedBox(height: 24 * phoneScale),
                        _buildJourneyNavigation(
                          phoneScale,
                          hasJourneyNote: hasJourneyNote,
                          showJourneyNote: showJourneyNote,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyNoteContent(
    SummaryQuote quote,
    double phoneScale, {
    required Key key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 27 * phoneScale),
        Icon(
          Icons.format_quote_rounded,
          size: 28 * phoneScale,
          color: AhmaTheme.mocha.withOpacity(0.7),
        ),
        SizedBox(height: 12 * phoneScale),
        Text(
          quote.text,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 16 * phoneScale,
            height: 1.55,
            fontWeight: FontWeight.w400,
            color: AhmaTheme.mocha.withOpacity(0.92),
          ),
        ),
      ],
    );
  }

  Widget _buildFullSummaryContent(
    String summary,
    double phoneScale, {
    required Key key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 23 * phoneScale),
        Text(
          'FULL CALL SUMMARY',
          style: AhmaTheme.labelTextStyle.copyWith(
            fontSize: 10 * phoneScale,
            color: AhmaTheme.mocha.withOpacity(0.68),
            letterSpacing: 0.85,
          ),
        ),
        SizedBox(height: 15 * phoneScale),
        Text(
          summary,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13 * phoneScale,
            height: 1.58,
            color: AhmaTheme.mocha.withOpacity(0.88),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyNavigation(
    double phoneScale, {
    required bool hasJourneyNote,
    required bool showJourneyNote,
  }) {
    final backLabel = showJourneyNote
        ? 'Journeys'
        : hasJourneyNote
        ? 'Your note'
        : 'Journeys';

    return SizedBox(
      height: 38 * phoneScale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildJourneyNavigationButton(
            icon: Icons.arrow_back_rounded,
            label: backLabel,
            phoneScale: phoneScale,
            onPressed: () {
              if (!showJourneyNote && hasJourneyNote) {
                setState(() => _selectedJourneyPage = 0);
              } else {
                _closeJourneyDetail();
              }
            },
          ),
          if (showJourneyNote)
            _buildJourneyNavigationButton(
              icon: Icons.arrow_forward_rounded,
              label: 'Full summary',
              phoneScale: phoneScale,
              iconAfter: true,
              onPressed: () => setState(() => _selectedJourneyPage = 1),
            ),
        ],
      ),
    );
  }

  Widget _buildJourneyNavigationButton({
    required IconData icon,
    required String label,
    required double phoneScale,
    required VoidCallback onPressed,
    bool iconAfter = false,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      iconAlignment: iconAfter ? IconAlignment.end : IconAlignment.start,
      icon: Icon(icon, size: 17 * phoneScale),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AhmaTheme.mocha.withOpacity(0.72),
        minimumSize: Size.zero,
        padding: EdgeInsets.symmetric(
          horizontal: 8 * phoneScale,
          vertical: 7 * phoneScale,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: 10.5 * phoneScale,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _openJourneyDetail(BackendUpdate update) {
    final quote = selectEmpoweringSummaryQuote([update.actionPlan.summary]);
    setState(() {
      _selectedJourney = update;
      _selectedJourneyPage = quote.isFromSummary ? 0 : 1;
    });
  }

  void _closeJourneyDetail() {
    if (!mounted) return;
    setState(() {
      _selectedJourney = null;
      _selectedJourneyPage = 0;
    });
  }

  Widget _buildTrailItem(dynamic item) {
    final phoneScale = _phoneScale(context);
    final walk = item as WalkEntry;
    final isActionPlan = walk.backendUpdate != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Node dot
        _buildNodeDot(walk),

        SizedBox(width: 7 * phoneScale),

        Expanded(
          child: GestureDetector(
            onTap: isActionPlan
                ? () => _openJourneyDetail(walk.backendUpdate!)
                : null,
            child: AnimatedContainer(
              width: double.infinity,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(vertical: 2 * phoneScale),
              child: _buildNodeCard(walk, isActionPlan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeDotForUpdate(BackendUpdate update) {
    Color dotColor = AhmaTheme.mid;
    Color borderColor = AhmaTheme.mocha.withOpacity(0.18);

    // Color based on primary need
    switch (update.classification.primaryNeed.toLowerCase()) {
      case 'mental_health':
        dotColor = AhmaTheme.palePink;
        borderColor = AhmaTheme.palePink;
        break;
      case 'seniors_help':
        dotColor = AhmaTheme.sageGreen;
        borderColor = AhmaTheme.sageGreen;
        break;
      default:
        dotColor = AhmaTheme.mid;
        borderColor = AhmaTheme.mocha.withOpacity(0.18);
    }

    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
    );
  }

  Widget _buildNodeDot(dynamic item) {
    final phoneScale = _phoneScale(context);
    Color dotColor = AhmaTheme.mid;
    Color borderColor = AhmaTheme.mocha.withOpacity(0.18);

    if (item is WalkEntry) {
      if (item.isActive) {
        dotColor = AhmaTheme.sageGreen;
        borderColor = AhmaTheme.sageGreen;
      } else if (item.isPink) {
        dotColor = AhmaTheme.palePink;
        borderColor = AhmaTheme.palePink;
      }

      if (item.isFuture) {
        return Container(
          width: 9 * phoneScale,
          height: 9 * phoneScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 1.5 * phoneScale,
              style: BorderStyle.solid,
            ),
          ),
        );
      }
    }

    return Container(
      width: 9 * phoneScale,
      height: 9 * phoneScale,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5 * phoneScale),
      ),
    );
  }

  Widget _buildNodeCard(WalkEntry walk, [bool isActionPlan = false]) {
    final phoneScale = _phoneScale(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9 * phoneScale,
        vertical: 5 * phoneScale,
      ),
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: walk.isFuture
            ? Border.all(
                color: AhmaTheme.mocha.withOpacity(0.06),
                width: 1,
                style: BorderStyle.solid,
              )
            : Border.all(color: AhmaTheme.mocha.withOpacity(0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title with expand icon if action plan
          Row(
            children: [
              Expanded(
                child: Text(
                  walk.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12 * phoneScale,
                    color: AhmaTheme.mochaMuted,
                    fontWeight: FontWeight.w300,
                    letterSpacing: walk.isFuture ? 0.04 : 0.0,
                  ),
                ),
              ),
              if (isActionPlan) ...[
                SizedBox(width: 4 * phoneScale),
                Icon(
                  Icons.expand_more,
                  size: 12 * phoneScale,
                  color: AhmaTheme.mocha.withOpacity(0.4),
                ),
                _buildDeleteMenu(walk.backendUpdate!, phoneScale),
              ],
            ],
          ),

          // Subtitle - prevent wrapping
          if (walk.subtitle.isNotEmpty) ...[
            SizedBox(height: 1 * phoneScale),
            Text(
              walk.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 13.5 * phoneScale,
                color: AhmaTheme.sageGreen,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildExpandedActionPlan(BackendUpdate update) {
    final plan = update.actionPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with collapse icon - showing date as title (exact match to collapsed)
        Row(
          children: [
            Expanded(
              child: Text(
                _formatJourneyDateTime(update.timestamp),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AhmaTheme.mochaMuted,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Icon(
              Icons.expand_less,
              size: 12,
              color: AhmaTheme.mocha.withOpacity(0.4),
            ),
            _buildDeleteMenu(update, 1),
          ],
        ),
        const SizedBox(height: 8),

        if (plan.summary.isNotEmpty) ...[
          Text(
            plan.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              height: 1.45,
              color: AhmaTheme.mochaMuted,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Tasks
        if (plan.todoistTasks.isNotEmpty) ...[
          Text(
            'Tasks',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AhmaTheme.sageGreen,
            ),
          ),
          const SizedBox(height: 4),
          ...plan.todoistTasks
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AhmaTheme.sageGreen.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.taskName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 11,
                                color: AhmaTheme.mochaMuted,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 8),
        ],

        // Resources
        if (plan.resources.isNotEmpty) ...[
          Text(
            'Resources',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AhmaTheme.palePink,
            ),
          ),
          const SizedBox(height: 4),
          ...plan.resources
              .map(
                (resource) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AhmaTheme.palePink.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          resource.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 11,
                                color: AhmaTheme.mochaMuted,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ],
    );
  }

  String _formatJourneyDateTime(DateTime timestamp) {
    return DateFormat('d MMM yyyy · h:mm a').format(timestamp.toLocal());
  }

  Widget _buildDeleteMenu(BackendUpdate update, double scale) {
    return PopupMenuButton<String>(
      tooltip: 'Journey options',
      padding: EdgeInsets.zero,
      iconSize: 17 * scale,
      icon: Icon(
        Icons.more_vert_rounded,
        color: AhmaTheme.mocha.withOpacity(0.48),
      ),
      onSelected: (value) {
        if (value == 'delete') {
          _confirmDeleteSummary(update);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 19),
              SizedBox(width: 10),
              Text('Delete summary'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteSummary(BackendUpdate update) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this summary?'),
        content: const Text(
          'This removes the journal summary from AHMA and cannot be undone. '
          'Your lifetime journey count will stay the same.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(backendProvider.notifier).deleteSummary(update.callId);
      if (!mounted) return;
      setState(() {
        _expandedPlans.remove(update.callId.hashCode);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Summary deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete summary: $error')),
      );
    }
  }
}

class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(24);
    final speckPaint = Paint()
      ..color = const Color(0xFF6D563D).withOpacity(0.035);
    final fiberPaint = Paint()
      ..color = const Color(0xFF8B7358).withOpacity(0.025)
      ..strokeWidth = 0.6;

    for (var i = 0; i < 95; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(point, 0.35 + random.nextDouble() * 0.45, speckPaint);
    }

    for (var i = 0; i < 28; i++) {
      final start = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawLine(
        start,
        start + Offset(3 + random.nextDouble() * 7, random.nextDouble() - 0.5),
        fiberPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
