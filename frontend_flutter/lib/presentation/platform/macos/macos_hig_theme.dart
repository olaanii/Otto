import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Complete Apple macOS Sonoma & Sequoia Human Interface Guidelines (HIG) theme tokens.
/// Encapsulates vibrancy materials, AppKit window geometry, SF Pro typography,
/// frosted liquid glass shaders, and Apple system color tokens.
class MacOSTheme {
  const MacOSTheme._();

  // ---------------------------------------------------------------------------
  // Apple macOS System Colors (Sonoma / Sequoia Dynamic Palette)
  // ---------------------------------------------------------------------------
  static const Color systemBlueLight = Color(0xFF007AFF);
  static const Color systemBlueDark = Color(0xFF0A84FF);

  static const Color systemPurpleLight = Color(0xFFAF52DE);
  static const Color systemPurpleDark = Color(0xFFBF5AF2);

  static const Color systemGreenLight = Color(0xFF34C759);
  static const Color systemGreenDark = Color(0xFF30D158);

  static const Color systemOrangeLight = Color(0xFFFF9500);
  static const Color systemOrangeDark = Color(0xFFFF9F0A);

  static const Color systemRedLight = Color(0xFFFF3B30);
  static const Color systemRedDark = Color(0xFFFF453A);

  static const Color systemYellowLight = Color(0xFFFFCC00);
  static const Color systemYellowDark = Color(0xFFFFD60A);

  static const Color systemTealLight = Color(0xFF59ADC4);
  static const Color systemTealDark = Color(0xFF6AC4DC);

  static const Color systemIndigoLight = Color(0xFF5856D6);
  static const Color systemIndigoDark = Color(0xFF5E5CE6);

  // ---------------------------------------------------------------------------
  // macOS Window Traffic Light Controls (Close, Minimize, Zoom)
  // ---------------------------------------------------------------------------
  static const Color trafficLightClose = Color(0xFFFF5F56);
  static const Color trafficLightCloseBorder = Color(0xFFE0443E);
  static const Color trafficLightMinimize = Color(0xFFFFBD2E);
  static const Color trafficLightMinimizeBorder = Color(0xFFDEA123);
  static const Color trafficLightZoom = Color(0xFF27C93F);
  static const Color trafficLightZoomBorder = Color(0xFF1AAB29);
  static const Color trafficLightInactive = Color(0xFFDCDCDC);
  static const Color trafficLightInactiveDark = Color(0xFF4A4A4A);

  static const double trafficLightDiameter = 12.0;
  static const double trafficLightSpacing = 8.0;
  static const double trafficLightLeftMargin = 16.0;
  static const double trafficLightToolbarWidth = 82.0;

  // ---------------------------------------------------------------------------
  // Dynamic Helpers for Light / Dark Mode
  // ---------------------------------------------------------------------------
  static Color systemBlue(bool isDark) =>
      isDark ? systemBlueDark : systemBlueLight;
  static Color systemPurple(bool isDark) =>
      isDark ? systemPurpleDark : systemPurpleLight;
  static Color systemGreen(bool isDark) =>
      isDark ? systemGreenDark : systemGreenLight;
  static Color systemOrange(bool isDark) =>
      isDark ? systemOrangeDark : systemOrangeLight;
  static Color systemRed(bool isDark) =>
      isDark ? systemRedDark : systemRedLight;
  static Color systemIndigo(bool isDark) =>
      isDark ? systemIndigoDark : systemIndigoLight;

  // ---------------------------------------------------------------------------
  // Canvas & Background Tints (AppKit NSVisualEffect Materials)
  // ---------------------------------------------------------------------------
  static Color windowBackground(bool isDark) =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F6F6);

  static Color sidebarBackground(bool isDark) => isDark
      ? const Color(0xCC1A1A1C) // Semi-transparent for blur backdrop
      : const Color(0xD9ECECEC);

  static Color toolbarBackground(bool isDark) => isDark
      ? const Color(0xB8242426)
      : const Color(0xCCF7F7F7);

  static Color contentBackground(bool isDark) =>
      isDark ? const Color(0xFF161618) : const Color(0xFFFFFFFF);

  static Color cardBackground(bool isDark) =>
      isDark ? const Color(0xFF232326) : const Color(0xFFFFFFFF);

  static Color sheetBackground(bool isDark) =>
      isDark ? const Color(0xFA222226) : const Color(0xFBF8F8F9);

  // ---------------------------------------------------------------------------
  // Hairline Borders & Glass Highlights
  // ---------------------------------------------------------------------------
  static Color border(bool isDark) => isDark
      ? const Color(0x2EFFFFFF) // 0.5px subtle separator
      : const Color(0x1F000000);

  static Color subtleBorder(bool isDark) => isDark
      ? const Color(0x1CFFFFFF)
      : const Color(0x12000000);

  /// Top highlight line imitating the Apple liquid glass refraction stroke
  static Color topGlassHighlight(bool isDark) => isDark
      ? const Color(0x29FFFFFF) // 16% white top sheen
      : const Color(0x80FFFFFF); // 50% white top sheen

  // ---------------------------------------------------------------------------
  // Text Tokens (SF Pro System Label Colors)
  // ---------------------------------------------------------------------------
  static Color label(bool isDark) =>
      isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);

  static Color secondaryLabel(bool isDark) =>
      isDark ? const Color(0x9EFFFFFF) : const Color(0x99000000);

  static Color tertiaryLabel(bool isDark) =>
      isDark ? const Color(0x61FFFFFF) : const Color(0x4D000000);

  static Color quaternaryLabel(bool isDark) =>
      isDark ? const Color(0x2EFFFFFF) : const Color(0x2E000000);

  // ---------------------------------------------------------------------------
  // Selection Pills & Controls
  // ---------------------------------------------------------------------------
  static Color selectionPill(bool isDark) => isDark
      ? systemBlueDark.withOpacity(0.22)
      : systemBlueLight.withOpacity(0.14);

  static Color selectionPillActive(bool isDark) =>
      isDark ? systemBlueDark : systemBlueLight;

  static Color segmentedControlTrack(bool isDark) => isDark
      ? const Color(0x40000000)
      : const Color(0x18000000);

  static Color segmentedControlPill(bool isDark) => isDark
      ? const Color(0xFF38383C)
      : const Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // AppKit Drop Shadows
  // ---------------------------------------------------------------------------
  static List<BoxShadow> windowShadow = const [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 40,
      spreadRadius: 0,
      offset: Offset(0, 18),
    ),
  ];

  static List<BoxShadow> sheetShadow = const [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 36,
      spreadRadius: 2,
      offset: Offset(0, 14),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> segmentedPillShadow = const [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      spreadRadius: 0,
      offset: Offset(0, 1.5),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 1,
      spreadRadius: 0,
      offset: Offset(0, 0.5),
    ),
  ];

  // ---------------------------------------------------------------------------
  // SF Pro Typography System (Inter with SF Pro Tracking & Proportions)
  // ---------------------------------------------------------------------------
  static TextStyle get sfPro => GoogleFonts.inter();
  static TextStyle get sfMono => GoogleFonts.jetBrainsMono();

  static TextStyle largeTitle({required bool isDark}) => sfPro.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
        color: label(isDark),
      );

  static TextStyle title1({required bool isDark}) => sfPro.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        color: label(isDark),
      );

  static TextStyle title2({required bool isDark}) => sfPro.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: label(isDark),
      );

  static TextStyle title3({required bool isDark}) => sfPro.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: label(isDark),
      );

  static TextStyle headline({required bool isDark}) => sfPro.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        color: label(isDark),
      );

  static TextStyle body({required bool isDark}) => sfPro.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: label(isDark),
      );

  static TextStyle callout({required bool isDark}) => sfPro.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: secondaryLabel(isDark),
      );

  static TextStyle subheadline({required bool isDark}) => sfPro.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: secondaryLabel(isDark),
      );

  static TextStyle footnote({required bool isDark}) => sfPro.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: tertiaryLabel(isDark),
      );

  static TextStyle code({
    required bool isDark,
    double fontSize = 11.5,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) =>
      sfMono.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.2,
        height: 1.4,
        color: color ?? label(isDark),
      );
}

/// Frosted liquid glass container replicating macOS NSVisualEffectView vibrancy.
class MacOSVisualEffectBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadows;
  final bool showTopSheen;

  const MacOSVisualEffectBox({
    super.key,
    required this.child,
    this.blur = 28.0,
    required this.backgroundColor,
    this.borderRadius,
    this.border,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.shadows,
    this.showTopSheen = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.zero;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: r,
        border: border ??
            Border.all(
              color: MacOSTheme.border(isDark),
              width: 0.5,
            ),
      ),
      child: Stack(
        children: [
          if (showTopSheen && r != BorderRadius.zero)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: MacOSTheme.topGlassHighlight(isDark),
                  borderRadius: BorderRadius.only(
                    topLeft: r.topLeft,
                    topRight: r.topRight,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );

    // Apply BackdropFilter for authentic AppKit frosted glass look
    content = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    if (shadows != null && shadows!.isNotEmpty) {
      content = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: shadows,
        ),
        child: content,
      );
    } else if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
