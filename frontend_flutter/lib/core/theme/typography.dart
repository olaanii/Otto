import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography combining Inter for interface controls and JetBrains Mono for diff lines.
class AppTypography {
  const AppTypography._();

  static TextStyle get uiFont => GoogleFonts.inter();
  static TextStyle get codeFont => GoogleFonts.jetBrainsMono();

  static TextTheme textTheme(Color textColor, Color subtextColor) {
    return TextTheme(
      displayLarge: uiFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textColor,
      ),
      displayMedium: uiFont.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: textColor,
      ),
      titleLarge: uiFont.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textColor,
      ),
      titleMedium: uiFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: uiFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: uiFont.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: uiFont.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: uiFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: subtextColor,
      ),
      labelLarge: uiFont.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: uiFont.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: subtextColor,
      ),
    );
  }

  static TextStyle diffLineStyle({
    required bool isDark,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return codeFont.copyWith(
      fontSize: 12.5,
      height: 1.45,
      fontWeight: fontWeight,
      color: color ?? (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF18181B)),
    );
  }

  static TextStyle diffGutterStyle({required bool isDark}) {
    return codeFont.copyWith(
      fontSize: 11.5,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
    );
  }
}
