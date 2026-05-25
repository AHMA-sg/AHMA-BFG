import 'package:flutter/material.dart';
import '../../core/theme/ahma_theme.dart';

enum AhmaNavTab { profile, call, kopi }

class AhmaBottomNav extends StatelessWidget {
  final AhmaNavTab currentTab;
  final Function(AhmaNavTab) onTabChanged;

  const AhmaBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: AhmaTheme.background.withOpacity(0.96),
        border: Border(
          top: BorderSide(color: AhmaTheme.mocha.withOpacity(0.07), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: _buildNavItem(
                  context,
                  AhmaNavTab.profile,
                  _buildProfileIcon(),
                  'home',
                ),
              ),
            ),
            Expanded(child: Center(child: _buildCallButton(context))),
            Expanded(
              child: Center(
                child: _buildNavItem(
                  context,
                  AhmaNavTab.kopi,
                  _buildKopiIcon(),
                  'journeys',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AhmaNavTab tab,
    Widget icon,
    String label,
  ) {
    final isActive = currentTab == tab;

    return GestureDetector(
      onTap: () => onTabChanged(tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(opacity: isActive ? 1.0 : 0.45, child: icon),
            const SizedBox(height: 8),
            Text(
              label,
              style: AhmaTheme.navLabelStyle.copyWith(
                color: isActive
                    ? AhmaTheme.sageGreen
                    : AhmaTheme.mocha.withOpacity(0.35),
                fontSize: (AhmaTheme.navLabelStyle.fontSize ?? 10) * 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onTabChanged(AhmaNavTab.call),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AhmaTheme.sageGreen,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AhmaTheme.sageGreen.withOpacity(0.25),
                      width: 2.2,
                    ),
                  ),
                ),
                Image.asset(
                  'resources/Phone-on.png', // Changed from ahma logo
                  width: 48,
                  height: 48,
                ),
              ],
            ),
          ),
          // Removed 'ahma' text
        ],
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Image.asset('resources/ahma-logo.png', width: 44, height: 44);
  }

  Widget _buildKopiIcon() {
    return Image.asset('resources/Kopi.png', width: 44, height: 44);
  }
}

class _ProfileIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Body (ellipse)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.65),
      width: size.width * 0.64,
      height: size.height * 0.45,
    );
    canvas.drawOval(bodyRect, paint);

    // Head (ellipse)
    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.4),
      width: size.width * 0.41,
      height: size.height * 0.32,
    );

    final headPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.75)
      ..style = PaintingStyle.fill;
    canvas.drawOval(headRect, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KopiIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Body (ellipse)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.45, size.height * 0.65),
      width: size.width * 0.5,
      height: size.height * 0.36,
    );
    canvas.drawOval(bodyRect, paint);

    // Head (ellipse)
    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.45, size.height * 0.45),
      width: size.width * 0.32,
      height: size.height * 0.25,
    );

    final headPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(headRect, headPaint);

    // Legs (lines)
    final legPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.65)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    // Left leg
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.73),
      Offset(size.width * 0.25, size.height * 0.91),
      legPaint,
    );

    // Middle leg
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.77),
      Offset(size.width * 0.43, size.height * 0.95),
      legPaint,
    );

    // Right leg
    canvas.drawLine(
      Offset(size.width * 0.59, size.height * 0.73),
      Offset(size.width * 0.64, size.height * 0.91),
      legPaint,
    );

    // Shell (rectangle)
    final shellRect = Rect.fromLTWH(
      size.width * 0.61,
      size.height * 0.30,
      size.width * 0.23,
      size.height * 0.18,
    );

    final shellPaint = Paint()
      ..color = AhmaTheme.mid.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(shellRect, const Radius.circular(1)),
      shellPaint,
    );

    // Shell opening
    final shellOpeningRect = Rect.fromLTWH(
      size.width * 0.64,
      size.height * 0.34,
      size.width * 0.18,
      size.height * 0.09,
    );

    final shellOpeningPaint = Paint()
      ..color = AhmaTheme.mocha.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(shellOpeningRect, const Radius.circular(0.5)),
      shellOpeningPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
