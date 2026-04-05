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
      height: 64,
      decoration: BoxDecoration(
        color: AhmaTheme.background.withOpacity(0.96),
        border: Border(
          top: BorderSide(
            color: AhmaTheme.mocha.withOpacity(0.07),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 6, right: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              AhmaNavTab.profile,
              _buildProfileIcon(),
              'me',
            ),
            _buildCallButton(context),
            _buildNavItem(
              context,
              AhmaNavTab.kopi,
              _buildKopiIcon(),
              'kopi',
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isActive ? 1.0 : 0.45,
              child: icon,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AhmaTheme.navLabelStyle.copyWith(
                color: isActive ? AhmaTheme.sageGreen : AhmaTheme.mocha.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final isActive = currentTab == AhmaNavTab.call;
    
    return GestureDetector(
      onTap: () => onTabChanged(AhmaNavTab.call),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AhmaTheme.sageGreen,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AhmaTheme.sageGreen.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                ),
                Icon(
                  Icons.mic,
                  size: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ahma',
            style: AhmaTheme.navLabelStyle.copyWith(
              color: isActive ? AhmaTheme.sageGreen : AhmaTheme.mocha.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _ProfileIconPainter(),
      ),
    );
  }

  Widget _buildKopiIcon() {
    return Image.asset(
      'resources/Kopi.png',
      width: 22,
      height: 22,
    );
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
