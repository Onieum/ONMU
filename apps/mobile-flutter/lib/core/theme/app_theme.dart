import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryPink,
      brightness: Brightness.light,
      primary: AppColors.primaryPink,
      secondary: AppColors.primaryPurple,
      surface: AppColors.bgDefault,
      surfaceContainerHighest: AppColors.bgPaper,
      outline: AppColors.lineSoft,
      onPrimary: AppColors.textInverse,
      onSurface: AppColors.textMain,
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
        backgroundColor: AppColors.bgWarm,
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
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.bgDefault,
        indicatorColor: AppColors.primaryPinkSoft,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: AppColors.textSub,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: AppColors.textSub),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primaryPink,
          foregroundColor: AppColors.textMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.textMain,
          side: const BorderSide(color: AppColors.lineBrown),
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
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.textMain,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textMain,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: AppColors.textMain,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          height: 1.3,
          letterSpacing: 0,
        ),
        titleSmall: TextStyle(
          color: AppColors.textMain,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.35,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textMain,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSub,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          color: AppColors.textInverse,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSub,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
