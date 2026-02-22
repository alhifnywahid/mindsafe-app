import 'package:flutter/material.dart';
import 'package:mindsafe_flutter/core/constants/app_colors.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';
import 'package:mindsafe_flutter/core/constants/app_text_styles.dart';

class DarkTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: AppColors.gray900,
      onSecondary: AppColors.white,
      onSurface: AppColors.gray100,
      onError: AppColors.white,
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.gray100,
      titleTextStyle: AppTextStyles.headingMedium.copyWith(
        color: AppColors.gray100,
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      elevation: AppSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      color: AppColors.darkCard,
      margin: EdgeInsets.zero,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.gray900,
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        textStyle: AppTextStyles.button,
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.gray600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.gray600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: AppSpacing.paddingMd,
    ),

    // Icon
    iconTheme: const IconThemeData(color: AppColors.gray300, size: 24),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(
        color: AppColors.gray100,
      ),
      displayMedium: AppTextStyles.displayMedium.copyWith(
        color: AppColors.gray100,
      ),
      displaySmall: AppTextStyles.displaySmall.copyWith(
        color: AppColors.gray100,
      ),
      headlineLarge: AppTextStyles.headingLarge.copyWith(
        color: AppColors.gray100,
      ),
      headlineMedium: AppTextStyles.headingMedium.copyWith(
        color: AppColors.gray100,
      ),
      headlineSmall: AppTextStyles.headingSmall.copyWith(
        color: AppColors.gray100,
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.gray200),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray200),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.gray300),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.gray300),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.gray300),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.gray400),
    ),
  );
}
