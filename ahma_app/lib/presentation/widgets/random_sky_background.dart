import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Random watercolor sky background with different times of day
///
/// Features:
/// - Randomly selects from different time-of-day skies
/// - Static (no animation)
/// - Lens flare effects for bright light sources
/// - Pale brown watercolor path under house
class RandomSkyBackground extends StatefulWidget {
  final double pathHeight; // Height of path below house (e.g., 30% of screen)
  final Widget? child; // House or other content above path
  final bool useGradientFallback; // Use gradients instead of PNGs (default true until PNGs ready)

  const RandomSkyBackground({
    super.key,
    this.pathHeight = 0.3,
    this.child,
    this.useGradientFallback = true, // Default to gradients until you create PNGs
  });

  @override
  State<RandomSkyBackground> createState() => _RandomSkyBackgroundState();
}

class _RandomSkyBackgroundState extends State<RandomSkyBackground> {
  late SkyTimeOfDay selectedSky;
  late int randomSeed;

  @override
  void initState() {
    super.initState();
    // Randomly select a sky on first load
    randomSeed = math.Random().nextInt(1000);
    selectedSky = _selectRandomSky();
  }

  SkyTimeOfDay _selectRandomSky() {
    final random = math.Random(randomSeed);
    final skies = SkyTimeOfDay.values;
    return skies[random.nextInt(skies.length)];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Use gradient fallback if PNGs not ready
    if (widget.useGradientFallback) {
      return _buildGradientVersion(screenSize);
    }

    // Use PNG version (when images are ready)
    return Stack(
      children: [
        // Layer 1: Sky background (watercolor PNG)
        Positioned.fill(
          child: Image.asset(
            _getSkyImagePath(selectedSky),
            fit: BoxFit.cover,
          ),
        ),

        // Layer 2: Lens flare overlay (if sky has strong light)
        if (_hasLensFlare(selectedSky))
          Positioned.fill(
            child: _buildLensFlare(selectedSky, screenSize),
          ),

        // Layer 3: Pale brown watercolor path (bottom portion)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: screenSize.height * widget.pathHeight,
          child: Image.asset(
            'resources/path-watercolor-brown.png',
            fit: BoxFit.cover,
            // Blend with sky for natural transition
            colorBlendMode: BlendMode.multiply,
          ),
        ),

        // Layer 4: Child content (house, etc.)
        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _buildGradientVersion(Size screenSize) {
    final skyColors = _getSkyGradientColors(selectedSky);

    return Stack(
      children: [
        // Sky gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: skyColors,
            ),
          ),
        ),

        // Lens flare (if applicable)
        if (_hasLensFlare(selectedSky))
          Positioned.fill(
            child: _buildLensFlare(selectedSky, screenSize),
          ),

        // Path gradient (pale brown)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: screenSize.height * widget.pathHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFD2B48C).withOpacity(0.3), // Light tan
                  const Color(0xFFC8A882).withOpacity(0.6), // Pale brown
                  const Color(0xFFB8936B).withOpacity(0.9), // Brown
                ],
              ),
            ),
          ),
        ),

        // Child content (house, etc.)
        if (widget.child != null) widget.child!,
      ],
    );
  }

  List<Color> _getSkyGradientColors(SkyTimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case SkyTimeOfDay.dawn:
        return [
          const Color(0xFF1e3a5f), // Deep blue
          const Color(0xFF6a4c93), // Purple
          const Color(0xFFffa69e), // Soft pink
        ];
      case SkyTimeOfDay.sunrise:
        return [
          const Color(0xFFffd5a2), // Peach
          const Color(0xFFffb88c), // Orange
          const Color(0xFFff9a76), // Red-orange
        ];
      case SkyTimeOfDay.morning:
        return [
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFFADD8E6), // Light blue
          const Color(0xFFF0F8FF), // Alice blue
        ];
      case SkyTimeOfDay.midday:
        return [
          const Color(0xFF4A90E2), // Bright blue
          const Color(0xFF7CB3E9), // Light blue
          const Color(0xFFB8E6F5), // Pale blue
        ];
      case SkyTimeOfDay.afternoon:
        return [
          const Color(0xFF6BB6FF), // Soft blue
          const Color(0xFF9FCFFF), // Light blue
          const Color(0xFFFFE5B4), // Peach
        ];
      case SkyTimeOfDay.sunset:
        return [
          const Color(0xFFFF6B6B), // Coral red
          const Color(0xFFFF9E80), // Orange
          const Color(0xFFFFD4A3), // Peach
        ];
      case SkyTimeOfDay.dusk:
        return [
          const Color(0xFF4A2C71), // Deep purple
          const Color(0xFF7B4397), // Purple
          const Color(0xFFDC2430), // Pink-red
        ];
      case SkyTimeOfDay.night:
        return [
          const Color(0xFF0F2027), // Dark blue
          const Color(0xFF203A43), // Blue-gray
          const Color(0xFF2C5364), // Steel blue
        ];
    }
  }

  String _getSkyImagePath(SkyTimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case SkyTimeOfDay.dawn:
        return 'resources/sky-dawn.png';
      case SkyTimeOfDay.sunrise:
        return 'resources/sky-sunrise.png';
      case SkyTimeOfDay.morning:
        return 'resources/sky-morning.png';
      case SkyTimeOfDay.midday:
        return 'resources/sky-midday.png';
      case SkyTimeOfDay.afternoon:
        return 'resources/sky-afternoon.png';
      case SkyTimeOfDay.sunset:
        return 'resources/sky-sunset.png';
      case SkyTimeOfDay.dusk:
        return 'resources/sky-dusk.png';
      case SkyTimeOfDay.night:
        return 'resources/sky-night.png';
    }
  }

  bool _hasLensFlare(SkyTimeOfDay timeOfDay) {
    // Strong light sources: sunrise, midday, sunset
    return timeOfDay == SkyTimeOfDay.sunrise ||
        timeOfDay == SkyTimeOfDay.midday ||
        timeOfDay == SkyTimeOfDay.sunset;
  }

  Widget _buildLensFlare(SkyTimeOfDay timeOfDay, Size screenSize) {
    // Position lens flare based on time of day
    Alignment alignment;
    Color flareColor;

    switch (timeOfDay) {
      case SkyTimeOfDay.sunrise:
        alignment = const Alignment(-0.6, -0.4); // Left upper
        flareColor = const Color(0xFFFFA500).withOpacity(0.4); // Orange
        break;
      case SkyTimeOfDay.midday:
        alignment = const Alignment(0.0, -0.7); // Top center
        flareColor = const Color(0xFFFFFFAA).withOpacity(0.6); // Bright yellow
        break;
      case SkyTimeOfDay.sunset:
        alignment = const Alignment(0.6, -0.3); // Right upper
        flareColor = const Color(0xFFFF6347).withOpacity(0.5); // Red-orange
        break;
      default:
        alignment = Alignment.topCenter;
        flareColor = Colors.white.withOpacity(0.3);
    }

    return Align(
      alignment: alignment,
      child: CustomPaint(
        size: Size(screenSize.width, screenSize.height * 0.5),
        painter: LensFlarePainter(
          color: flareColor,
          intensity: 0.7,
        ),
      ),
    );
  }
}

/// Time of day options for sky backgrounds
enum SkyTimeOfDay {
  dawn,      // 5-6am: Deep blue with hints of purple
  sunrise,   // 6-7am: Orange, pink, yellow - LENS FLARE
  morning,   // 7-10am: Bright blue, white clouds
  midday,    // 10-2pm: Bright sky, strong sun - LENS FLARE
  afternoon, // 2-5pm: Softer blue, golden tones
  sunset,    // 5-7pm: Orange, red, purple - LENS FLARE
  dusk,      // 7-8pm: Deep purple, pink
  night,     // 8pm+: Dark blue, stars
}

/// Custom painter for lens flare effect
class LensFlarePainter extends CustomPainter {
  final Color color;
  final double intensity;

  LensFlarePainter({
    required this.color,
    this.intensity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Main light source (sun/bright spot)
    final mainFlare = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(intensity),
          color.withOpacity(intensity * 0.6),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.3),
        radius: size.width * 0.4,
      ));

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      size.width * 0.4,
      mainFlare,
    );

    // Secondary flare (smaller, offset)
    final secondaryFlare = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(intensity * 0.4),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.3, size.height * 0.5),
        radius: size.width * 0.2,
      ));

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.5),
      size.width * 0.2,
      secondaryFlare,
    );

    // Lens hexagon flares (small artifacts)
    _drawHexFlare(canvas, Offset(size.width * 0.7, size.height * 0.4), 20);
    _drawHexFlare(canvas, Offset(size.width * 0.2, size.height * 0.6), 15);
  }

  void _drawHexFlare(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = color.withOpacity(intensity * 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LensFlarePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.intensity != intensity;
  }
}

/// Alternative: Use PNG lens flare overlays instead of CustomPainter
class PngLensFlareOverlay extends StatelessWidget {
  final SkyTimeOfDay timeOfDay;

  const PngLensFlareOverlay({
    super.key,
    required this.timeOfDay,
  });

  @override
  Widget build(BuildContext context) {
    // Use pre-rendered lens flare PNGs for more realistic effects
    final flarePath = _getFlarePath(timeOfDay);
    if (flarePath == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Image.asset(
        flarePath,
        fit: BoxFit.cover,
        colorBlendMode: BlendMode.screen, // Screen blend for light effects
      ),
    );
  }

  String? _getFlarePath(SkyTimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case SkyTimeOfDay.sunrise:
        return 'resources/lens-flare-sunrise.png';
      case SkyTimeOfDay.midday:
        return 'resources/lens-flare-midday.png';
      case SkyTimeOfDay.sunset:
        return 'resources/lens-flare-sunset.png';
      default:
        return null; // No lens flare for other times
    }
  }
}

/// Fallback: Solid gradient skies if PNGs not ready
class GradientSkyBackground extends StatelessWidget {
  final SkyTimeOfDay timeOfDay;
  final double pathHeight;

  const GradientSkyBackground({
    super.key,
    required this.timeOfDay,
    this.pathHeight = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colors = _getSkyColors(timeOfDay);

    return Stack(
      children: [
        // Sky gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),

        // Path gradient (pale brown)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: screenSize.height * pathHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFD2B48C).withOpacity(0.3), // Light tan
                  const Color(0xFFC8A882).withOpacity(0.6), // Pale brown
                  const Color(0xFFB8936B).withOpacity(0.8), // Brown
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getSkyColors(SkyTimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case SkyTimeOfDay.dawn:
        return [
          const Color(0xFF1e3a5f), // Deep blue
          const Color(0xFF6a4c93), // Purple
          const Color(0xFFffa69e), // Soft pink
        ];
      case SkyTimeOfDay.sunrise:
        return [
          const Color(0xFFffd5a2), // Peach
          const Color(0xFFffb88c), // Orange
          const Color(0xFFff9a76), // Red-orange
        ];
      case SkyTimeOfDay.morning:
        return [
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFFADD8E6), // Light blue
          const Color(0xFFF0F8FF), // Alice blue
        ];
      case SkyTimeOfDay.midday:
        return [
          const Color(0xFF4A90E2), // Bright blue
          const Color(0xFF7CB3E9), // Light blue
          const Color(0xFFB8E6F5), // Pale blue
        ];
      case SkyTimeOfDay.afternoon:
        return [
          const Color(0xFF6BB6FF), // Soft blue
          const Color(0xFF9FCFFF), // Light blue
          const Color(0xFFFFE5B4), // Peach
        ];
      case SkyTimeOfDay.sunset:
        return [
          const Color(0xFFFF6B6B), // Coral red
          const Color(0xFFFF9E80), // Orange
          const Color(0xFFFFD4A3), // Peach
        ];
      case SkyTimeOfDay.dusk:
        return [
          const Color(0xFF4A2C71), // Deep purple
          const Color(0xFF7B4397), // Purple
          const Color(0xFFDC2430), // Pink-red
        ];
      case SkyTimeOfDay.night:
        return [
          const Color(0xFF0F2027), // Dark blue
          const Color(0xFF203A43), // Blue-gray
          const Color(0xFF2C5364), // Steel blue
        ];
    }
  }
}
