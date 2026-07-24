import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ahma_theme.dart';
import '../../core/utils/summary_quote.dart';
import '../providers/backend_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/house_animation.dart';
import 'account_screen.dart';
import 'ahma_call_screen.dart';
import 'kopi_journal_screen.dart';

const double _profileDesignWidth = 457;
const double _profileDesignHeight = 760;
const double _profileCompactDesignHeight = 620;
const double _profileTextScale = 0.96;

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
    // Profile-derived greeting (replaces the old hardcoded "Sam").
    final displayName =
        ref.watch(profileGateProvider).profile?.displayName ?? 'friend';
    final updates = ref.watch(backendProvider.select((state) => state.updates));
    final journeyCount = updates.length;
    final summaryQuote = selectEmpoweringSummaryQuote(
      updates.take(20).map((update) => update.actionPlan.summary),
    );

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isPhoneViewport = constraints.maxWidth <= 480;
        final compact = constraints.maxHeight < 680;
        final veryCompact = constraints.maxHeight < 580;
        final designHeight = compact
            ? _profileCompactDesignHeight
            : _profileDesignHeight;
        final rawScale = math.min<double>(
          1.0,
          math.min(
            constraints.maxWidth / _profileDesignWidth,
            constraints.maxHeight / designHeight,
          ),
        );
        final safetyFactor = isPhoneViewport
            ? (compact ? 0.86 : 0.88)
            : (compact ? 0.98 : 0.95);
        final scale = math.max(0.58, math.min(1.0, rawScale * safetyFactor));

        return _ProfileContent(
          scale: scale,
          compact: compact,
          veryCompact: veryCompact,
          displayName: displayName,
          journeyCount: journeyCount,
          summaryQuote: summaryQuote,
          onOpenCallJourney: () => _openCallJourney(context),
          onOpenPastJourneys: () => _openPastJourneys(context),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: onOpenCallJourney == null && onOpenPastJourneys == null
          ? SafeArea(child: content)
          : content,
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

class _ProfileContent extends StatelessWidget {
  final double scale;
  final bool compact;
  final bool veryCompact;
  final String displayName;
  final int journeyCount;
  final SummaryQuote summaryQuote;
  final VoidCallback onOpenCallJourney;
  final VoidCallback onOpenPastJourneys;

  const _ProfileContent({
    required this.scale,
    required this.compact,
    required this.veryCompact,
    required this.displayName,
    required this.journeyCount,
    required this.summaryQuote,
    required this.onOpenCallJourney,
    required this.onOpenPastJourneys,
  });

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    double t(double value) => s(value * _profileTextScale);
    final isMobileWidth = MediaQuery.of(context).size.width <= 600;
    final horizontalPadding = isMobileWidth ? s(18) : 20.0;
    final topPadding = compact ? s(6) : 10.0;
    final bottomPadding = compact ? s(8) : s(18);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHero(
            scale: scale,
            compact: compact,
            veryCompact: veryCompact,
            displayName: displayName,
            journeyCount: journeyCount,
            onOpenCallJourney: onOpenCallJourney,
            onOpenPastJourneys: onOpenPastJourneys,
          ),
          if (!compact) ...[
            SizedBox(height: s(14)),
            _AffirmationCard(scale: scale, summaryQuote: summaryQuote),
            Expanded(
              child: LayoutBuilder(
                builder: (context, sectionConstraints) {
                  final footerLift = isMobileWidth ? s(24) : 0.0;
                  final welcomeTextHeight = t(22);
                  final houseHeight = math.max(
                    0.0,
                    sectionConstraints.maxHeight -
                        s(8) -
                        welcomeTextHeight -
                        footerLift,
                  );

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Center(
                          // Decorative brand art — hide from screen readers.
                          child: ExcludeSemantics(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.98,
                                child: HouseAnimationCinematic(
                                  height: houseHeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: s(8)),
                      SizedBox(
                        height: welcomeTextHeight,
                        child: Center(
                          child: _WelcomeHomeText(
                            scale: scale,
                            travelDistance:
                                houseHeight * houseCinematicBeginYOffset,
                          ),
                        ),
                      ),
                      if (footerLift > 0) SizedBox(height: footerLift),
                    ],
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: LayoutBuilder(
                builder: (context, sectionConstraints) {
                  final welcomeTextHeight = t(18);
                  final availableHeight = sectionConstraints.maxHeight;
                  final houseHeight = math.max(
                    0.0,
                    availableHeight - welcomeTextHeight - s(6),
                  );

                  if (availableHeight <= welcomeTextHeight + s(8)) {
                    return Center(
                      child: SizedBox(
                        height: welcomeTextHeight,
                        child: _WelcomeHomeText(
                          scale: scale,
                          travelDistance: 0,
                        ),
                      ),
                    );
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Center(
                          // Decorative brand art — hide from screen readers.
                          child: ExcludeSemantics(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.9,
                                child: HouseAnimationCinematic(
                                  height: houseHeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: s(6)),
                      SizedBox(
                        height: welcomeTextHeight,
                        child: Center(
                          child: _WelcomeHomeText(
                            scale: scale,
                            travelDistance:
                                houseHeight * houseCinematicBeginYOffset,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WelcomeHomeText extends StatefulWidget {
  final double scale;
  final double travelDistance;

  const _WelcomeHomeText({required this.scale, required this.travelDistance});

  @override
  State<_WelcomeHomeText> createState() => _WelcomeHomeTextState();
}

class _WelcomeHomeTextState extends State<_WelcomeHomeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: houseCinematicDuration,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    Future.delayed(houseCinematicDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * widget.scale;
    double t(double value) => s(value * _profileTextScale);

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final translateY = (1 - _curve.value) * widget.travelDistance;
        return Transform.translate(offset: Offset(0, translateY), child: child);
      },
      child: Text(
        'Welcome home, we\'re here with you.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: t(16),
          fontStyle: FontStyle.italic,
          color: AhmaTheme.mocha.withOpacity(0.62),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final double scale;
  final bool compact;
  final bool veryCompact;
  final String displayName;
  final int journeyCount;
  final VoidCallback onOpenCallJourney;
  final VoidCallback onOpenPastJourneys;

  const _ProfileHero({
    required this.scale,
    required this.compact,
    required this.veryCompact,
    required this.displayName,
    required this.journeyCount,
    required this.onOpenCallJourney,
    required this.onOpenPastJourneys,
  });

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    double t(double value) => s(value * _profileTextScale);

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
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: t(compact ? 34 : 42),
                      fontWeight: FontWeight.w700,
                      color: AhmaTheme.ahmaRed,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: s(4)),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: AhmaTheme.palePink.withOpacity(0.75),
                        size: s(22),
                      ),
                      SizedBox(width: s(8)),
                      Expanded(
                        child: Text(
                          'Your AI care resource companion',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: t(15),
                                color: AhmaTheme.mocha.withOpacity(0.64),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.1,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Top-right avatar opens the account page (view/edit profile,
            // log out).
            Material(
              color: Colors.white.withOpacity(0.28),
              shape: CircleBorder(
                side: BorderSide(color: Colors.white.withOpacity(0.5)),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
                child: SizedBox(
                  width: s(64),
                  height: s(64),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'A',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: t(24),
                            color: AhmaTheme.ahmaRed.withOpacity(0.72),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: s(compact ? 10 : 16)),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: t(compact ? 22 : 24),
              color: AhmaTheme.mocha.withOpacity(0.95),
              height: 1.1,
            ),
            children: [
              const TextSpan(text: 'Good morning, '),
              TextSpan(
                text: displayName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: t(compact ? 22 : 24),
                  color: AhmaTheme.mocha.withOpacity(0.95),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: s(compact ? 8 : 14)),
        Text(
          journeyCount == 1
              ? "You've been on 1 journey."
              : "You've been on $journeyCount journeys.",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: t(15),
            color: AhmaTheme.mocha.withOpacity(0.88),
          ),
        ),
        SizedBox(height: s(compact ? 10 : 16)),
        _CallJourneyCard(
          scale: scale,
          compact: compact,
          veryCompact: veryCompact,
          onTap: onOpenCallJourney,
        ),
        SizedBox(height: s(compact ? 8 : 10)),
        _PastJourneysCard(
          scale: scale,
          compact: compact,
          onTap: onOpenPastJourneys,
        ),
      ],
    );
  }
}

class _CallJourneyCard extends StatelessWidget {
  final double scale;
  final bool compact;
  final bool veryCompact;
  final VoidCallback onTap;

  const _CallJourneyCard({
    required this.scale,
    required this.compact,
    required this.veryCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    double t(double value) => s(value * _profileTextScale);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(38)),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            s(compact ? 18 : 22),
            s(compact ? 18 : 24),
            s(compact ? 16 : 20),
            s(compact ? 18 : 24),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s(38)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF6A7151), AhmaTheme.sageGreen],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: s(-10),
                bottom: s(-18),
                child: Opacity(
                  opacity: 0.12,
                  child: CustomPaint(
                    size: Size(s(140), s(140)),
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
                                fontSize: t(compact ? 24 : 30),
                                color: Colors.white,
                                height: 1.05,
                              ),
                          maxLines: veryCompact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: s(compact ? 8 : 10)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: s(250)),
                          child: Text(
                            'Talk to your AI companion for care guidance and support.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: t(compact ? 12 : 12.5),
                                  height: 1.35,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                            maxLines: veryCompact ? 2 : 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: s(compact ? 12 : 22)),
                  _PhoneOrb(scale: scale, compact: compact),
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
  final double scale;
  final bool compact;
  final VoidCallback onTap;

  const _PastJourneysCard({
    required this.scale,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    double t(double value) => s(value * _profileTextScale);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(28)),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: s(14),
            vertical: s(compact ? 10 : 14),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE3ECD7), Color(0xFFCCDDBD)],
            ),
            borderRadius: BorderRadius.circular(s(28)),
            border: Border.all(color: const Color(0xFFCCDDBD), width: s(1.4)),
          ),
          child: Row(
            children: [
              Container(
                width: s(52),
                height: s(52),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3F8EC),
                ),
                child: Image.asset(
                  'resources/Kopi.png',
                  width: s(26),
                  height: s(26),
                  excludeFromSemantics: true,
                ),
              ),
              SizedBox(width: s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your past journeys',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: t(compact ? 16 : 18),
                            color: const Color(0xFF45543B),
                          ),
                    ),
                    if (!compact) ...[
                      SizedBox(height: s(4)),
                      Text(
                        'View your previous calls and summaries.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: t(11),
                              color: const Color(0xFF5D6E52),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: s(12)),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF5F734C),
                size: s(34),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  final double scale;
  final SummaryQuote summaryQuote;

  const _AffirmationCard({required this.scale, required this.summaryQuote});

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s(16), s(14), s(14), s(12)),
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor.withOpacity(0.74),
        borderRadius: BorderRadius.circular(s(32)),
        border: Border.all(color: const Color(0xFFE8D7C5), width: s(1.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: s(52),
            height: s(52),
            child: Image.asset(
              'resources/full-cup.png',
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: _AffirmationCopy(scale: scale, summaryQuote: summaryQuote),
          ),
        ],
      ),
    );
  }
}

class _AffirmationCopy extends StatelessWidget {
  final double scale;
  final SummaryQuote summaryQuote;

  const _AffirmationCopy({required this.scale, required this.summaryQuote});

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    double t(double value) => s(value * _profileTextScale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.format_quote_rounded,
          color: const Color(0xFFFFC85A),
          size: s(30),
        ),
        SizedBox(height: s(4)),
        Text(
          summaryQuote.isFromSummary
              ? 'A NOTE FROM YOUR JOURNEYS'
              : 'TODAY\'S AFFIRMATION',
          style: AhmaTheme.labelTextStyle.copyWith(
            fontSize: t(10),
            color: AhmaTheme.sageGreen.withOpacity(0.9),
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: s(10)),
        Text(
          summaryQuote.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: t(17),
            color: Colors.black.withOpacity(0.92),
            height: 1.24,
          ),
        ),
      ],
    );
  }
}

class _PhoneOrb extends StatelessWidget {
  final double scale;
  final bool compact;

  const _PhoneOrb({required this.scale, required this.compact});

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final outerSize = compact ? 132.0 : 177.0;
    final middleSize = compact ? 108.0 : 144.0;
    final innerSize = compact ? 92.0 : 120.0;

    return SizedBox(
      width: s(outerSize),
      height: s(outerSize),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: s(outerSize),
            height: s(outerSize),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Container(
            width: s(middleSize),
            height: s(middleSize),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Container(
            width: s(innerSize),
            height: s(innerSize),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFAF5EE),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'press me!',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: s(compact ? 9.5 : 11.25),
                    color: AhmaTheme.sageGreen,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
                SizedBox(height: s(compact ? 4 : 6)),
                Image.asset(
                  'resources/Phone-on.png',
                  width: s(compact ? 40 : 51),
                  height: s(compact ? 40 : 51),
                ),
              ],
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
