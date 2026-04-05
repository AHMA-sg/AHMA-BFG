import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/ahma_theme.dart';

/// Watercolor textured background with grain effect
/// 
/// Creates a layered watercolor effect with subtle grain texture
/// matching the design language's hand-drawn aesthetic
class WatercolorBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const WatercolorBackground({
    super.key,
    required this.child,
    this.opacity = 0.55, // Reverted to match HTML
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          color: AhmaTheme.background,
        ),
        
        // Watercolor blobs
        Positioned.fill(
          child: CustomPaint(
            painter: _WatercolorPainter(),
          ),
        ),
        
        // Grain texture overlay
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: _GrainPainter(),
            ),
          ),
        ),
        
        // Content
        child,
      ],
    );
  }
}

class _WatercolorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Much more visible blob data to match ideal
    final blobs = [
      _WatercolorBlob(
        center: Offset(size.width * 0.2, size.height * 0.15),
        radiusX: size.width * 0.25,
        radiusY: size.height * 0.15,
        color: const Color(0xFFBA9EA7).withOpacity(0.07), // Much more visible
        rotation: -15,
      ),
      _WatercolorBlob(
        center: Offset(size.width * 0.8, size.height * 0.3),
        radiusX: size.width * 0.2,
        radiusY: size.height * 0.12,
        color: const Color(0xFF646556).withOpacity(0.07), // Much more visible
        rotation: 20,
      ),
      _WatercolorBlob(
        center: Offset(size.width * 0.35, size.height * 0.72),
        radiusX: size.width * 0.25,
        radiusY: size.height * 0.12,
        color: const Color(0xFFC1B1A1).withOpacity(0.08), // Much more visible
        rotation: 5,
      ),
      _WatercolorBlob(
        center: Offset(size.width * 0.7, size.height * 0.85),
        radiusX: size.width * 0.18,
        radiusY: size.height * 0.08,
        color: const Color(0xFFBA9EA7).withOpacity(0.07), // Much more visible
        rotation: -10,
      ),
      _WatercolorBlob(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radiusX: size.width * 0.3,
        radiusY: size.height * 0.18,
        color: const Color(0xFFF2EBE1).withOpacity(0.2), // Much more visible
        rotation: 0,
      ),
    ];

    for (final blob in blobs) {
      blob.paint(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WatercolorBlob {
  final Offset center;
  final double radiusX;
  final double radiusY;
  final Color color;
  final double rotation;

  _WatercolorBlob({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.color,
    required this.rotation,
  });

  void paint(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 3.14159 / 180);
    
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    
    canvas.drawOval(rect, paint);
    canvas.restore();
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Better pseudo-random distribution for natural grain
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Much higher grain density for visibility
    final grainDensity = (size.width * size.height * 0.12).floor(); // Much higher density
    
    for (int i = 0; i < grainDensity; i++) {
      // More natural random distribution using multiple factors
      final x = (math.sin(i * 12.989) * 43758.5453) % 1.0 * size.width;
      final y = (math.cos(i * 78.233) * 23421.631) % 1.0 * size.height;
      
      // More natural color variation
      final v = (math.sin(i * 45.123) * math.cos(i * 67.890) * 127.5 + 127.5) % 255;
      final alpha = (math.sin(i * 23.456) * 12.345 + 4.0) % 3.0 + 2.0; // Range 4-9
      
      // Natural RGB variation
      final r = v;
      final g = v;
      final b = (math.sin(i * 34.567) > 0.5) ? v * 0.9 : v;
      
      paint.color = Color.fromARGB(
        (alpha / 255.0 * 255).round(),
        r.round(),
        g.round(),
        b.round(),
      );
      
      // Much larger grain points for visibility
      canvas.drawCircle(
        Offset(x, y),
        1.5, // Much larger grain points
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Static pattern
}

/// Simplified watercard background for cards
class WatercolorCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const WatercolorCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AhmaTheme.mocha.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Watercolor gradient background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                painter: _CardWatercolorPainter(),
              ),
            ),
          ),
          
          // Content
          child,
        ],
      ),
    );
  }
}

class _CardWatercolorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create watercolor gradient effect
    final gradient = RadialGradient(
      center: const Alignment(0.4, -0.3),
      radius: 1.2,
      colors: [
        AhmaTheme.palePink.withOpacity(0.13),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect);
    
    canvas.drawRect(rect, paint);
    
    // Second gradient for depth
    final gradient2 = RadialGradient(
      center: const Alignment(0.7, 0.7),
      radius: 1.0,
      colors: [
        AhmaTheme.sageGreen.withOpacity(0.07),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5],
    );
    
    final paint2 = Paint()
      ..shader = gradient2.createShader(rect);
    
    canvas.drawRect(rect, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
