import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/ahma_theme.dart';
import '../../data/models/action_plan.dart';
import '../providers/backend_provider.dart';

class WalkEntry {
  final String title;
  final String subtitle;
  final String? collectible;
  final bool isActive;
  final bool isPink;
  final bool isFuture;
  final BackendUpdate? backendUpdate;

  const WalkEntry({
    required this.title,
    required this.subtitle,
    this.collectible,
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

  @override
  void initState() {
    super.initState();
    _walks = [
      const WalkEntry(
        title: 'Tuesday evening',
        subtitle: 'breathing · 8 min',
        collectible: 'kopi',
        isActive: true,
      ),
      const WalkEntry(
        title: 'Sunday, heavy heart',
        subtitle: 'just talking · 22 min',
        isPink: true,
      ),
      const WalkEntry(
        title: 'Thursday morning',
        subtitle: 'grounding · 5 min',
        collectible: '✦',
      ),
      const WalkEntry(
        title: 'first walk',
        subtitle: 'introduced · hello',
      ),
      const WalkEntry(
        title: 'more to come',
        subtitle: '',
        isFuture: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show watercolor background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with logo and walk count
            _buildTopBar(),
            
            // Main content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final walkCount = _walks.where((walk) => !walk.isFuture).length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Text(
            'AHMA',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AhmaTheme.ahmaRed,
              letterSpacing: 0.8,
            ),
          ),
          
          // Walk count
          Text(
            '${walkCount} walks',
            style: AhmaTheme.labelTextStyle.copyWith(
              fontSize: 12.0, // 50% larger: 8 * 1.5
              color: AhmaTheme.mocha.withOpacity(0.35),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with action plans
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Your Journey',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 15, // 50% larger: 15 * 1.5
                color: AhmaTheme.mocha.withOpacity(0.8),
              ),
            ),
          ),
          
          // Action plans are now integrated directly into the spiral trail
          
          // Spiral nodes
          Expanded(
            child: _buildSpiralNodes(),
          ),
        ],
      ),
    );
  }

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
        Expanded(
          child: _buildActionPlanCard(update, plan, isExpanded),
        ),
        
        // Collectible (if any)
        const SizedBox(width: 7),
        _buildCollectible('✦'),
      ],
    );
  }

  Widget _buildActionPlanCard(BackendUpdate update, ActionPlan plan, bool isExpanded) {
    return Container(
      width: isExpanded ? double.infinity : 140,
      height: isExpanded ? null : 60,
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AhmaTheme.mocha.withOpacity(0.07),
          width: 1,
        ),
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
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                ...plan.calendarEvents.map((event) => Padding(
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 12,
                            color: AhmaTheme.mocha.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
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
                ...plan.todoistTasks.map((task) => Padding(
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 12,
                            color: AhmaTheme.mocha.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
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
    final timeStr = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    
    // Create a new walk entry based on the action plan
    final newWalk = WalkEntry(
      title: '${_formatNeed(update.classification.primaryNeed)} · $timeStr',
      subtitle: '${update.actionPlan.totalActions} action${update.actionPlan.totalActions == 1 ? '' : 's'} · ${update.stats.newActions} new',
      collectible: 'kopi',
      isActive: true,
    );
    
    setState(() {
      // Remove the 'more to come' future entry if it exists
      _walks = _walks.where((walk) => !walk.isFuture).toList();
      // Add the new walk at the top
      _walks.insert(0, newWalk);
      // Add back the 'more to come' entry
      _walks.add(const WalkEntry(
        title: 'more to come',
        subtitle: '',
        isFuture: true,
      ));
    });
    
    // Show a snackbar to confirm
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_formatNeed(update.classification.primaryNeed)} to your journey!'),
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
    return Consumer(
      builder: (context, ref, child) {
        final backendState = ref.watch(backendProvider);
        final actionPlans = backendState.updates;
        
        // Combine existing walks with action plans
        // Action plans should appear at the top (after stubs) in chronological order
        final allTrailItems = <dynamic>[];
        
        // Add action plans first (newest at top)
        final sortedActionPlans = List.from(actionPlans.take(3));
        sortedActionPlans.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
        
        for (final update in sortedActionPlans) {
          final timestamp = update.timestamp;
          final dateStr = '${timestamp.day}/${timestamp.month}';
          
          // Calculate call duration (placeholder - you might need to store actual duration)
          final callDuration = '5 min'; // TODO: Get actual call duration from data
          
          final topic = _formatNeed(update.classification.primaryNeed);
          final actionPlanWalk = WalkEntry(
            title: dateStr, // Title is now the date
            subtitle: '$topic · $callDuration', // Topic with duration
            collectible: 'kopi',
            isActive: true,
            backendUpdate: update, // Store the update for expansion
          );
          
          allTrailItems.add(actionPlanWalk);
        }
        
        // Add existing walks after action plans
        allTrailItems.addAll(_walks);
        
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 255,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Stack(
              children: [
                // Spiral line
                Positioned(
                  left: 4,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 1,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
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
                
                // Nodes (walks + action plans) with dynamic positioning
                ..._buildDynamicTrailItems(allTrailItems),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDynamicTrailItems(List<dynamic> allTrailItems) {
    final items = <Widget>[];
    double currentTop = 10.0;
    
    for (int index = 0; index < allTrailItems.length; index++) {
      final item = allTrailItems[index];
      final walk = item as WalkEntry;
      final isActionPlan = walk.backendUpdate != null;
      final isExpanded = isActionPlan && _expandedPlans.contains(walk.backendUpdate!.callId.hashCode);
      
      // Calculate height for this item based on expansion state
      double itemHeight = 55.0; // Default height
      if (isExpanded && isActionPlan) {
        // Calculate expanded height based on content
        final update = walk.backendUpdate!;
        final plan = update.actionPlan;
        int contentCount = plan.todoistTasks.length + plan.resources.length;
        itemHeight = 55.0 + (contentCount * 15.0) + 40.0; // Base + content + padding
      }
      
      final leftOffset = index % 2 == 0 ? 0.0 : (index % 3 == 1 ? 12.0 : 16.0);
      
      items.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          top: currentTop,
          left: leftOffset,
          child: _buildTrailItem(item),
        ),
      );
      
      // Move to next position
      currentTop += itemHeight + 10.0;
    }
    
    return items;
  }

  Widget _buildTrailItem(dynamic item) {
    final walk = item as WalkEntry;
    final isActionPlan = walk.backendUpdate != null;
    final isExpanded = isActionPlan && _expandedPlans.contains(walk.backendUpdate!.callId.hashCode);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Node dot
        _buildNodeDot(walk),
        
        const SizedBox(width: 7),
        
        // Expandable node card
        GestureDetector(
          onTap: isActionPlan ? () => _toggleActionPlanExpansion(walk.backendUpdate!.callId) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            constraints: BoxConstraints(
              minWidth: isExpanded ? 200 : 120,
              maxWidth: isExpanded ? 280 : 150,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 12 : 8,
              vertical: isExpanded ? 10 : 6,
            ),
            decoration: BoxDecoration(
              color: isExpanded && isActionPlan 
                ? AhmaTheme.cardColor.withOpacity(0.1) // Subtle cream card fade in
                : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isExpanded && isActionPlan
                  ? AhmaTheme.mocha.withOpacity(0.05) // Subtle border fade in
                  : Colors.transparent,
                width: 1,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isExpanded && isActionPlan
                ? _buildExpandedActionPlan(walk.backendUpdate!)
                : _buildNodeCard(walk, isActionPlan),
            ),
          ),
        ),
        
        // Collectible (if any)
        if (walk.collectible != null) ...[
          const SizedBox(width: 7),
          _buildCollectible(walk.collectible!),
        ],
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
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildNodeDot(dynamic item) {
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
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
        );
      }
    }
    
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildNodeCard(WalkEntry walk, [bool isActionPlan = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: walk.isFuture 
          ? Border.all(
              color: AhmaTheme.mocha.withOpacity(0.06),
              width: 1,
              style: BorderStyle.solid,
            )
          : Border.all(
              color: AhmaTheme.mocha.withOpacity(0.07),
              width: 1,
            ),
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
                    fontSize: 10,
                    color: AhmaTheme.mocha.withOpacity(0.8),
                    fontWeight: FontWeight.w300,
                    letterSpacing: walk.isFuture ? 0.04 : 0.0,
                  ),
                ),
              ),
              if (isActionPlan) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more,
                  size: 12,
                  color: AhmaTheme.mocha.withOpacity(0.4),
                ),
              ],
            ],
          ),
          
          // Subtitle - prevent wrapping
          if (walk.subtitle.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              walk.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 13.5, // 50% larger: 9 * 1.5
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

  Widget _buildCollectible(String emoji) {
    Color bgColor = AhmaTheme.sageGreen.withOpacity(0.2);
    
    if (emoji == '☕' || emoji == 'kopi') {
      bgColor = AhmaTheme.palePink.withOpacity(0.3);
    } else if (emoji == '?') {
      bgColor = AhmaTheme.mid.withOpacity(0.3);
    }
    
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: emoji == '?' 
          ? Border.all(
              color: AhmaTheme.mocha.withOpacity(0.15),
              width: 1,
              style: BorderStyle.solid,
            )
          : null,
      ),
      child: Center(
        child: emoji == 'kopi' 
          ? Image.asset(
              'resources/Kopi.png',
              width: 12,
              height: 12,
            )
          : Text(
              emoji,
              style: AhmaTheme.labelTextStyle.copyWith(
                fontSize: 8,
                color: AhmaTheme.mocha.withOpacity(0.6),
              ),
            ),
      ),
    );
  }

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
                '${update.timestamp.day}/${update.timestamp.month}', // Date as title
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AhmaTheme.mocha.withOpacity(0.8),
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Icon(
              Icons.expand_less,
              size: 12,
              color: AhmaTheme.mocha.withOpacity(0.4),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Topic with duration below date (exact match to collapsed subtitle)
        Text(
          '${_formatNeed(update.classification.primaryNeed)} · 5 min', // Topic with duration
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 9, // Match collapsed subtitle size (13.5 is scaled down)
            fontWeight: FontWeight.w300,
            color: AhmaTheme.sageGreen, // Match collapsed subtitle color
            letterSpacing: 0.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        
        // Tasks
        if (plan.todoistTasks.isNotEmpty) ...[
          Text(
            'Tasks',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AhmaTheme.sageGreen,
            ),
          ),
          const SizedBox(height: 4),
          ...plan.todoistTasks.map((task) => Padding(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      color: AhmaTheme.mocha.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 8),
        ],
        
        // Resources
        if (plan.resources.isNotEmpty) ...[
          Text(
            'Resources',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AhmaTheme.palePink,
            ),
          ),
          const SizedBox(height: 4),
          ...plan.resources.map((resource) => Padding(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      color: AhmaTheme.mocha.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ],
    );
  }
}
