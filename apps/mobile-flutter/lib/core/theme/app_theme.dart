import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

export 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => light();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple,
      brightness: Brightness.light,
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryPink,
      surface: AppColors.bgDefault,
      surfaceContainerHighest: AppColors.bgPaper,
      outline: AppColors.lineSoft,
      error: AppColors.accentRed,
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
      cardTheme: CardThemeData(
        color: AppColors.bgPaper,
        elevation: 0.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.lineSoft),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.primaryPurple,
          side: const BorderSide(color: AppColors.linePurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.primaryPink,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.bgDefault,
        indicatorColor: AppColors.primaryPurpleSoft,
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textMain,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          height: 1.2,
          letterSpacing: 0,
        ),
        displayMedium: TextStyle(
          color: AppColors.textMain,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textMain,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: AppColors.textMain,
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSub,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.4,
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
