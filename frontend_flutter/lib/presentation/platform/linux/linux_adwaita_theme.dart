import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Official GNOME HIG & Libadwaita Color Palette.
/// Conforms to GNOME Libadwaita style specifications:
/// https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/named-colors.html
class AdwaitaColors {
  const AdwaitaColors._();

  // Primary Accent: Adwaita Blue
  static const Color blue1 = Color(0xFF99C1F1);
  static const Color blue2 = Color(0xFF62A0EA);
  static const Color blue3 = Color(0xFF3584E4); // Standard Adwaita Accent
  static const Color blue4 = Color(0xFF1C71D8);
  static const Color blue5 = Color(0xFF1A5FB4);

  // Success: Adwaita Green
  static const Color green1 = Color(0xFF8FF0A4);
  static const Color green2 = Color(0xFF57E389);
  static const Color green3 = Color(0xFF33D17A); // Dark mode success
  static const Color green4 = Color(0xFF26A269); // Light mode success
  static const Color green5 = Color(0xFF1F7A4D);

  // Warning: Adwaita Yellow / Amber
  static const Color yellow1 = Color(0xFFF9F06B);
  static const Color yellow2 = Color(0xFFF8E45C);
  static const Color yellow3 = Color(0xFFF6D32D); // Dark mode warning
  static const Color yellow4 = Color(0xFFE5A50A); // Light mode warning
  static const Color yellow5 = Color(0xFFC67800);

  // Destructive / Error: Adwaita Red
  static const Color red1 = Color(0xFFF66151); // Dark mode error
  static const Color red2 = Color(0xFFED333B);
  static const Color red3 = Color(0xFFE01B24); // Standard Destructive
  static const Color red4 = Color(0xFFC01C28); // Light mode error
  static const Color red5 = Color(0xFF86181D);

  // Purple / Violet: Adwaita Purple
  static const Color purple1 = Color(0xFFDC8ADD);
  static const Color purple2 = Color(0xFFC061CB);
  static const Color purple3 = Color(0xFF9141AC);
  static const Color purple4 = Color(0xFF813D9C);
  static const Color purple5 = Color(0xFF613583);

  // Neutral / Window Backgrounds
  // Libadwaita Dark
  static const Color darkWindowBg = Color(0xFF242424);     // @window_bg_color
  static const Color darkViewBg = Color(0xFF1E1E1E);       // @view_bg_color
  static const Color darkCardBg = Color(0xFF303030);       // @card_bg_color
  static const Color darkHeaderBarBg = Color(0xFF282828);  // @headerbar_bg_color
  static const Color darkPopoverBg = Color(0xFF383838);    // @popover_bg_color
  static const Color darkBorder = Color(0x1FFFFFFF);       // ~12% white outline
  static const Color darkBorderCrisp = Color(0xFF3D3D3D);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // 70% opacity
  static const Color darkTextMuted = Color(0x73FFFFFF);     // 45% opacity

  // Libadwaita Light
  static const Color lightWindowBg = Color(0xFFFAFAFA);    // @window_bg_color
  static const Color lightViewBg = Color(0xFFFFFFFF);      // @view_bg_color
  static const Color lightCardBg = Color(0xFFFFFFFF);      // @card_bg_color
  static const Color lightHeaderBarBg = Color(0xFFEBEBEB); // @headerbar_bg_color
  static const Color lightPopoverBg = Color(0xFFFFFFFF);   // @popover_bg_color
  static const Color lightBorder = Color(0x1F000000);      // ~12% black outline
  static const Color lightBorderCrisp = Color(0xFFD6D6D6);
  static const Color lightText = Color(0xFF242424);
  static const Color lightTextSecondary = Color(0x99242424); // 60% opacity
  static const Color lightTextMuted = Color(0x66242424);     // 40% opacity

  // Window title button colors
  static const Color windowCloseHover = Color(0xFFE01B24);
  static const Color windowButtonDark = Color(0x24FFFFFF);
  static const Color windowButtonLight = Color(0x1F000000);
}

/// Libadwaita HIG Theme Extension providing easy access to official Adwaita tokens.
class LinuxAdwaitaTokens extends ThemeExtension<LinuxAdwaitaTokens> {
  final Color windowBg;
  final Color viewBg;
  final Color cardBg;
  final Color headerBarBg;
  final Color popoverBg;
  final Color border;
  final Color borderCrisp;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color success;
  final Color warning;
  final Color destructive;
  final double cardRadius;
  final double pillRadius;

  const LinuxAdwaitaTokens({
    required this.windowBg,
    required this.viewBg,
    required this.cardBg,
    required this.headerBarBg,
    required this.popoverBg,
    required this.border,
    required this.borderCrisp,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.success,
    required this.warning,
    required this.destructive,
    this.cardRadius = 12.0,
    this.pillRadius = 999.0,
  });

  static const LinuxAdwaitaTokens dark = LinuxAdwaitaTokens(
    windowBg: AdwaitaColors.darkWindowBg,
    viewBg: AdwaitaColors.darkViewBg,
    cardBg: AdwaitaColors.darkCardBg,
    headerBarBg: AdwaitaColors.darkHeaderBarBg,
    popoverBg: AdwaitaColors.darkPopoverBg,
    border: AdwaitaColors.darkBorder,
    borderCrisp: AdwaitaColors.darkBorderCrisp,
    textPrimary: AdwaitaColors.darkText,
    textSecondary: AdwaitaColors.darkTextSecondary,
    textMuted: AdwaitaColors.darkTextMuted,
    accent: AdwaitaColors.blue3,
    success: AdwaitaColors.green3,
    warning: AdwaitaColors.yellow3,
    destructive: AdwaitaColors.red1,
  );

  static const LinuxAdwaitaTokens light = LinuxAdwaitaTokens(
    windowBg: AdwaitaColors.lightWindowBg,
    viewBg: AdwaitaColors.lightViewBg,
    cardBg: AdwaitaColors.lightCardBg,
    headerBarBg: AdwaitaColors.lightHeaderBarBg,
    popoverBg: AdwaitaColors.lightPopoverBg,
    border: AdwaitaColors.lightBorder,
    borderCrisp: AdwaitaColors.lightBorderCrisp,
    textPrimary: AdwaitaColors.lightText,
    textSecondary: AdwaitaColors.lightTextSecondary,
    textMuted: AdwaitaColors.lightTextMuted,
    accent: AdwaitaColors.blue3,
    success: AdwaitaColors.green4,
    warning: AdwaitaColors.yellow4,
    destructive: AdwaitaColors.red3,
  );

  @override
  ThemeExtension<LinuxAdwaitaTokens> copyWith({
    Color? windowBg,
    Color? viewBg,
    Color? cardBg,
    Color? headerBarBg,
    Color? popoverBg,
    Color? border,
    Color? borderCrisp,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? success,
    Color? warning,
    Color? destructive,
    double? cardRadius,
    double? pillRadius,
  }) {
    return LinuxAdwaitaTokens(
      windowBg: windowBg ?? this.windowBg,
      viewBg: viewBg ?? this.viewBg,
      cardBg: cardBg ?? this.cardBg,
      headerBarBg: headerBarBg ?? this.headerBarBg,
      popoverBg: popoverBg ?? this.popoverBg,
      border: border ?? this.border,
      borderCrisp: borderCrisp ?? this.borderCrisp,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      destructive: destructive ?? this.destructive,
      cardRadius: cardRadius ?? this.cardRadius,
      pillRadius: pillRadius ?? this.pillRadius,
    );
  }

  @override
  ThemeExtension<LinuxAdwaitaTokens> lerp(
    covariant ThemeExtension<LinuxAdwaitaTokens>? other,
    double t,
  ) {
    if (other is! LinuxAdwaitaTokens) return this;
    return LinuxAdwaitaTokens(
      windowBg: Color.lerp(windowBg, other.windowBg, t)!,
      viewBg: Color.lerp(viewBg, other.viewBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      headerBarBg: Color.lerp(headerBarBg, other.headerBarBg, t)!,
      popoverBg: Color.lerp(popoverBg, other.popoverBg, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderCrisp: Color.lerp(borderCrisp, other.borderCrisp, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      pillRadius: pillRadius + (other.pillRadius - pillRadius) * t,
    );
  }
}

/// Official GNOME Cantarell / Ubuntu Typography builder.
class AdwaitaTypography {
  const AdwaitaTypography._();

  static TextStyle get cantarell => GoogleFonts.cantarell(
        textStyle: const TextStyle(
          fontFamily: 'Cantarell',
          fontFamilyFallback: ['Ubuntu', 'DejaVu Sans', 'sans-serif'],
        ),
      );

  static TextStyle get ubuntu => GoogleFonts.ubuntu(
        textStyle: const TextStyle(
          fontFamily: 'Ubuntu',
          fontFamilyFallback: ['Cantarell', 'sans-serif'],
        ),
      );

  static TextStyle get monospace => GoogleFonts.jetBrainsMono(
        textStyle: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontFamilyFallback: ['Ubuntu Mono', 'monospace'],
        ),
      );

  static TextTheme textTheme(Color textPrimary, Color textSecondary) {
    return TextTheme(
      // Window Title / Banner
      displaySmall: cantarell.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      // HeaderBar Title / Section Header
      titleLarge: cantarell.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: textPrimary,
      ),
      // Card / Group Title
      titleMedium: cantarell.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      // Preference Row Title
      titleSmall: cantarell.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      // Primary Body
      bodyLarge: cantarell.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textPrimary,
      ),
      // Secondary Description
      bodyMedium: cantarell.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: textSecondary,
      ),
      // Subtitles & Captions
      bodySmall: cantarell.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      // Button Labels
      labelLarge: cantarell.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      // Badges / Tags
      labelSmall: cantarell.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: textSecondary,
      ),
    );
  }
}

/// Linux Adwaita Theme Definition.
class LinuxAdwaitaTheme {
  const LinuxAdwaitaTheme._();

  static ThemeData get darkTheme {
    const tokens = LinuxAdwaitaTokens.dark;
    final textTheme = AdwaitaTypography.textTheme(
      tokens.textPrimary,
      tokens.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tokens.windowBg,
      extensions: const [tokens],
      colorScheme: ColorScheme.dark(
        primary: tokens.accent,
        onPrimary: Colors.white,
        surface: tokens.cardBg,
        onSurface: tokens.textPrimary,
        outline: tokens.borderCrisp,
        secondary: tokens.warning,
        error: tokens.destructive,
      ),
      textTheme: textTheme,
      cardTheme: CardTheme(
        color: tokens.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.popoverBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tokens.borderCrisp, width: 0.5),
        ),
        textStyle: AdwaitaTypography.cantarell.copyWith(
          fontSize: 11,
          color: tokens.textPrimary,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      iconTheme: IconThemeData(
        color: tokens.textPrimary,
        size: 18,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(tokens.borderCrisp),
        radius: const Radius.circular(tokens.pillRadius),
        thickness: MaterialStateProperty.all(5),
      ),
    );
  }

  static ThemeData get lightTheme {
    const tokens = LinuxAdwaitaTokens.light;
    final textTheme = AdwaitaTypography.textTheme(
      tokens.textPrimary,
      tokens.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tokens.windowBg,
      extensions: const [tokens],
      colorScheme: ColorScheme.light(
        primary: tokens.accent,
        onPrimary: Colors.white,
        surface: tokens.cardBg,
        onSurface: tokens.textPrimary,
        outline: tokens.borderCrisp,
        secondary: tokens.warning,
        error: tokens.destructive,
      ),
      textTheme: textTheme,
      cardTheme: CardTheme(
        color: tokens.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.popoverBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tokens.borderCrisp, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: AdwaitaTypography.cantarell.copyWith(
          fontSize: 11,
          color: tokens.textPrimary,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      iconTheme: IconThemeData(
        color: tokens.textPrimary,
        size: 18,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(tokens.borderCrisp),
        radius: const Radius.circular(tokens.pillRadius),
        thickness: MaterialStateProperty.all(5),
      ),
    );
  }
}

/// Convenience context extension for clean Adwaita token access.
extension AdwaitaContextX on BuildContext {
  LinuxAdwaitaTokens get adwaita {
    final tokens = Theme.of(this).extension<LinuxAdwaitaTokens>();
    if (tokens != null) return tokens;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? LinuxAdwaitaTokens.dark : LinuxAdwaitaTokens.light;
  }
}
