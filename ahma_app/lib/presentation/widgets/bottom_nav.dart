import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AhmaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AhmaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.bg.withOpacity(0.96),
        border: Border(top: BorderSide(color: AppTheme.mocha.withOpacity(0.07))),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap,
              label: 'me',
              icon: const _TurtleHalfIcon(),
            ),
            _CallNavItem(
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              index: 2,
              currentIndex: currentIndex,
              onTap: onTap,
              label: 'kopi',
              icon: const _WalkingTurtleIcon(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String label;
  final Widget icon;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.label,
    required this.icon,
  });

  bool get isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTheme.mono(
                  size: 9,
                  color: isActive ? AppTheme.sage : AppTheme.mocha,
                  opacity: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CallNavItem({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.sage.withOpacity(0.25)),
                ),
              ),
              Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.sage,
                ),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'ahma',
            style: AppTheme.mono(
              size: 9,
              color: isActive ? AppTheme.sage : AppTheme.mocha,
              opacity: isActive ? 1.0 : 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Turtle icons ──────────────────────────────────────────────────────────────

class _TurtleHalfIcon extends StatelessWidget {
  const _TurtleHalfIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24, height: 24,
      child: CustomPaint(painter: _TurtleHalfPainter()),
    );
  }
}

class _TurtleHalfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = AppTheme.sage.withOpacity(0.75)..style = PaintingStyle.fill;
    final shell = Paint()..color = const Color(0xFF8A8A72).withOpacity(0.85)..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.62), width: size.width * 1.1, height: size.height * 0.78), body);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.5), width: size.width * 0.75, height: size.height * 0.6), shell);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _WalkingTurtleIcon extends StatelessWidget {
  const _WalkingTurtleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24, height: 24,
      child: CustomPaint(painter: _WalkingTurtlePainter()),
    );
  }
}

class _WalkingTurtlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = AppTheme.sage.withOpacity(0.75)..style = PaintingStyle.fill;
    final shell = Paint()..color = const Color(0xFF8A8A72).withOpacity(0.8)..style = PaintingStyle.fill;
    final leg = Paint()
      ..color = AppTheme.sage.withOpacity(0.7)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cupBody = Paint()..color = AppTheme.mid.withOpacity(0.75)..style = PaintingStyle.fill;
    final cupFill = Paint()..color = AppTheme.coffee.withOpacity(0.6)..style = PaintingStyle.fill;

    // Body
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.42, size.height * 0.62), width: size.width * 0.82, height: size.height * 0.62), body);
    // Shell
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.42, size.height * 0.52), width: size.width * 0.58, height: size.height * 0.5), shell);
    // Legs
    canvas.drawLine(Offset(size.width * 0.28, size.height * 0.72), Offset(size.width * 0.18, size.height * 0.92), leg);
    canvas.drawLine(Offset(size.width * 0.42, size.height * 0.78), Offset(size.width * 0.38, size.height * 0.96), leg);
    canvas.drawLine(Offset(size.width * 0.56, size.height * 0.72), Offset(size.width * 0.64, size.height * 0.92), leg);
    // Tiny kopi cup
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.7, size.height * 0.28, size.width * 0.26, size.height * 0.24), const Radius.circular(2)), cupBody);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.72, size.height * 0.36, size.width * 0.22, size.height * 0.12), const Radius.circular(1)), cupFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
