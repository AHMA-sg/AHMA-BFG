import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/ahma_theme.dart';
import 'watercolor_background.dart';

/// AHMA Phone Container
///
/// Mimics the exact phone container from the HTML design
/// with watercolor background and grain texture overlay
class AhmaPhoneContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double scaleFactor;

  const AhmaPhoneContainer({
    super.key,
    required this.child,
    this.width = 272, // Original size - scaling will handle the rest
    this.height = 570, // Original size - scaling will handle the rest
    this.scaleFactor = 1.2, // 20% larger by default
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (width ?? 272) * scaleFactor;
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (height ?? 570) * scaleFactor;
        final isPhoneViewport = viewportWidth <= 480;
        final isTabletViewport =
            viewportWidth <= 768 && viewportHeight <= 950;
        final outerPadding = isPhoneViewport ? 12.0 : 24.0;
        final maxShellHeight = isPhoneViewport
            ? double.infinity
            : (isTabletViewport ? 820.0 : 720.0);
        final targetHeight = constraints.maxHeight.isFinite
            ? math.min(
                constraints.maxHeight - (outerPadding * 2),
                maxShellHeight,
              )
            : (height ?? 570) * scaleFactor;
        final aspectRatio = (width ?? 272) / (height ?? 570);
        final targetWidth = constraints.maxWidth.isFinite
            ? math.min(
                constraints.maxWidth - (outerPadding * 2),
                targetHeight * aspectRatio,
              )
            : (width ?? 272) * scaleFactor;
        final shellWidth = math.max(width ?? 272, targetWidth);
        final shellHeight = shellWidth / aspectRatio;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(outerPadding),
            child: Container(
              width: shellWidth,
              height: shellHeight,
              decoration: BoxDecoration(
                color: AhmaTheme.background,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: AhmaTheme.mocha.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: WatercolorBackground(opacity: 0.55, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Status bar widget matching the HTML design
class AhmaStatusBar extends StatelessWidget {
  const AhmaStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Empty status bar - no time or battery
  }
}

/// Top bar with logo and optional end button
class AhmaTopBar extends StatelessWidget {
  final String? title;
  final VoidCallback? onEndPressed;
  final Widget? trailing;

  const AhmaTopBar({
    super.key,
    this.title = 'AHMA',
    this.onEndPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // End button or leading widget
          onEndPressed != null
              ? GestureDetector(
                  onTap: onEndPressed,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AhmaTheme.ahmaRed.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AhmaTheme.ahmaRed.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 11,
                      color: AhmaTheme.ahmaRed,
                    ),
                  ),
                )
              : trailing ?? const SizedBox(width: 26),

          // Logo/title
          Text(
            title!,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AhmaTheme.ahmaRed,
              letterSpacing: 0.8,
            ),
          ),

          // Trailing widget or empty space for balance
          const SizedBox(width: 26),
        ],
      ),
    );
  }
}
