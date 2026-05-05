import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF26DE81);
  static const Color favorite = Color(0xFF4ECDC4);

  // Neutral colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);

  // Text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle statsNumber = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: primary,
    letterSpacing: -1.0,
  );

  static const TextStyle statsLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: favorite,
        error: danger,
        surface: cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
