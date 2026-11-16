import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'typography.dart';

/// Moonjar-inspired application theme system with light and dark mode variants.
class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = AppTypography.textTheme(
      AppColors.zinc900,
      AppColors.zinc600,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paperLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.indigo600,
        onPrimary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.zinc900,
        outline: AppColors.borderLight,
        secondary: AppColors.amber500,
        error: AppColors.rose600,
      ),
      textTheme: textTheme,
      cardTheme: CardTheme(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.zinc800),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = AppTypography.textTheme(
      AppColors.zinc100,
      AppColors.zinc400,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.indigo500,
        onPrimary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.zinc100,
        outline: AppColors.borderDark,
        secondary: AppColors.amber400,
        error: AppColors.rose500,
      ),
      textTheme: textTheme,
      cardTheme: CardTheme(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.zinc200),
      ),
    );
  }
}
