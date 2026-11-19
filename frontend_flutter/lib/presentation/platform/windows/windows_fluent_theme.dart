import 'dart:ui';
import 'package:flutter/material.dart';

/// Microsoft Windows 11 Fluent Design System 2 Theme Tokens & Controls.
/// Provides authentic Mica & Acrylic backdrops, Segoe UI Variable typography,
/// elevation hierarchies, stroke outlines, and Fluent component styling.
class FluentMicaColors {
  const FluentMicaColors._();

  // --- Light Theme Mica & Acrylic ---
  static const Color micaBaseLight = Color(0xFFF3F3F3);
  static const Color micaAltLight = Color(0xFFDADADA);
  static const Color acrylicBackgroundLight = Color(0xF2FCFCFC);
  static const Color layerBackgroundLight = Color(0xFFFFFFFF);
  static const Color layerBackgroundAltLight = Color(0xFFF9F9F9);
  static const Color subtleFillTransparentLight = Color(0x00000000);
  static const Color subtleFillSecondaryLight = Color(0x09000000); // 3.7% black hover
  static const Color subtleFillTertiaryLight = Color(0x0F000000); // 6% black pressed

  // --- Dark Theme Mica & Acrylic ---
  static const Color micaBaseDark = Color(0xFF202020);
  static const Color micaAltDark = Color(0xFF1B1B1B); // Figma Navigation pane background #1b1b1b
  static const Color acrylicBackgroundDark = Color(0xF0202020);
  static const Color layerBackgroundDark = Color(0xFF2B2B2B); // Figma Panes & Cards #2b2b2b
  static const Color layerBackgroundAltDark = Color(0xFF2F2F2F); // Figma Raised Card & Active Nav #2f2f2f
  static const Color subtleFillTransparentDark = Color(0x00FFFFFF);
  static const Color subtleFillSecondaryDark = Color(0x0DFFFFFF); // 5% white hover
  static const Color subtleFillTertiaryDark = Color(0x14FFFFFF); // 8% white pressed

  // --- Figma Exact Surfaces & Controls ---
  static const Color navBackground = Color(0xFF1B1B1B);
  static const Color cardBackground = Color(0xFF2B2B2B);
  static const Color cardRaised = Color(0xFF2F2F2F);
  static const Color cardActive = Color(0xFF2A2A2E);
  static const Color borderDefault = Color(0xFF3A3A3A);
  static const Color borderInput = Color(0xFF484848);
  static const Color inputBg = Color(0xFF3A3A3A);
  static const Color buttonDefaultBg = Color(0xFF3A3A3A);
  static const Color buttonPrimaryBg = Color(0xFF60CDFF);

  // --- Fluent Strokes & Borders ---
  static const Color cardStrokeLight = Color(0x0F000000); // 6% black outline
  static const Color cardStrokeDark = Color(0xFF3A3A3A); // Figma 1px border #3a3a3a
  static const Color surfaceStrokeLight = Color(0x0D000000);
  static const Color surfaceStrokeDark = Color(0xFF484848); // Figma input border #484848
  static const Color dividerStrokeLight = Color(0x12000000);
  static const Color dividerStrokeDark = Color(0xFF3A3A3A);
  static const Color focusStroke = Color(0xFF60CDFF);

  // --- Fluent Text Colors ---
  static const Color textPrimaryLight = Color(0xE4000000); // 89% black
  static const Color textSecondaryLight = Color(0x9E000000); // 62% black
  static const Color textTertiaryLight = Color(0x73000000); // 45% black
  static const Color textDisabledLight = Color(0x5C000000); // 36% black

  static const Color textPrimaryDark = Color(0xFFFFFFFF); // 100% white
  static const Color textSecondaryDark = Color(0xFFB3B3B3); // Figma secondary text #b3b3b3
  static const Color textTertiaryDark = Color(0xFF8A8A8A); // Figma subtle/line counter #8a8a8a
  static const Color textDisabledDark = Color(0x5EFFFFFF); // 37% white

  // --- Windows 11 System Accents (Otto Figma Theme) ---
  static const Color accentDefault = Color(0xFF60CDFF); // Figma Cyan Accent #60cdff
  static const Color accentLight = Color(0xFF60CDFF); // Figma Cyan Accent #60cdff
  static const Color accentDark = Color(0xFF0078D4);
  static const Color accentIndigo = Color(0xFF60CDFF);
  static const Color accentIndigoDark = Color(0xFF0078D4);

  // Status & Git Accents from Figma
  static const Color statusReady = Color(0xFF6CCB5F); // Figma Green #6ccb5f
  static const Color statusDraft = Color(0xFFB3B3B3); // Figma Draft Grey #b3b3b3
  static const Color statusInReview = Color(0xFFFCE100); // Figma Yellow #fce100
  static const Color statusNeedsAttention = Color(0xFFFCE100);
  static const Color statusNotConnected = Color(0xFF8A8A8A);
  static const Color gitAdded = Color(0xFF6CCB5F); // Emerald
  static const Color gitAddedSubtleLight = Color(0xFFE6F4EA);
  static const Color gitAddedSubtleDark = Color(0x286CCB5F);

  static const Color gitRemoved = Color(0xFFFF8A80); // Rose / Danger
  static const Color gitRemovedSubtleLight = Color(0xFFFCE8E6);
  static const Color gitRemovedSubtleDark = Color(0x28FF8A80);

  static const Color gitModified = Color(0xFFFCE100); // Amber
  static const Color gitModifiedSubtleLight = Color(0xFFFEF3C7);
  static const Color gitModifiedSubtleDark = Color(0x28FCE100);

  // Figma Exact Screen-Specific Tokens
  static const Color diffAddedLine = Color(0xFF1E3A29); // Figma #1e3a29
  static const Color diffDeletedLine = Color(0xFF3D2226); // Figma #3d2226
  static const Color syncErrorBannerBg = Color(0xFF3A3210); // Figma #3a3210
  static const Color syncErrorBannerBorder = Color(0xFF6B5A1E); // Figma #6b5a1e
  static const Color syncErrorText = Color(0xFFFCE100); // Figma #fce100
  static const Color dangerText = Color(0xFFFF8A80); // Figma #ff8a80
  static const Color dangerBorder = Color(0xFF5A2A2E); // Figma #5a2a2e
  static const Color shortcutKeycapBg = Color(0xFF383838); // Figma #383838
  static const Color shortcutKeycapBorder = Color(0xFF4A4A4A); // Figma #4a4a4a

  // Windows Titlebar Control Hover Colors
  static const Color closeButtonHover = Color(0xFFC42B1C);
  static const Color closeButtonPressed = Color(0xFFB82618);
  static const Color captionHoverLight = Color(0x0A000000);
  static const Color captionHoverDark = Color(0x0FFFFFFF);
}

/// Segoe UI Variable Typography for Windows 11 Fluent 2.
class FluentTypography {
  const FluentTypography._();

  static const String fontFamily = 'Segoe UI Variable, Segoe UI, -apple-system, BlinkMacSystemFont, sans-serif';
  static const String monoFamily = 'Cascadia Code, Consolas, JetBrains Mono, monospace';

  static TextStyle get caption => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  static TextStyle get captionStrong => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  static TextStyle get bodyStrong => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
      );

  static TextStyle get subtitle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get title => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 40,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      );

  /// Tabular numbers typography for diff line counters and commit statistics.
  static TextStyle diffLineStyle({
    required bool isDark,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: 12.5,
      height: 1.45,
      fontWeight: fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color ?? (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF18181B)),
    );
  }

  static TextStyle diffGutterStyle({required bool isDark}) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: 11.5,
      height: 1.45,
      fontWeight: FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
    );
  }
}

/// Elevation hierarchies in Fluent Design System 2.
class FluentElevation {
  const FluentElevation._();

  static List<BoxShadow> cardRest(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x28000000) : const Color(0x0A000000),
          blurRadius: 4,
          offset: const Offset(0, 1.5),
        ),
      ];

  static List<BoxShadow> cardHover(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x3D000000) : const Color(0x14000000),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> flyout(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x52000000) : const Color(0x24000000),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: isDark ? const Color(0x28000000) : const Color(0x14000000),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> dialog(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x7A000000) : const Color(0x38000000),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: isDark ? const Color(0x3D000000) : const Color(0x1A000000),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Authentic Acrylic / Mica Backdrop Layer Widget.
class FluentMicaBackdrop extends StatelessWidget {
  final Widget child;
  final bool isAlt;
  final bool enableAcrylicBlur;

  const FluentMicaBackdrop({
    super.key,
    required this.child,
    this.isAlt = false,
    this.enableAcrylicBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? (isAlt ? FluentMicaColors.micaAltDark : FluentMicaColors.micaBaseDark)
        : (isAlt ? FluentMicaColors.micaAltLight : FluentMicaColors.micaBaseLight);

    if (!enableAcrylicBlur) {
      return ColoredBox(
        color: baseColor,
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid tinted base
        ColoredBox(color: baseColor),

        // Frosted glass acrylic blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: (isDark
                    ? FluentMicaColors.acrylicBackgroundDark
                    : FluentMicaColors.acrylicBackgroundLight)
                .withOpacity(0.35),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

/// Fluent Card Container with standard 8px corner radii and 1px stroke outline.
class FluentCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? borderColor;

  const FluentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<FluentCard> createState() => _FluentCardState();
}

class _FluentCardState extends State<FluentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? FluentMicaColors.layerBackgroundDark
        : FluentMicaColors.layerBackgroundLight;

    final defaultBorder = isDark
        ? FluentMicaColors.cardStrokeDark
        : FluentMicaColors.cardStrokeLight;

    final activeBorder = isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? defaultBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? activeBorder
                  : (widget.borderColor ??
                      (_isHovered && widget.onTap != null
                          ? defaultBorder.withOpacity(0.35)
                          : defaultBorder)),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered && widget.onTap != null
                ? FluentElevation.cardHover(isDark)
                : FluentElevation.cardRest(isDark),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Windows 11 Fluent Pill Toggle Switch.
class FluentToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? tooltip;

  const FluentToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault;

    final switchWidget = GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 40,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: value
                ? accent
                : (isDark
                    ? const Color(0xFF333333)
                    : const Color(0xFFE5E5E5)),
            border: Border.all(
              color: value
                  ? accent
                  : (isDark ? FluentMicaColors.cardStrokeDark : FluentMicaColors.cardStrokeLight),
              width: 1,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? (isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF))
                    : (isDark ? const Color(0xFFD0D0D0) : const Color(0xFF5A5A5A)),
              ),
            ),
          ),
        ),
      ),
    );

    if (label == null) {
      return tooltip != null ? Tooltip(message: tooltip!, child: switchWidget) : switchWidget;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        switchWidget,
        const SizedBox(width: 8),
        Text(
          label!,
          style: FluentTypography.body.copyWith(
            fontSize: 12.5,
            color: isDark ? FluentMicaColors.textPrimaryDark : FluentMicaColors.textPrimaryLight,
          ),
        ),
      ],
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: content) : content;
  }
}

/// Fluent Interactive Button (Standard, Accent, Subtle).
enum FluentButtonStyle { standard, accent, subtle, danger }

class FluentButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FluentButtonStyle style;
  final EdgeInsetsGeometry padding;
  final double height;
  final String? tooltip;
  final IconData? icon;

  const FluentButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style = FluentButtonStyle.standard,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.height = 32,
    this.tooltip,
    this.icon,
  });

  @override
  State<FluentButton> createState() => _FluentButtonState();
}

class _FluentButtonState extends State<FluentButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null;

    Color bg;
    Color border;
    Color fg;

    switch (widget.style) {
      case FluentButtonStyle.accent:
        final accent = isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault;
        bg = _isPressed
            ? accent.withOpacity(0.85)
            : (_isHovered ? accent.withOpacity(0.92) : accent);
        border = Colors.transparent;
        fg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
        break;

      case FluentButtonStyle.subtle:
        bg = _isPressed
            ? (isDark
                ? FluentMicaColors.subtleFillTertiaryDark
                : FluentMicaColors.subtleFillTertiaryLight)
            : (_isHovered
                ? (isDark
                    ? FluentMicaColors.subtleFillSecondaryDark
                    : FluentMicaColors.subtleFillSecondaryLight)
                : Colors.transparent);
        border = Colors.transparent;
        fg = isDark ? FluentMicaColors.textPrimaryDark : FluentMicaColors.textPrimaryLight;
        break;

      case FluentButtonStyle.danger:
        bg = _isPressed
            ? FluentMicaColors.closeButtonPressed
            : (_isHovered ? FluentMicaColors.closeButtonHover : const Color(0xFFD83B01));
        border = Colors.transparent;
        fg = Colors.white;
        break;

      case FluentButtonStyle.standard:
        bg = _isPressed
            ? (isDark ? const Color(0xFF444444) : const Color(0xFFE8E8E8))
            : (_isHovered
                ? (isDark ? const Color(0xFF404040) : const Color(0xFFF5F5F5))
                : (isDark
                    ? const Color(0xFF3A3A3A)
                    : FluentMicaColors.layerBackgroundLight));
        border = isDark ? const Color(0xFF484848) : FluentMicaColors.cardStrokeLight;
        fg = isDark ? FluentMicaColors.textPrimaryDark : FluentMicaColors.textPrimaryLight;
        break;
    }

    if (!isEnabled) {
      bg = isDark ? const Color(0x10FFFFFF) : const Color(0x08000000);
      border = Colors.transparent;
      fg = isDark ? FluentMicaColors.textDisabledDark : FluentMicaColors.textDisabledLight;
    }

    final buttonWidget = MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isEnabled) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutQuad,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              DefaultTextStyle(
                style: FluentTypography.bodyStrong.copyWith(
                  fontSize: 12.5,
                  color: fg,
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? FluentMicaColors.cardStrokeDark : FluentMicaColors.cardStrokeLight,
          ),
          boxShadow: FluentElevation.flyout(isDark),
        ),
        textStyle: FluentTypography.caption.copyWith(
          color: isDark ? FluentMicaColors.textPrimaryDark : FluentMicaColors.textPrimaryLight,
        ),
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
