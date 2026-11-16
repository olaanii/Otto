import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:google_fonts/google_fonts.dart';

/// Authentic Apple iOS 17/18 Human Interface Guidelines (HIG) theme definitions,
/// dynamic system colors, and SF Pro typographic scale for the Otto mobile client.
class IosColors {
  IosColors._();

  // --- Dynamic System Tint Colors (iOS 17/18 Spec) ---

  /// Standard iOS System Blue
  static const CupertinoDynamicColor systemBlue = CupertinoDynamicColor(
    color: Color(0xFF007AFF),
    darkColor: Color(0xFF0A84FF),
    highContrastColor: Color(0xFF0040DD),
    darkHighContrastColor: Color(0xFF409CFF),
    elevatedColor: Color(0xFF007AFF),
    darkElevatedColor: Color(0xFF0A84FF),
    highContrastElevatedColor: Color(0xFF0040DD),
    darkHighContrastElevatedColor: Color(0xFF409CFF),
  );

  /// Standard iOS System Green
  static const CupertinoDynamicColor systemGreen = CupertinoDynamicColor(
    color: Color(0xFF34C759),
    darkColor: Color(0xFF30D158),
    highContrastColor: Color(0xFF248A3D),
    darkHighContrastColor: Color(0xFF34C759),
    elevatedColor: Color(0xFF34C759),
    darkElevatedColor: Color(0xFF30D158),
    highContrastElevatedColor: Color(0xFF248A3D),
    darkHighContrastElevatedColor: Color(0xFF34C759),
  );

  /// Standard iOS System Indigo (Otto brand accent)
  static const CupertinoDynamicColor systemIndigo = CupertinoDynamicColor(
    color: Color(0xFF5856D6),
    darkColor: Color(0xFF5E5CE6),
    highContrastColor: Color(0xFF3634A3),
    darkHighContrastColor: Color(0xFF7D7AFF),
    elevatedColor: Color(0xFF5856D6),
    darkElevatedColor: Color(0xFF5E5CE6),
    highContrastElevatedColor: Color(0xFF3634A3),
    darkHighContrastElevatedColor: Color(0xFF7D7AFF),
  );

  /// Standard iOS System Orange
  static const CupertinoDynamicColor systemOrange = CupertinoDynamicColor(
    color: Color(0xFFFF9500),
    darkColor: Color(0xFFFF9F0A),
    highContrastColor: Color(0xFFC93400),
    darkHighContrastColor: Color(0xFFFFB340),
    elevatedColor: Color(0xFFFF9500),
    darkElevatedColor: Color(0xFFFF9F0A),
    highContrastElevatedColor: Color(0xFFC93400),
    darkHighContrastElevatedColor: Color(0xFFFFB340),
  );

  /// Standard iOS System Red
  static const CupertinoDynamicColor systemRed = CupertinoDynamicColor(
    color: Color(0xFFFF3B30),
    darkColor: Color(0xFFFF453A),
    highContrastColor: Color(0xFFD70015),
    darkHighContrastColor: Color(0xFFFF6961),
    elevatedColor: Color(0xFFFF3B30),
    darkElevatedColor: Color(0xFFFF453A),
    highContrastElevatedColor: Color(0xFFD70015),
    darkHighContrastElevatedColor: Color(0xFFFF6961),
  );

  /// Standard iOS System Purple
  static const CupertinoDynamicColor systemPurple = CupertinoDynamicColor(
    color: Color(0xFFAF52DE),
    darkColor: Color(0xFFBF5AF2),
    highContrastColor: Color(0xFF8944AB),
    darkHighContrastColor: Color(0xFFDA8FFF),
    elevatedColor: Color(0xFFAF52DE),
    darkElevatedColor: Color(0xFFBF5AF2),
    highContrastElevatedColor: Color(0xFF8944AB),
    darkHighContrastElevatedColor: Color(0xFFDA8FFF),
  );

  /// Standard iOS System Teal
  static const CupertinoDynamicColor systemTeal = CupertinoDynamicColor(
    color: Color(0xFF59ADC4),
    darkColor: Color(0xFF70D7FF),
    highContrastColor: Color(0xFF0071A4),
    darkHighContrastColor: Color(0xFF70D7FF),
    elevatedColor: Color(0xFF59ADC4),
    darkElevatedColor: Color(0xFF70D7FF),
    highContrastElevatedColor: Color(0xFF0071A4),
    darkHighContrastElevatedColor: Color(0xFF70D7FF),
  );

  /// Standard iOS System Mint
  static const CupertinoDynamicColor systemMint = CupertinoDynamicColor(
    color: Color(0xFF00C7BE),
    darkColor: Color(0xFF63E6E2),
    highContrastColor: Color(0xFF00817B),
    darkHighContrastColor: Color(0xFF63E6E2),
    elevatedColor: Color(0xFF00C7BE),
    darkElevatedColor: Color(0xFF63E6E2),
    highContrastElevatedColor: Color(0xFF00817B),
    darkHighContrastElevatedColor: Color(0xFF63E6E2),
  );

  // --- Dynamic System Backgrounds ---

  /// Primary background: pure white in light mode, pure black in dark mode (iOS 17/18 OLED black)
  static const CupertinoDynamicColor systemBackground = CupertinoDynamicColor(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF000000),
    highContrastColor: Color(0xFFFFFFFF),
    darkHighContrastColor: Color(0xFF000000),
    elevatedColor: Color(0xFFFFFFFF),
    darkElevatedColor: Color(0xFF1C1C1E),
    highContrastElevatedColor: Color(0xFFFFFFFF),
    darkHighContrastElevatedColor: Color(0xFF242426),
  );

  /// Secondary background for card surfaces and grouped table elements
  static const CupertinoDynamicColor secondarySystemBackground = CupertinoDynamicColor(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF1C1C1E),
    highContrastColor: Color(0xFFE5E5EA),
    darkHighContrastColor: Color(0xFF242426),
    elevatedColor: Color(0xFFF2F2F7),
    darkElevatedColor: Color(0xFF2C2C2E),
    highContrastElevatedColor: Color(0xFFE5E5EA),
    darkHighContrastElevatedColor: Color(0xFF363638),
  );

  /// Tertiary background for nested elements
  static const CupertinoDynamicColor tertiarySystemBackground = CupertinoDynamicColor(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF2C2C2E),
    highContrastColor: Color(0xFFFFFFFF),
    darkHighContrastColor: Color(0xFF363638),
    elevatedColor: Color(0xFFFFFFFF),
    darkElevatedColor: Color(0xFF3A3A3C),
    highContrastElevatedColor: Color(0xFFFFFFFF),
    darkHighContrastElevatedColor: Color(0xFF48484A),
  );

  /// Grouped background primary
  static const CupertinoDynamicColor systemGroupedBackground = CupertinoDynamicColor(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF000000),
    highContrastColor: Color(0xFFE5E5EA),
    darkHighContrastColor: Color(0xFF000000),
    elevatedColor: Color(0xFFF2F2F7),
    darkElevatedColor: Color(0xFF1C1C1E),
    highContrastElevatedColor: Color(0xFFE5E5EA),
    darkHighContrastElevatedColor: Color(0xFF242426),
  );

  /// Secondary grouped background (cells in grouped lists)
  static const CupertinoDynamicColor secondarySystemGroupedBackground = CupertinoDynamicColor(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF1C1C1E),
    highContrastColor: Color(0xFFFFFFFF),
    darkHighContrastColor: Color(0xFF242426),
    elevatedColor: Color(0xFFFFFFFF),
    darkElevatedColor: Color(0xFF2C2C2E),
    highContrastElevatedColor: Color(0xFFFFFFFF),
    darkHighContrastElevatedColor: Color(0xFF363638),
  );

  // --- Dynamic Text & Label Colors ---

  /// Primary label: solid black in light mode, solid white in dark mode
  static const CupertinoDynamicColor label = CupertinoDynamicColor(
    color: Color(0xFF000000),
    darkColor: Color(0xFFFFFFFF),
    highContrastColor: Color(0xFF000000),
    darkHighContrastColor: Color(0xFFFFFFFF),
    elevatedColor: Color(0xFF000000),
    darkElevatedColor: Color(0xFFFFFFFF),
    highContrastElevatedColor: Color(0xFF000000),
    darkHighContrastElevatedColor: Color(0xFFFFFFFF),
  );

  /// Secondary label for subtitles, timestamps, and secondary info
  static const CupertinoDynamicColor secondaryLabel = CupertinoDynamicColor(
    color: Color(0x993C3C43), // 60% opacity
    darkColor: Color(0x99EBEBF5),
    highContrastColor: Color(0xBC3C3C43),
    darkHighContrastColor: Color(0xBCEBEBF5),
    elevatedColor: Color(0x993C3C43),
    darkElevatedColor: Color(0x99EBEBF5),
    highContrastElevatedColor: Color(0xBC3C3C43),
    darkHighContrastElevatedColor: Color(0xBCEBEBF5),
  );

  /// Tertiary label for placeholder text, subtle markers
  static const CupertinoDynamicColor tertiaryLabel = CupertinoDynamicColor(
    color: Color(0x4D3C3C43), // 30% opacity
    darkColor: Color(0x4DEBEBF5),
    highContrastColor: Color(0x733C3C43),
    darkHighContrastColor: Color(0x73EBEBF5),
    elevatedColor: Color(0x4D3C3C43),
    darkElevatedColor: Color(0x4DEBEBF5),
    highContrastElevatedColor: Color(0x733C3C43),
    darkHighContrastElevatedColor: Color(0x73EBEBF5),
  );

  // --- Separator & Grays ---

  /// Standard iOS hair-line separator
  static const CupertinoDynamicColor separator = CupertinoDynamicColor(
    color: Color(0x4A3C3C43), // 29% opacity
    darkColor: Color(0x99545458), // 60% opacity
    highContrastColor: Color(0x5E3C3C43),
    darkHighContrastColor: Color(0xAB545458),
    elevatedColor: Color(0x4A3C3C43),
    darkElevatedColor: Color(0x99545458),
    highContrastElevatedColor: Color(0x5E3C3C43),
    darkHighContrastElevatedColor: Color(0xAB545458),
  );

  /// Translucent fill for search bars, drag grabbers, segmented controls
  static const CupertinoDynamicColor systemFill = CupertinoDynamicColor(
    color: Color(0x33787880), // 20% opacity
    darkColor: Color(0x5C787880), // 36% opacity
    highContrastColor: Color(0x47787880),
    darkHighContrastColor: Color(0x70787880),
    elevatedColor: Color(0x33787880),
    darkElevatedColor: Color(0x5C787880),
    highContrastElevatedColor: Color(0x47787880),
    darkHighContrastElevatedColor: Color(0x70787880),
  );

  /// Modal sheet drag grabber bar color
  static const CupertinoDynamicColor grabberColor = CupertinoDynamicColor(
    color: Color(0x4D3C3C43),
    darkColor: Color(0x66EBEBF5),
    highContrastColor: Color(0x803C3C43),
    darkHighContrastColor: Color(0x8CEBEBF5),
    elevatedColor: Color(0x4D3C3C43),
    darkElevatedColor: Color(0x66EBEBF5),
    highContrastElevatedColor: Color(0x803C3C43),
    darkHighContrastElevatedColor: Color(0x8CEBEBF5),
  );

  // --- Git Stacking & Diff Specialized Colors ---

  /// Diff Addition Green Background
  static const CupertinoDynamicColor diffAdditionBg = CupertinoDynamicColor(
    color: Color(0x1F34C759),
    darkColor: Color(0x2E30D158),
    highContrastColor: Color(0x33248A3D),
    darkHighContrastColor: Color(0x3D34C759),
    elevatedColor: Color(0x1F34C759),
    darkElevatedColor: Color(0x2E30D158),
    highContrastElevatedColor: Color(0x33248A3D),
    darkHighContrastElevatedColor: Color(0x3D34C759),
  );

  /// Diff Deletion Red Background
  static const CupertinoDynamicColor diffDeletionBg = CupertinoDynamicColor(
    color: Color(0x1FFF3B30),
    darkColor: Color(0x2EFF453A),
    highContrastColor: Color(0x33D70015),
    darkHighContrastColor: Color(0x3DFF6961),
    elevatedColor: Color(0x1FFF3B30),
    darkElevatedColor: Color(0x2EFF453A),
    highContrastElevatedColor: Color(0x33D70015),
    darkHighContrastElevatedColor: Color(0x3DFF6961),
  );

  /// Conventional Commit Type: feat -> indigo
  static const Color commitFeat = Color(0xFF5856D6);
  /// Conventional Commit Type: fix -> emerald green
  static const Color commitFix = Color(0xFF34C759);
  /// Conventional Commit Type: refactor -> amber/orange
  static const Color commitRefactor = Color(0xFFFF9500);
  /// Conventional Commit Type: perf -> purple
  static const Color commitPerf = Color(0xFFAF52DE);
  /// Conventional Commit Type: chore/docs -> gray
  static const Color commitChore = Color(0xFF8E8E93);
}

/// SF Pro Typographic scale calibrated to Apple iOS 17/18 Human Interface Guidelines.
class IosTypography {
  IosTypography._();

  static TextStyle get _baseStyle {
    // Inter / SF Pro style typography fallback
    return GoogleFonts.inter();
  }

  /// Collapsible Large Title (34pt, Bold, -0.4 letter spacing)
  static TextStyle get largeTitle => _baseStyle.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
      );

  /// Title 1 (28pt, Bold, 0.36)
  static TextStyle get title1 => _baseStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.36,
        height: 1.22,
      );

  /// Title 2 (22pt, Bold, 0.35)
  static TextStyle get title2 => _baseStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
        height: 1.25,
      );

  /// Title 3 (20pt, Semibold, 0.38)
  static TextStyle get title3 => _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.38,
        height: 1.25,
      );

  /// Headline (17pt, Semibold, -0.41)
  static TextStyle get headline => _baseStyle.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
        height: 1.3,
      );

  /// Body (17pt, Regular, -0.41)
  static TextStyle get body => _baseStyle.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.41,
        height: 1.3,
      );

  /// Callout (16pt, Regular, -0.32)
  static TextStyle get callout => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,
        height: 1.3,
      );

  /// Subheadline (15pt, Regular, -0.24)
  static TextStyle get subheadline => _baseStyle.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.24,
        height: 1.33,
      );

  /// Footnote (13pt, Regular, -0.08)
  static TextStyle get footnote => _baseStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.08,
        height: 1.35,
      );

  /// Caption 1 (12pt, Regular, 0.0)
  static TextStyle get caption1 => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.33,
      );

  /// Caption 2 (11pt, Regular, 0.07)
  static TextStyle get caption2 => _baseStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.07,
        height: 1.36,
      );

  /// SF Mono / Code Font for diffs, SHAs, LOC counters
  static TextStyle get monoCode => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  /// Bold variant of monoCode
  static TextStyle get monoCodeBold => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );
}

/// Cupertino theme bundle providing standard iOS 17/18 styling.
class IosCupertinoTheme {
  IosCupertinoTheme._();

  /// Light CupertinoThemeData
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: IosColors.systemIndigo,
      primaryContrastingColor: CupertinoColors.white,
      barBackgroundColor: Color(0xCCF8F8F8), // Translucent frosted glass effect
      scaffoldBackgroundColor: Color(0xFFF2F2F7), // Grouped background
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: Color(0xFF000000),
      ),
    );
  }

  /// Dark CupertinoThemeData (authentic OLED iOS black)
  static CupertinoThemeData get darkTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: IosColors.systemIndigo,
      primaryContrastingColor: CupertinoColors.black,
      barBackgroundColor: Color(0xCC121212), // Translucent dark blur
      scaffoldBackgroundColor: Color(0xFF000000), // Pure OLED black
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: Color(0xFFFFFFFF),
      ),
    );
  }

  /// Helper to check if current Cupertino/Material context is dark mode
  static bool isDark(BuildContext context) {
    return CupertinoTheme.brightnessOf(context) == Brightness.dark;
  }

  /// Resolves any CupertinoDynamicColor to the current ambient brightness
  static Color resolve(CupertinoDynamicColor dynamicColor, BuildContext context) {
    return dynamicColor.resolveFrom(context);
  }
}
