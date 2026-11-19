import 'package:flutter/material.dart';

/// Moonjar & Apple inspired design system palette.
/// Provides refined zinc, amber, emerald, indigo, and warm paper tones.
class AppColors {
  const AppColors._();

  // Primary backgrounds & surfaces
  static const Color paperLight = Color(0xFFFAF8F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF4F3EF);
  static const Color borderLight = Color(0xFFE5E2DC);

  static const Color backgroundDark = Color(0xFF0D0E11);
  static const Color surfaceDark = Color(0xFF14161C);
  static const Color cardDark = Color(0xFF1C1F26);
  static const Color borderDark = Color(0xFF282C37);

  // Zinc shades for neutral typography and borders
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // Accent Colors: Indigo (primary action), Amber (warning / in-progress), Emerald (success / git added)
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo950 = Color(0xFF1E1B4B);

  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);

  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);

  // Diff Rendering Specific Colors
  static const Color diffAddedBgLight = Color(0xFFE6F4EA);
  static const Color diffAddedLineLight = Color(0xFF137333);
  static const Color diffAddedBgDark = Color(0x2810B981);
  static const Color diffAddedLineDark = Color(0xFF34D399);

  static const Color diffRemovedBgLight = Color(0xFFFCE8E6);
  static const Color diffRemovedLineLight = Color(0xFFC5221F);
  static const Color diffRemovedBgDark = Color(0x28F43F5E);
  static const Color diffRemovedLineDark = Color(0xFFFB7185);

  static const Color diffHunkHeaderBgLight = Color(0xFFF1F3F4);
  static const Color diffHunkHeaderDark = Color(0xFF1F232D);

  // Glassmorphic HUD overlay
  static const Color hudGlassLight = Color(0xD9FAF8F5);
  static const Color hudGlassDark = Color(0xE614161C);
}
