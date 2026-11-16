import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic colors for Git stacking and Otto guardrail workflows in Material 3.
class GitM3SemanticColors extends ThemeExtension<GitM3SemanticColors> {
  final Color gitAdded;
  final Color onGitAdded;
  final Color gitAddedContainer;
  final Color onGitAddedContainer;

  final Color gitRemoved;
  final Color onGitRemoved;
  final Color gitRemovedContainer;
  final Color onGitRemovedContainer;

  final Color gitModified;
  final Color onGitModified;
  final Color gitModifiedContainer;
  final Color onGitModifiedContainer;

  final Color complianceHigh;
  final Color complianceMedium;
  final Color complianceLow;

  const GitM3SemanticColors({
    required this.gitAdded,
    required this.onGitAdded,
    required this.gitAddedContainer,
    required this.onGitAddedContainer,
    required this.gitRemoved,
    required this.onGitRemoved,
    required this.gitRemovedContainer,
    required this.onGitRemovedContainer,
    required this.gitModified,
    required this.onGitModified,
    required this.gitModifiedContainer,
    required this.onGitModifiedContainer,
    required this.complianceHigh,
    required this.complianceMedium,
    required this.complianceLow,
  });

  static const light = GitM3SemanticColors(
    gitAdded: Color(0xFF137333),
    onGitAdded: Colors.white,
    gitAddedContainer: Color(0xFFC4EED0),
    onGitAddedContainer: Color(0xFF072711),
    gitRemoved: Color(0xFFC5221F),
    onGitRemoved: Colors.white,
    gitRemovedContainer: Color(0xFFF9DEDC),
    onGitRemovedContainer: Color(0xFF410E0B),
    gitModified: Color(0xFFB06000),
    onGitModified: Colors.white,
    gitModifiedContainer: Color(0xFFFFDDB3),
    onGitModifiedContainer: Color(0xFF2A1700),
    complianceHigh: Color(0xFF137333),
    complianceMedium: Color(0xFFB06000),
    complianceLow: Color(0xFFC5221F),
  );

  static const dark = GitM3SemanticColors(
    gitAdded: Color(0xFF81C995),
    onGitAdded: Color(0xFF003915),
    gitAddedContainer: Color(0xFF0A5323),
    onGitAddedContainer: Color(0xFFA8E6B8),
    gitRemoved: Color(0xFFF28B82),
    onGitRemoved: Color(0xFF601410),
    gitRemovedContainer: Color(0xFF8C1D18),
    onGitRemovedContainer: Color(0xFFF9DEDC),
    gitModified: Color(0xFFFDD663),
    onGitModified: Color(0xFF432C00),
    gitModifiedContainer: Color(0xFF604100),
    onGitModifiedContainer: Color(0xFFFFE08B),
    complianceHigh: Color(0xFF81C995),
    complianceMedium: Color(0xFFFDD663),
    complianceLow: Color(0xFFF28B82),
  );

  @override
  ThemeExtension<GitM3SemanticColors> copyWith({
    Color? gitAdded,
    Color? onGitAdded,
    Color? gitAddedContainer,
    Color? onGitAddedContainer,
    Color? gitRemoved,
    Color? onGitRemoved,
    Color? gitRemovedContainer,
    Color? onGitRemovedContainer,
    Color? gitModified,
    Color? onGitModified,
    Color? gitModifiedContainer,
    Color? onGitModifiedContainer,
    Color? complianceHigh,
    Color? complianceMedium,
    Color? complianceLow,
  }) {
    return GitM3SemanticColors(
      gitAdded: gitAdded ?? this.gitAdded,
      onGitAdded: onGitAdded ?? this.onGitAdded,
      gitAddedContainer: gitAddedContainer ?? this.gitAddedContainer,
      onGitAddedContainer: onGitAddedContainer ?? this.onGitAddedContainer,
      gitRemoved: gitRemoved ?? this.gitRemoved,
      onGitRemoved: onGitRemoved ?? this.onGitRemoved,
      gitRemovedContainer: gitRemovedContainer ?? this.gitRemovedContainer,
      onGitRemovedContainer: onGitRemovedContainer ?? this.onGitRemovedContainer,
      gitModified: gitModified ?? this.gitModified,
      onGitModified: onGitModified ?? this.onGitModified,
      gitModifiedContainer: gitModifiedContainer ?? this.gitModifiedContainer,
      onGitModifiedContainer: onGitModifiedContainer ?? this.onGitModifiedContainer,
      complianceHigh: complianceHigh ?? this.complianceHigh,
      complianceMedium: complianceMedium ?? this.complianceMedium,
      complianceLow: complianceLow ?? this.complianceLow,
    );
  }

  @override
  ThemeExtension<GitM3SemanticColors> lerp(
    covariant ThemeExtension<GitM3SemanticColors>? other,
    double t,
  ) {
    if (other is! GitM3SemanticColors) return this;
    return GitM3SemanticColors(
      gitAdded: Color.lerp(gitAdded, other.gitAdded, t)!,
      onGitAdded: Color.lerp(onGitAdded, other.onGitAdded, t)!,
      gitAddedContainer: Color.lerp(gitAddedContainer, other.gitAddedContainer, t)!,
      onGitAddedContainer: Color.lerp(onGitAddedContainer, other.onGitAddedContainer, t)!,
      gitRemoved: Color.lerp(gitRemoved, other.gitRemoved, t)!,
      onGitRemoved: Color.lerp(onGitRemoved, other.onGitRemoved, t)!,
      gitRemovedContainer: Color.lerp(gitRemovedContainer, other.gitRemovedContainer, t)!,
      onGitRemovedContainer: Color.lerp(onGitRemovedContainer, other.onGitRemovedContainer, t)!,
      gitModified: Color.lerp(gitModified, other.gitModified, t)!,
      onGitModified: Color.lerp(onGitModified, other.onGitModified, t)!,
      gitModifiedContainer: Color.lerp(gitModifiedContainer, other.gitModifiedContainer, t)!,
      onGitModifiedContainer: Color.lerp(onGitModifiedContainer, other.onGitModifiedContainer, t)!,
      complianceHigh: Color.lerp(complianceHigh, other.complianceHigh, t)!,
      complianceMedium: Color.lerp(complianceMedium, other.complianceMedium, t)!,
      complianceLow: Color.lerp(complianceLow, other.complianceLow, t)!,
    );
  }
}

/// Official Android Material Design 3 (Material You / M3) theme configuration for Otto.
///
/// Implements:
/// - Dynamic Color Schemes generated from a brand or system wallpaper seed (`ColorScheme.fromSeed`)
/// - Material 3 tonal elevation and surface tint system
/// - Official Google Roboto typography scale
/// - Custom component theming: M3 Cards with 16px corner radii, NavigationBar with stadium pill indicators,
///   M3 ModalBottomSheet with 28px top corner radius and drag handle, and extended FloatingActionButton.
class AndroidMaterial3Theme {
  const AndroidMaterial3Theme._();

  /// Default Otto Android seed color (harmonious deep indigo/violet).
  static const Color defaultSeedColor = Color(0xFF4F46E5);

  /// Secondary seed for Otto developer tools (teal / cyan tone).
  static const Color secondarySeedColor = Color(0xFF00677D);

  /// Builds the Google Roboto Material 3 Typography Scale.
  static TextTheme buildRobotoTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.robotoTextTheme();

    return base.copyWith(
      displayLarge: GoogleFonts.roboto(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.roboto(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.roboto(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.roboto(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Roboto Mono text style helper for git commit hashes, branch chips, and diffs.
  static TextStyle monoStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Creates a Light Material Design 3 ThemeData.
  static ThemeData light({
    Color seedColor = defaultSeedColor,
    ColorScheme? dynamicColorScheme,
  }) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        );

    return _buildTheme(colorScheme, Brightness.light, GitM3SemanticColors.light);
  }

  /// Creates a Dark Material Design 3 ThemeData.
  static ThemeData dark({
    Color seedColor = defaultSeedColor,
    ColorScheme? dynamicColorScheme,
  }) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );

    return _buildTheme(colorScheme, Brightness.dark, GitM3SemanticColors.dark);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    Brightness brightness,
    GitM3SemanticColors semanticColors,
  ) {
    final textTheme = buildRobotoTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // TopAppBar Theme with M3 scroll-under tonal elevation
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),

      // M3 Cards with 16px corner radii as required by specifications
      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Bottom NavigationBar Theme with stadium pill indicators
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // NavigationRail for tablets and foldables
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        useIndicator: true,
        labelType: NavigationRailLabelType.all,
        groupAlignment: -0.2,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),

      // Extended Floating Action Button Theme with 16px corner radius
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        hoverElevation: 4,
        focusElevation: 3,
        highlightElevation: 6,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

      // Modal Bottom Sheet Theme with 28px top corner radius & drag handle
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 1,
        modalElevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
        dragHandleSize: const Size(32, 4),
        clipBehavior: Clip.antiAlias,
      ),

      // Dialog Theme with 28px corners
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 3,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),

      // SearchBar Theme with stadium pill
      searchBarTheme: SearchBarThemeData(
        backgroundColor: MaterialStatePropertyAll(colorScheme.surfaceContainerHigh),
        surfaceTintColor: MaterialStatePropertyAll(colorScheme.surfaceTint),
        elevation: const MaterialStatePropertyAll(1),
        shape: const MaterialStatePropertyAll(StadiumBorder()),
        textStyle: MaterialStatePropertyAll(
          textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        ),
        hintStyle: MaterialStatePropertyAll(
          textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        padding: const MaterialStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
      ),

      // Chips with 8px rounded corners
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        labelStyle: textTheme.labelMedium,
        iconTheme: IconThemeData(
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      extensions: [semanticColors],
    );
  }
}
