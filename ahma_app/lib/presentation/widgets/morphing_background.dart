import 'package:flutter/material.dart';
import '../../data/models/call_model.dart';

/// Morphing gradient background that changes based on call stage
///
/// Stage colors:
/// - Assess: Blue/Teal gradient (calming, assessment)
/// - Support: Green/Emerald gradient (growth, support)
/// - Evaluate: Purple/Violet gradient (reflection, evaluation)
class MorphingBackground extends StatelessWidget {
  final CallStage stage;
  final Duration transitionDuration;

  const MorphingBackground({
    super.key,
    required this.stage,
    this.transitionDuration = const Duration(seconds: 2),
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForStage(stage);

    return AnimatedContainer(
      duration: transitionDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  List<Color> _getColorsForStage(CallStage stage) {
    switch (stage) {
      case CallStage.assess:
        return [
          const Color(0xFF4A90E2), // Bright blue
          const Color(0xFF50E3C2), // Turquoise
          const Color(0xFFB8E6E1), // Light teal
        ];

      case CallStage.support:
        return [
          const Color(0xFF7ED321), // Lime green
          const Color(0xFF50E3A0), // Mint green
          const Color(0xFFB8F5E1), // Pale green
        ];

      case CallStage.evaluate:
        return [
          const Color(0xFF9013FE), // Purple
          const Color(0xFFBD10E0), // Magenta
          const Color(0xFFE8D5F5), // Lavender
        ];
    }
  }
}

/// Static helper to get stage color for UI elements
class StageColors {
  static Color getPrimary(CallStage stage) {
    switch (stage) {
      case CallStage.assess:
        return const Color(0xFF4A90E2); // Blue
      case CallStage.support:
        return const Color(0xFF7ED321); // Green
      case CallStage.evaluate:
        return const Color(0xFF9013FE); // Purple
    }
  }

  static Color getSecondary(CallStage stage) {
    switch (stage) {
      case CallStage.assess:
        return const Color(0xFF50E3C2); // Turquoise
      case CallStage.support:
        return const Color(0xFF50E3A0); // Mint
      case CallStage.evaluate:
        return const Color(0xFFBD10E0); // Magenta
    }
  }
}
