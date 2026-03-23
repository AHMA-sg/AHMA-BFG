import 'package:flutter/material.dart';

/// Blends multiple background PNGs together with various blend modes
///
/// Features:
/// - Layer multiple images with different blend modes
/// - Animated opacity for smooth transitions
/// - Support for custom blend modes (multiply, screen, overlay, etc.)
///
/// Usage:
/// ```dart
/// BlendedBackground(
///   layers: [
///     BackgroundLayer(
///       imagePath: 'resources/bg-layer-1.png',
///       opacity: 1.0,
///       blendMode: BlendMode.srcOver,
///     ),
///     BackgroundLayer(
///       imagePath: 'resources/bg-layer-2.png',
///       opacity: 0.6,
///       blendMode: BlendMode.multiply,
///     ),
///   ],
/// )
/// ```
class BlendedBackground extends StatelessWidget {
  final List<BackgroundLayer> layers;
  final Color? backgroundColor;
  final BoxFit fit;

  const BlendedBackground({
    super.key,
    required this.layers,
    this.backgroundColor,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: layers.map((layer) => _buildLayer(layer)).toList(),
      ),
    );
  }

  Widget _buildLayer(BackgroundLayer layer) {
    Widget image = Image.asset(
      layer.imagePath,
      fit: fit,
      colorBlendMode: layer.blendMode,
    );

    // Apply opacity if needed
    if (layer.opacity < 1.0) {
      image = Opacity(
        opacity: layer.opacity,
        child: image,
      );
    }

    // Apply color filter if provided
    if (layer.colorFilter != null) {
      image = ColorFiltered(
        colorFilter: layer.colorFilter!,
        child: image,
      );
    }

    return image;
  }
}

/// Configuration for a single background layer
class BackgroundLayer {
  final String imagePath;
  final double opacity;
  final BlendMode blendMode;
  final ColorFilter? colorFilter;

  const BackgroundLayer({
    required this.imagePath,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.colorFilter,
  });
}

/// Animated version with smooth transitions between layers
class AnimatedBlendedBackground extends StatefulWidget {
  final List<BackgroundLayer> layers;
  final Color? backgroundColor;
  final BoxFit fit;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedBlendedBackground({
    super.key,
    required this.layers,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.animationDuration = const Duration(seconds: 3),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedBlendedBackground> createState() =>
      _AnimatedBlendedBackgroundState();
}

class _AnimatedBlendedBackgroundState extends State<AnimatedBlendedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: widget.layers
            .asMap()
            .entries
            .map((entry) => _buildAnimatedLayer(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  Widget _buildAnimatedLayer(int index, BackgroundLayer layer) {
    // Stagger animations for each layer
    final begin = (index * 0.2).clamp(0.0, 1.0);
    final end = (begin + 0.5).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: widget.animationCurve),
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: layer.opacity).animate(animation),
      child: Image.asset(
        layer.imagePath,
        fit: widget.fit,
        colorBlendMode: layer.blendMode,
      ),
    );
  }
}

/// Common blend mode presets for easy use
class BlendPresets {
  static const BackgroundLayer multiply = BackgroundLayer(
    imagePath: '',
    blendMode: BlendMode.multiply,
  );

  static const BackgroundLayer screen = BackgroundLayer(
    imagePath: '',
    blendMode: BlendMode.screen,
  );

  static const BackgroundLayer overlay = BackgroundLayer(
    imagePath: '',
    blendMode: BlendMode.overlay,
  );

  static const BackgroundLayer softLight = BackgroundLayer(
    imagePath: '',
    blendMode: BlendMode.softLight,
  );

  static const BackgroundLayer hardLight = BackgroundLayer(
    imagePath: '',
    blendMode: BlendMode.hardLight,
  );

  static const BackgroundLayer colorDodge = BackgroundLayer(
    imagePath: '',
    blendMode: BlendMode.colorDodge,
  );

  static const BackgroundLayer colorBurn = BackgroundLayer(
    imagePath: '',
    blendMode: BlendMode.colorBurn,
  );
}

/// Helper to create tinted layers
class TintedLayer extends BackgroundLayer {
  TintedLayer({
    required String imagePath,
    required Color tintColor,
    double opacity = 1.0,
    BlendMode blendMode = BlendMode.srcOver,
  }) : super(
          imagePath: imagePath,
          opacity: opacity,
          blendMode: blendMode,
          colorFilter: ColorFilter.mode(tintColor, BlendMode.modulate),
        );
}

/// Example usage with watercolor effect:
///
/// ```dart
/// BlendedBackground(
///   backgroundColor: const Color(0xFFFFF4E6), // Base cream color
///   layers: [
///     // Base watercolor texture
///     BackgroundLayer(
///       imagePath: 'resources/watercolor-base.png',
///       opacity: 1.0,
///       blendMode: BlendMode.srcOver,
///     ),
///     // Teal overlay with multiply blend
///     BackgroundLayer(
///       imagePath: 'resources/watercolor-overlay.png',
///       opacity: 0.4,
///       blendMode: BlendMode.multiply,
///     ),
///     // Soft light accent
///     BackgroundLayer(
///       imagePath: 'resources/watercolor-accent.png',
///       opacity: 0.3,
///       blendMode: BlendMode.softLight,
///     ),
///   ],
/// )
/// ```
///
/// Common blend modes for watercolor:
/// - BlendMode.multiply: Darkens colors (like watercolor layers)
/// - BlendMode.screen: Lightens colors (soft glow)
/// - BlendMode.overlay: Combines multiply and screen
/// - BlendMode.softLight: Subtle color enhancement
/// - BlendMode.colorBurn: Increases saturation
