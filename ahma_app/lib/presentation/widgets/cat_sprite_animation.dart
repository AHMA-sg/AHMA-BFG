import 'package:flutter/material.dart';

/// Cat sprite animation using sprite sheet
///
/// REQUIREMENTS:
/// - Cat sprite sheet PNG with walk cycle frames
/// - Expected layout: 8 frames in 2 rows of 4
/// - Transparent background
///
/// TODO: Implement once sprite sheet is provided
class CatSpriteAnimation extends StatefulWidget {
  final double position; // 0.0 to 1.0 across screen width
  final bool isWalking;
  final bool facingRight;

  const CatSpriteAnimation({
    super.key,
    required this.position,
    this.isWalking = true,
    this.facingRight = true,
  });

  @override
  State<CatSpriteAnimation> createState() => _CatSpriteAnimationState();
}

class _CatSpriteAnimationState extends State<CatSpriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _frameController;
  int _currentFrame = 0;

  // Sprite sheet configuration
  static const int _totalFrames = 8;
  static const int _framesPerRow = 4;
  static const double _frameRate = 10; // fps

  @override
  void initState() {
    super.initState();

    _frameController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / _frameRate).round()),
    )..addListener(() {
        if (_frameController.isCompleted) {
          setState(() {
            _currentFrame = (_currentFrame + 1) % _totalFrames;
          });
          if (widget.isWalking) {
            _frameController.forward(from: 0);
          }
        }
      });

    if (widget.isWalking) {
      _frameController.forward();
    }
  }

  @override
  void didUpdateWidget(CatSpriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isWalking && !_frameController.isAnimating) {
      _frameController.forward();
    } else if (!widget.isWalking) {
      _frameController.stop();
    }
  }

  @override
  void dispose() {
    _frameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final xPosition = screenWidth * widget.position;

    return Positioned(
      left: xPosition - 32, // Center the 64px sprite
      bottom: 100,
      child: Transform.flip(
        flipX: !widget.facingRight,
        child: _buildCatSprite(),
      ),
    );
  }

  Widget _buildCatSprite() {
    // TODO: Replace with actual sprite sheet rendering
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.pets,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  /*
  // Example implementation with actual sprite sheet:

  Widget _buildCatSprite() {
    // Calculate sprite position in sheet
    final row = _currentFrame ~/ _framesPerRow;
    final col = _currentFrame % _framesPerRow;

    final spriteWidth = 128.0; // Width of each frame in sprite sheet
    final spriteHeight = 128.0; // Height of each frame

    return ClipRect(
      child: Align(
        alignment: Alignment(
          -1.0 + (2 * col / (_framesPerRow - 1)),
          -1.0 + (2 * row / ((_totalFrames ~/ _framesPerRow) - 1)),
        ),
        widthFactor: 1 / _framesPerRow,
        heightFactor: 1 / (_totalFrames ~/ _framesPerRow),
        child: Image.asset(
          'resources/cat-sprite-sheet.png',
          width: spriteWidth * _framesPerRow,
          height: spriteHeight * (_totalFrames ~/ _framesPerRow),
          fit: BoxFit.none,
        ),
      ),
    );
  }
  */
}
