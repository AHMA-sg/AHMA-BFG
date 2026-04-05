import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/ahma_bottom_nav.dart';
import '../widgets/ahma_phone_container.dart';
import '../../core/theme/ahma_theme.dart';
import 'ahma_call_screen.dart';
import 'kopi_journal_screen.dart';
import 'profile_screen.dart';

/// Main AHMA Screen with Bottom Navigation
/// 
/// This is the new main screen that replaces the old home screen
/// and provides navigation between the three core experiences:
/// - Profile (affirmations, user stats)
/// - Call (AHMA voice interaction)
/// - Kopi (journal with spiral timeline)
class AhmaMainScreen extends ConsumerStatefulWidget {
  const AhmaMainScreen({super.key});

  @override
  ConsumerState<AhmaMainScreen> createState() => _AhmaMainScreenState();
}

class _AhmaMainScreenState extends ConsumerState<AhmaMainScreen> {
  AhmaNavTab _currentTab = AhmaNavTab.profile;

  @override
  Widget build(BuildContext context) {
    return AhmaPhoneContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Status bar
            const AhmaStatusBar(),
            
            // Main content
            Expanded(
              child: _buildCurrentScreen(),
            ),
            
            // Bottom navigation
            AhmaBottomNav(
              currentTab: _currentTab,
              onTabChanged: _onTabChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTab) {
      case AhmaNavTab.profile:
        return const ProfileScreen();
      case AhmaNavTab.call:
        return const AhmaCallScreen();
      case AhmaNavTab.kopi:
        return const KopiJournalScreen();
    }
  }

  void _onTabChanged(AhmaNavTab tab) {
    setState(() {
      _currentTab = tab;
    });
  }
}
