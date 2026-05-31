import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple,
      brightness: Brightness.light,
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryPink,
      surface: AppColors.bgDefault,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgDefault,
      fontFamily: 'Apple SD Gothic Neo',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.bgDefault,
        foregroundColor: AppColors.textMain,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.bgPaper,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          side: BorderSide(color: AppColors.lineSoft),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.textMain,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: AppColors.textMain,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        titleMedium: TextStyle(
          color: AppColors.textMain,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          color: AppColors.textMain,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textMain,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSub,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: AppColors.textInverse,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSub,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgDefault,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.linePink, width: 1.4),
        ),
      ),
    );
  }
}
