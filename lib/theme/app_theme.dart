import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان زهرية هادئة — مناسبة لمشروع بناتي.
abstract final class AppColors {
  static const Color bgTop = Color(0xFFFFF5F9);
  static const Color bgBottom = Color(0xFFFFEEF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFFF0F6);
  static const Color primary = Color(0xFFEC407A);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color accentSoft = Color(0xFFF8BBD0);
  static const Color textPrimary = Color(0xFF3D2C35);
  static const Color textSecondary = Color(0xFF7A6570);
  static const Color ok = Color(0xFF81C784);
  static const Color warn = Color(0xFFFFB74D);
  static const Color alert = Color(0xFFE57373);
  static const Color outline = Color(0xFFF5C2D6);
  static const Color shadow = Color(0x33EC407A);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accentSoft,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.alert,
      outline: AppColors.outline,
    ),
    scaffoldBackgroundColor: AppColors.bgBottom,
  );

  final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return base.copyWith(
    visualDensity: VisualDensity.standard,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: GoogleFonts.tajawal(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      shadowColor: AppColors.shadow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
