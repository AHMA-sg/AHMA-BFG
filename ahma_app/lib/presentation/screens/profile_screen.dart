import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/ahma_theme.dart';

class Affirmation {
  final String text;
  final String from;
  final Color? dotColor;

  const Affirmation({
    required this.text,
    required this.from,
    this.dotColor,
  });
}

/// Profile Screen with Affirmations
/// 
/// Features:
/// - User profile with name and streak
/// - Today's affirmation card
/// - This week's mood pills
/// - Collectibles display
/// - Past brews with affirmations
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final List<String> _weekMoods = ['tired', 'hopeful', 'calm'];
  final List<String> _collectibles = ['☕', '✦', '?'];
  final List<Affirmation> _pastAffirmations = [
    const Affirmation(
      text: 'You are allowed to take up space.',
      from: '',
      dotColor: AhmaTheme.palePink,
    ),
    const Affirmation(
      text: 'It\'s okay that today was hard.',
      from: '',
      dotColor: AhmaTheme.sageGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show watercolor background
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with logo and profile icon
            _buildTopBar(),
            
            // Main content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Text(
            'AHMA',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AhmaTheme.ahmaRed,
              letterSpacing: 0.8,
            ),
          ),
          
          // Profile icon (half turtle)
          _buildProfileIcon(),
        ],
      ),
    );
  }

  Widget _buildProfileIcon() {
    return SizedBox(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: _ProfileIconPainter(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // User info section
          _buildUserInfo(),
          
          const SizedBox(height: 8),
          
          // Today's affirmation
          _buildTodaysAffirmation(),
          
          const SizedBox(height: 7),
          
          // This week and collectibles grid
          _buildWeekGrid(),
          
          const SizedBox(height: 7),
          
          // Past brews section
          _buildPastBrews(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hui Lin',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 17,
                color: AhmaTheme.mocha.withOpacity(0.82),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '12 brews collected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 8,
                color: AhmaTheme.sageGreen,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w200,
              ),
            ),
          ],
        ),
        
        // Streak counter
        Column(
          children: [
            Text(
              '7',
              style: AhmaTheme.labelTextStyle.copyWith(
                fontSize: 14,
                color: AhmaTheme.ahmaRed,
              ),
            ),
            Text(
              'streak',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 7,
                color: AhmaTheme.mocha.withOpacity(0.38),
                letterSpacing: 0.7,
                fontWeight: FontWeight.w200,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysAffirmation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: AhmaTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'today\'s affirmation',
            style: AhmaTheme.labelTextStyle.copyWith(
              fontSize: 7,
              color: AhmaTheme.sageGreen.withOpacity(0.65),
              letterSpacing: 0.8,
            ),
          ),
          
          const SizedBox(height: 7),
          
          // Affirmation text
          Text(
            'You don\'t have to have it all figured out. Resting is also moving forward.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 12,
              color: AhmaTheme.mocha.withOpacity(0.82),
              height: 1.55,
            ),
          ),
          
          const SizedBox(height: 7),
          
          // From
          Text(
            '— from your 3rd brew',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 8,
              color: AhmaTheme.sageGreen,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekGrid() {
    return Row(
      children: [
        // This week's moods
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: AhmaTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  'this week',
                  style: AhmaTheme.labelTextStyle.copyWith(
                    fontSize: 7,
                    color: AhmaTheme.sageGreen.withOpacity(0.65),
                    letterSpacing: 0.8,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Mood pills
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _weekMoods.map((mood) => _buildMoodPill(mood)).toList(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 7),
        
        // Collectibles
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: AhmaTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  'collectibles',
                  style: AhmaTheme.labelTextStyle.copyWith(
                    fontSize: 7,
                    color: AhmaTheme.sageGreen.withOpacity(0.65),
                    letterSpacing: 0.8,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Collectible items
                Row(
                  children: _collectibles.map((collectible) => 
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: _buildCollectibleItem(collectible),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodPill(String mood) {
    Color bgColor = AhmaTheme.cardColor;
    
    if (mood == 'calm') {
      bgColor = AhmaTheme.palePink.withOpacity(0.18);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AhmaTheme.mocha.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Text(
        mood,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 9,
          color: AhmaTheme.mocha.withOpacity(0.8),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCollectibleItem(String collectible) {
    Color bgColor = AhmaTheme.sageGreen.withOpacity(0.2);
    Border? border;
    
    if (collectible == '☕') {
      bgColor = AhmaTheme.palePink.withOpacity(0.3);
    } else if (collectible == '?') {
      bgColor = AhmaTheme.mid.withOpacity(0.3);
      border = Border.all(
        color: AhmaTheme.mocha.withOpacity(0.15),
        width: 1,
        style: BorderStyle.solid,
      );
    }
    
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          collectible,
          style: AhmaTheme.labelTextStyle.copyWith(
            fontSize: 8,
            color: AhmaTheme.mocha.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildPastBrews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'past brews',
          style: AhmaTheme.labelTextStyle.copyWith(
            fontSize: 7,
            color: AhmaTheme.mocha.withOpacity(0.32),
            letterSpacing: 0.8,
          ),
        ),
        
        const SizedBox(height: 5),
        
        // Past affirmation cards
        ..._pastAffirmations.map((affirmation) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _buildPastAffirmationCard(affirmation),
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildPastAffirmationCard(Affirmation affirmation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AhmaTheme.cardColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AhmaTheme.mocha.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: affirmation.dotColor ?? AhmaTheme.sageGreen,
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 7),
          
          // Affirmation text
          Expanded(
            child: Text(
              affirmation.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                color: AhmaTheme.mocha,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background circle
    final bgPaint = Paint()
      ..color = AhmaTheme.cardColor
      ..style = PaintingStyle.fill;
    
    final bgBorderPaint = Paint()
      ..color = AhmaTheme.mocha.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.drawCircle(center, size.width * 0.46, bgPaint);
    canvas.drawCircle(center, size.width * 0.46, bgBorderPaint);

    // Body (ellipse - half turtle shape)
    final bodyPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.65),
      width: size.width * 0.62,
      height: size.height * 0.42,
    );
    canvas.drawOval(bodyRect, bodyPaint);

    // Head (ellipse)
    final headPaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.42),
      width: size.width * 0.42,
      height: size.height * 0.35,
    );
    canvas.drawOval(headRect, headPaint);

    // Eyes (small ellipses for half turtle effect)
    final eyePaint = Paint()
      ..color = AhmaTheme.sageGreen.withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final leftEyeRect = Rect.fromCenter(
      center: Offset(size.width * 0.33, size.height * 0.33),
      width: size.width * 0.14,
      height: size.width * 0.14,
    );
    canvas.drawOval(leftEyeRect, eyePaint);

    final rightEyeRect = Rect.fromCenter(
      center: Offset(size.width * 0.52, size.height * 0.33),
      width: size.width * 0.14,
      height: size.width * 0.14,
    );
    canvas.drawOval(rightEyeRect, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
