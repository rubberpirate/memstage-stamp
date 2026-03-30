import 'package:flutter/material.dart';

class AppTheme {
  static const Color onSurface = Color(0xFF2d3435);
  static const Color background = Color(0xFFf9f9f9);
  static const Color surfaceContainerHighest = Color(0xFFdde4e5);
  static const Color primary = Color(0xFF4e6266);
  static const Color onPrimary = Color(0xFFe8fbff);
  static const Color tertiary = Color(0xFF496272);
  static const Color surfaceContainerLow = Color(0xFFf2f4f4);
  static const Color surfaceContainer = Color(0xFFebeeef);
  static const Color onSurfaceVariant = Color(0xFF5a6061);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        surface: background,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainerHighest: surfaceContainerHighest,
      ),
      fontFamily: 'Inter', // Default to body font
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.w800, color: onSurface),
        headlineMedium: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.w700, color: onSurface),
        headlineSmall: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.w600, color: onSurface),
        titleLarge: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.w800, color: primary),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: onSurface),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: onSurface),
        labelSmall: TextStyle(fontFamily: 'Inter', color: onSurfaceVariant, letterSpacing: 1.5),
      ),
    );
  }
}
