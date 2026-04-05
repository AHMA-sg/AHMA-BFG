import 'package:flutter/material.dart';

/// AHMA Design System Theme
/// 
/// Based on the design language:
/// - Aesthetic: clean, hand-drawn, watercolor, kopitiam, japanese, pastel
/// - Colors: sage green, pale pink, mocha, mid tones, AHMA red
/// - Fonts: Caprasimo (loud), Fraunces (serif), League Spartan (calm), Share Tech Mono (mono)
class AhmaTheme {
  // Color palette from design language
  static const Color sageGreen = Color(0xFF646556);
  static const Color palePink = Color(0xFFBA9EA7);
  static const Color mocha = Color(0xFF2E2620);
  static const Color mid = Color(0xFFC1B1A1);
  static const Color ahmaRed = Color(0xFF800000);
  
  // Background colors
  static const Color background = Color(0xFFF2EBE1);
  static const Color backgroundInner = Color(0xFFF7F2EC);
  static const Color cardColor = Color(0xFFF0E9DF);
  static const Color cardColor2 = Color(0xFFEDE4D8);

  // Text styles
  static const String caprasimoFont = 'Caprasimo';
  static const String frauncesFont = 'Fraunces';
  static const String leagueSpartanFont = 'LeagueSpartan';
  static const String shareTechMonoFont = 'ShareTechMono';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sageGreen,
        brightness: Brightness.light,
        primary: sageGreen,
        secondary: palePink,
        surface: cardColor,
        background: background,
        error: ahmaRed,
      ),
      
      // Text theme
      textTheme: const TextTheme(
        // Loud font - Caprasimo
        displayLarge: TextStyle(
          fontFamily: caprasimoFont,
          fontSize: 32,
          color: mocha,
          letterSpacing: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: caprasimoFont,
          fontSize: 24,
          color: mocha,
          letterSpacing: 0.8,
        ),
        displaySmall: TextStyle(
          fontFamily: caprasimoFont,
          fontSize: 20,
          color: mocha,
          letterSpacing: 0.6,
        ),
        
        // Serif font - Fraunces
        headlineLarge: TextStyle(
          fontFamily: frauncesFont,
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: mocha,
          letterSpacing: 0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: frauncesFont,
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: mocha,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontFamily: frauncesFont,
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: mocha,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          fontFamily: frauncesFont,
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: mocha,
          height: 1.45,
        ),
        
        // Calm font - League Spartan
        titleLarge: TextStyle(
          fontFamily: leagueSpartanFont,
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: mocha,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontFamily: leagueSpartanFont,
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: mocha,
          letterSpacing: 0.3,
        ),
        bodySmall: TextStyle(
          fontFamily: leagueSpartanFont,
          fontSize: 10,
          fontWeight: FontWeight.w200,
          color: sageGreen,
          letterSpacing: 0.7,
        ),
        
        // Mono font - Share Tech Mono
        labelSmall: TextStyle(
          fontFamily: shareTechMonoFont,
          fontSize: 8,
          color: mocha,
          letterSpacing: 0.8,
        ),
        labelMedium: TextStyle(
          fontFamily: shareTechMonoFont,
          fontSize: 10,
          color: mocha,
          letterSpacing: 0.6,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: mocha.withOpacity(0.07),
            width: 1,
          ),
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sageGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: mocha.withOpacity(0.07),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: mocha.withOpacity(0.07),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: sageGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      
      // Scaffold theme
      scaffoldBackgroundColor: background,
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: mocha,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: caprasimoFont,
          fontSize: 21,
          color: ahmaRed,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Custom component themes
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: mocha.withOpacity(0.07),
      width: 1,
    ),
  );

  static BoxDecoration get pillDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: mocha.withOpacity(0.12),
      width: 1,
    ),
  );

  static TextStyle get labelTextStyle => const TextStyle(
    fontFamily: shareTechMonoFont,
    fontSize: 8,
    color: mocha,
    letterSpacing: 0.8,
  );

  static TextStyle get navLabelStyle => const TextStyle(
    fontFamily: shareTechMonoFont,
    fontSize: 8,
    color: mocha,
    letterSpacing: 0.5,
  );

  static TextStyle get cardLabelStyle => const TextStyle(
    fontFamily: frauncesFont,
    fontSize: 11,
    color: sageGreen,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.2,
  );
}
