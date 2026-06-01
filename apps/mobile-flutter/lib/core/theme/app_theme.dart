import 'package:flutter/material.dart';

class AppColors {
  // Background Colors
  static const Color bgDefault = Color(0xFFFFFFFF);
  static const Color bgWarm = Color(0xFFFFFDF9);
  static const Color bgPaper = Color(0xFFFFFAF3);
  static const Color bgGrid = Color(0xFFFFF7EF);
  static const Color bgPurpleSoft = Color(0xFFF6F1FF);

  // Primary Colors
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPurpleDark = Color(0xFF6D3FE8);
  static const Color primaryPurpleSoft = Color(0xFFEDE4FF);
  static const Color primaryPink = Color(0xFFFF8FA3);
  static const Color primaryPinkSoft = Color(0xFFFFE3E8);

  // Text Colors
  static const Color textMain = Color(0xFF3A2A23);
  static const Color textSub = Color(0xFF7A6258);
  static const Color textMuted = Color(0xFFA9948A);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Line / Border Colors
  static const Color lineSoft = Color(0xFFEAD8CC);
  static const Color lineBrown = Color(0xFFC9A995);
  static const Color linePink = Color(0xFFFF9CAD);
  static const Color linePurple = Color(0xFFBDA4FF);

  // Accent Colors
  static const Color accentBrown = Color(0xFFB98562);
  static const Color accentOrange = Color(0xFFFFB35C);
  static const Color accentGreen = Color(0xFFA8C58B);
  static const Color accentBlue = Color(0xFF8CC6E8);
  static const Color accentRed = Color(0xFFFF6B7A);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPurple,
        primary: AppColors.primaryPurple,
        secondary: AppColors.primaryPink,
        surface: AppColors.bgDefault,
        error: AppColors.accentRed,
      ),
      scaffoldBackgroundColor: AppColors.bgDefault,
      textTheme: const TextTheme(
        // DungGeunMo / Galmuri 느낌의 Pixel Title 대용으로 폰트 스타일 두껍고 딱딱하게 지정
        displayLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w900,
          color: AppColors.textMain,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
        titleMedium: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        bodyLarge: TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textMain,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textSub,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgPaper,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: AppColors.lineSoft, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgDefault,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.lineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.lineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}
