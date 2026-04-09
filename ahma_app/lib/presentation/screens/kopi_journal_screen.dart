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

  const WalkEntry({
    required this.title,
    required this.subtitle,
    this.collectible,
    this.isActive = false,
    this.isPink = false,
    this.isFuture = false,
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
          
          // Action plans section
          Consumer(
            builder: (context, ref, child) {
              final backendState = ref.watch(backendProvider);
              final actionPlans = backendState.updates;
              
              if (actionPlans.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /*Text(
                        'Action Plans',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 27.0, // 50% larger: 18 * 1.5
                          fontWeight: FontWeight.w300,
                          color: AhmaTheme.mocha.withOpacity(0.5),
                        ),
                      ), */
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AhmaTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AhmaTheme.mocha.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'No action plans yet. Complete a voice call to generate your first walk!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16.5, // 50% larger: 11 * 1.5
                            color: AhmaTheme.mocha.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Action Plans',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 27.0, // 50% larger: 18 * 1.5
                        fontWeight: FontWeight.w300,
                        color: AhmaTheme.mocha,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display action plans as trail items
                    ...actionPlans.take(3).map((update) => _buildActionPlanItem(update)).toList(),
                  ],
                ),
              );
            },
          ),
          
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

  Widget _buildSpiralNodes() {
    return SizedBox(
      height: 255,
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
          
          // Nodes
          ..._walks.asMap().entries.map((entry) {
            final index = entry.key;
            final walk = entry.value;
            final topPosition = index * 55.0;
            final leftOffset = index % 2 == 0 ? 0.0 : (index % 3 == 1 ? 12.0 : 16.0);
            
            return Positioned(
              top: topPosition,
              left: leftOffset,
              child: _buildNodeItem(walk),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNodeItem(WalkEntry walk) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Node dot
        _buildNodeDot(walk),
        
        const SizedBox(width: 7),
        
        // Node card
        _buildNodeCard(walk),
        
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

  Widget _buildNodeCard(WalkEntry walk) {
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
          // Title
          Text(
            walk.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 10,
              color: AhmaTheme.mocha.withOpacity(0.8),
              fontWeight: FontWeight.w300,
              letterSpacing: walk.isFuture ? 0.04 : 0.0,
            ),
          ),
          
          // Subtitle
          if (walk.subtitle.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              walk.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 13.5, // 50% larger: 9 * 1.5
                color: AhmaTheme.sageGreen,
                fontWeight: FontWeight.w300,
              ),
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
}
