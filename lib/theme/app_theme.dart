import 'package:flutter/material.dart';

/// Central place for colors, text styles and spacing so every
/// reusable widget looks consistent across the app.
class AppColors {
  AppColors._();

  // Primary brand: Deep Ocean Blue - great for trust + outdoor readability
  static const primary = Color(0xFF1E40AF); // Blue 800
  static const primaryDark = Color(0xFF1E3A8A); // Blue 900
  static const primaryLight = Color(0xFF3B82F6); // Blue 500
  
  // Accent: Warm Orange for CTAs - high visibility, action-oriented
  static const accent = Color(0xFFEA580C); // Orange 600
  static const accentDark = Color(0xFFC2410C); // Orange 700
  static const accentLight = Color(0xFFFB923C); // Orange 400

  // Neutrals - warmer slate for friendlier feel
  static const background = Color(0xFFFAFAF9); // Stone 50
  static const surface = Colors.white;
  static const surfaceElevated = Color(0xFFF5F5F4); // Stone 100

  static const textPrimary = Color(0xFF1C1917); // Stone 900
  static const textSecondary = Color(0xFF78716C); // Stone 500
  static const textTertiary = Color(0xFFA8A29E); // Stone 400
  static const divider = Color(0xFFE7E5E4); // Stone 200

  // Semantic colors
  static const success = Color(0xFF16A34A); // Green 600
  static const warning = Color(0xFFEA580C); // Orange 600
  static const error = Color(0xFFDC2626); // Red 600
  static const info = Color(0xFF0EA5E9); // Sky 500

  // Site type colors - distinct + accessible in sunlight
  static const houseBg = Color(0xFFFEF3C7); // Amber 100
  static const houseFg = Color(0xFFB45309); // Amber 700

  static const businessBg = Color(0xFFDBEAFE); // Blue 100
  static const businessFg = Color(0xFF1E40AF); // Blue 800

  static const churchBg = Color(0xFFFCE7F3); // Pink 100
  static const churchFg = Color(0xFFBE185D); // Pink 700

  static const schoolBg = Color(0xFFD1FAE5); // Emerald 100
  static const schoolFg = Color(0xFF047857); // Emerald 700

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)], // Blue 800 to Blue 600
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFEA580C), Color(0xFFF97316)], // Orange 600 to Orange 500
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF0EA5E9)], // Blue-Sky
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent, // Changed to accent for main CTAs
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}