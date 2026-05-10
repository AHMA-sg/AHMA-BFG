import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../widgets/house_animation.dart';
import 'ahma_call_screen.dart';
import 'kopi_journal_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback? onOpenCallJourney;
  final VoidCallback? onOpenPastJourneys;

  const ProfileScreen({
    super.key,
    this.onOpenCallJourney,
    this.onOpenPastJourneys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final houseHeight = screenHeight * 0.29;

    return Scaffold(
      backgroundColor: AhmaTheme.backgroundInner,
      body: Container(
        color: AhmaTheme.backgroundInner,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHero(
                  onOpenCallJourney: () => _openCallJourney(context),
                  onOpenPastJourneys: () => _openPastJourneys(context),
                ),
                const SizedBox(height: 18),
                _AffirmationCard(),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    'welcome home',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontStyle: FontStyle.italic,
                      color: AhmaTheme.mocha.withOpacity(0.62),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AhmaTheme.palePink.withOpacity(0.7),
                    size: 22,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -14),
                  child: Center(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.98,
                        child: HouseAnimationCinematic(height: houseHeight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCallJourney(BuildContext context) {
    if (onOpenCallJourney != null) {
      onOpenCallJourney!();
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AhmaCallScreen()));
  }

  void _openPastJourneys(BuildContext context) {
    if (onOpenPastJourneys != null) {
      onOpenPastJourneys!();
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const KopiJournalScreen()));
  }
}

class _ProfileHero extends StatelessWidget {
  final VoidCallback onOpenCallJourney;
  final VoidCallback onOpenPastJourneys;

  const _ProfileHero({
    required this.onOpenCallJourney,
    required this.onOpenPastJourneys,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AHMA',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 44,
                      color: AhmaTheme.ahmaRed,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Your AI care companion',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 18,
                              color: AhmaTheme.mocha.withOpacity(0.64),
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.1,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.favorite_rounded,
                        color: AhmaTheme.palePink.withOpacity(0.8),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.28),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    color: AhmaTheme.ahmaRed.withOpacity(0.72),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 34,
              color: AhmaTheme.mocha.withOpacity(0.95),
              height: 1.1,
            ),
            children: [
              const TextSpan(text: 'Good morning, '),
              TextSpan(
                text: 'Abhi',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 34,
                  color: AhmaTheme.mocha.withOpacity(0.95),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              color: AhmaTheme.palePink.withOpacity(0.75),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              "You've been on 4 walks.",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 19,
                color: AhmaTheme.mocha.withOpacity(0.88),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _CallJourneyCard(onTap: onOpenCallJourney),
        const SizedBox(height: 14),
        _PastJourneysCard(onTap: onOpenPastJourneys),
      ],
    );
  }
}

class _CallJourneyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CallJourneyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(34),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF6A7151), AhmaTheme.sageGreen],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -14,
                child: Opacity(
                  opacity: 0.12,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: _LeafPainter(),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a call journey',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: 27,
                                color: Colors.white,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            'Talk to your AI companion for care guidance and support.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 18,
                                  height: 1.35,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PhoneOrb(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastJourneysCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PastJourneysCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AhmaTheme.cardColor.withOpacity(0.68),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE6D2BE), width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AhmaTheme.palePink.withOpacity(0.28),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AhmaTheme.ahmaRed.withOpacity(0.6),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your past journeys',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 23,
                            color: Colors.black.withOpacity(0.9),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'View your previous calls and summaries.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        color: AhmaTheme.mocha.withOpacity(0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black.withOpacity(0.82),
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
          decoration: BoxDecoration(
            color: AhmaTheme.cardColor.withOpacity(0.74),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFE8D7C5), width: 1.35),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AffirmationCopy(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 150,
                        height: 200,
                        child: Image.asset(
                          'resources/full-cup.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _AffirmationCopy()),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      height: 230,
                      child: Image.asset(
                        'resources/full-cup.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _AffirmationCopy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.format_quote_rounded,
          color: const Color(0xFFFFC85A),
          size: 42,
        ),
        const SizedBox(height: 8),
        Text(
          'TODAY\'S AFFIRMATION',
          style: AhmaTheme.labelTextStyle.copyWith(
            fontSize: 11.5,
            color: AhmaTheme.sageGreen.withOpacity(0.9),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "You don't have to have it all figured out. Resting is also moving forward.",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            color: Colors.black.withOpacity(0.92),
            height: 1.32,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'From your 3rd journey',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 17,
            color: AhmaTheme.mocha.withOpacity(0.74),
          ),
        ),
      ],
    );
  }
}

class _PhoneOrb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 138,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFAF5EE),
            ),
            child: Center(
              child: Image.asset(
                'resources/Phone-on.png',
                width: 42,
                height: 42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.72,
        size.width * 0.56,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.18,
        size.width * 0.5,
        size.height * 0.02,
      );
    canvas.drawPath(path, stemPaint);

    void drawLeaf(double x, double y, double w, double h, double rotation) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        leafPaint,
      );
      canvas.restore();
    }

    drawLeaf(size.width * 0.34, size.height * 0.7, 18, 34, -0.6);
    drawLeaf(size.width * 0.66, size.height * 0.65, 18, 34, 0.7);
    drawLeaf(size.width * 0.36, size.height * 0.46, 16, 30, -0.9);
    drawLeaf(size.width * 0.68, size.height * 0.34, 16, 30, 0.9);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF9FB28D).withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = const Color(0xFFDDE6D4).withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final petalPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF4B8), Color(0xFFF7C95E)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 26));

    final centerPaint = Paint()
      ..color = const Color(0xFFD9A34A)
      ..style = PaintingStyle.fill;

    void drawStem(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.quadraticBezierTo(
          (points[i - 1].dx + points[i].dx) / 2,
          (points[i - 1].dy + points[i].dy) / 2,
          points[i].dx,
          points[i].dy,
        );
      }
      canvas.drawPath(path, stemPaint);
    }

    void drawLeaf(Offset center, Size leafSize, double rotation) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          -leafSize.width * 0.5,
          -leafSize.height * 0.15,
          0,
          -leafSize.height,
        )
        ..quadraticBezierTo(
          leafSize.width * 0.45,
          -leafSize.height * 0.2,
          0,
          0,
        );
      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    void drawFlower(Offset center, double radius, {double scale = 1}) {
      for (var i = 0; i < 10; i++) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate((math.pi * 2 / 10) * i);
        final rect = Rect.fromCenter(
          center: Offset(0, -radius * 0.6),
          width: radius * 0.8 * scale,
          height: radius * 1.35 * scale,
        );
        canvas.drawOval(rect, petalPaint);
        canvas.restore();
      }
      canvas.drawCircle(center, radius * 0.36 * scale, centerPaint);
      canvas.drawCircle(
        center,
        radius * 0.18 * scale,
        Paint()..color = const Color(0xFFFCE9A0),
      );
    }

    drawStem([
      Offset(size.width * 0.54, size.height),
      Offset(size.width * 0.58, size.height * 0.76),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.58, size.height * 0.22),
    ]);
    drawStem([
      Offset(size.width * 0.74, size.height),
      Offset(size.width * 0.7, size.height * 0.76),
      Offset(size.width * 0.76, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.16),
    ]);
    drawStem([
      Offset(size.width * 0.63, size.height),
      Offset(size.width * 0.62, size.height * 0.82),
      Offset(size.width * 0.67, size.height * 0.62),
      Offset(size.width * 0.64, size.height * 0.32),
    ]);

    drawLeaf(
      Offset(size.width * 0.51, size.height * 0.85),
      const Size(22, 38),
      -0.8,
    );
    drawLeaf(
      Offset(size.width * 0.67, size.height * 0.78),
      const Size(20, 42),
      0.6,
    );
    drawLeaf(
      Offset(size.width * 0.55, size.height * 0.67),
      const Size(22, 40),
      -0.35,
    );
    drawLeaf(
      Offset(size.width * 0.76, size.height * 0.6),
      const Size(20, 38),
      0.65,
    );
    drawLeaf(
      Offset(size.width * 0.59, size.height * 0.48),
      const Size(22, 40),
      -0.7,
    );
    drawLeaf(
      Offset(size.width * 0.72, size.height * 0.39),
      const Size(18, 34),
      0.4,
    );
    drawLeaf(
      Offset(size.width * 0.44, size.height * 0.91),
      const Size(18, 30),
      -0.4,
    );

    drawFlower(Offset(size.width * 0.47, size.height * 0.56), 26);
    drawFlower(Offset(size.width * 0.59, size.height * 0.23), 18, scale: 0.8);
    drawFlower(Offset(size.width * 0.78, size.height * 0.3), 12, scale: 0.72);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
