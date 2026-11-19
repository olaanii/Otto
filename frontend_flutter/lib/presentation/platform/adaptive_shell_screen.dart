import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import 'android/android_shell_screen.dart';
import 'ios_shell_screen.dart';
import 'linux_shell_screen.dart';
import 'macos_shell_screen.dart';
import 'platform_override_provider.dart';
import 'windows_shell_screen.dart';

/// Master Adaptive Shell Screen that detects host OS or developer preview override,
/// seamlessly rendering the native platform shell for:
/// - Windows Fluent Design ([WindowsShellScreen])
/// - macOS Human Interface Guidelines ([MacosShellScreen])
/// - Linux GNOME Libadwaita ([LinuxShellScreen])
/// - iOS Cupertino ([IosShellScreen])
/// - Android Material 3 ([AndroidShellScreen])
///
/// Features a sleek, non-intrusive floating Platform Preview switcher pill so developers
/// can live-toggle between all 5 native designs on any device.
class AdaptiveShellScreen extends ConsumerWidget {
  const AdaptiveShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrideState = ref.watch(platformOverrideProvider);
    final effectivePlatform = overrideState.effectiveTargetPlatform;

    // Resolve which native platform shell to render
    final Widget platformShell = switch (effectivePlatform) {
      TargetPlatform.windows => const WindowsShellScreen(),
      TargetPlatform.macOS => const MacosShellScreen(),
      TargetPlatform.linux => const LinuxShellScreen(),
      TargetPlatform.iOS => const CupertinoTheme(
          data: CupertinoThemeData(),
          child: IosShellScreen(),
        ),
      TargetPlatform.android || TargetPlatform.fuchsia => const AndroidShellScreen(),
    };

    return Scaffold(
      body: Stack(
        children: [
          // 1. Native Platform Shell
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(overrideState.effectiveTargetPlatform),
                child: platformShell,
              ),
            ),
          ),

          // 2. Sleek Floating Platform Preview Switcher Pill
          const Positioned(
            bottom: 16,
            right: 18,
            child: _PlatformPreviewSwitcherPill(),
          ),
        ],
      ),
    );
  }
}

/// Floating Platform Preview Switcher Pill widget.
/// Offers developers an instant, non-intrusive way to preview and test all 5 native designs.
class _PlatformPreviewSwitcherPill extends ConsumerStatefulWidget {
  const _PlatformPreviewSwitcherPill();

  @override
  ConsumerState<_PlatformPreviewSwitcherPill> createState() => _PlatformPreviewSwitcherPillState();
}

class _PlatformPreviewSwitcherPillState extends ConsumerState<_PlatformPreviewSwitcherPill> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final overrideState = ref.watch(platformOverrideProvider);
    final notifier = ref.read(platformOverrideProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pillBg = isDark
        ? const Color(0xE618181B) // zinc 900 with 90% opacity
        : const Color(0xF2FFFFFF); // white with 95% opacity
    final pillBorder = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: pillBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expand / Collapse Pill Trigger
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPlatformGlyph(overrideState.effectiveTargetPlatform, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        overrideState.isOverridden
                            ? overrideState.overrideOption.shortName
                            : 'Auto (${_shortTargetName(defaultTargetPlatform)})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : AppColors.zinc900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _isExpanded ? 0.5 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Platform Preview Options
              if (_isExpanded) ...[
                Container(
                  height: 18,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: pillBorder,
                ),

                // 1. Auto Host Detect Button
                _buildPlatformButton(
                  icon: Icons.devices,
                  label: 'Auto',
                  tooltip: 'Auto Detect Host (${_shortTargetName(defaultTargetPlatform)})',
                  isSelected: overrideState.overrideOption == PlatformOverrideOption.auto,
                  onTap: () {
                    notifier.resetToAuto();
                    setState(() => _isExpanded = false);
                  },
                  isDark: isDark,
                ),

                // 2. Windows Fluent
                _buildPlatformButton(
                  icon: Icons.window,
                  label: 'Windows',
                  tooltip: 'Windows 11 Fluent Design',
                  isSelected: overrideState.overrideOption == PlatformOverrideOption.windows,
                  onTap: () {
                    notifier.setPlatform(PlatformOverrideOption.windows);
                    setState(() => _isExpanded = false);
                  },
                  isDark: isDark,
                  accentColor: const Color(0xFF0078D4),
                ),

                // 3. macOS HIG
                _buildPlatformButton(
                  icon: Icons.apple,
                  label: 'macOS',
                  tooltip: 'macOS Human Interface Guidelines',
                  isSelected: overrideState.overrideOption == PlatformOverrideOption.macos,
                  onTap: () {
                    notifier.setPlatform(PlatformOverrideOption.macos);
                    setState(() => _isExpanded = false);
                  },
                  isDark: isDark,
                  accentColor: const Color(0xFF007AFF),
                ),

                // 4. Linux Adwaita
                _buildPlatformButton(
                  icon: Icons.terminal,
                  label: 'Linux',
                  tooltip: 'Linux GNOME Libadwaita',
                  isSelected: overrideState.overrideOption == PlatformOverrideOption.linux,
                  onTap: () {
                    notifier.setPlatform(PlatformOverrideOption.linux);
                    setState(() => _isExpanded = false);
                  },
                  isDark: isDark,
                  accentColor: const Color(0xFF3584E4),
                ),

                // 5. iOS Cupertino
                _buildPlatformButton(
                  icon: Icons.phone_iphone,
                  label: 'iOS',
                  tooltip: 'iOS 17/18 Cupertino Design',
                  isSelected: overrideState.overrideOption == PlatformOverrideOption.ios,
                  onTap: () {
                    notifier.setPlatform(PlatformOverrideOption.ios);
                    setState(() => _isExpanded = false);
                  },
                  isDark: isDark,
                  accentColor: const Color(0xFF34C759),
                ),

                // 6. Android Material 3
                _buildPlatformButton(
                  icon: Icons.android,
                  label: 'Android',
                  tooltip: 'Android Material 3 (Material You)',
                  isSelected: overrideState.overrideOption == PlatformOverrideOption.android,
                  onTap: () {
                    notifier.setPlatform(PlatformOverrideOption.android);
                    setState(() => _isExpanded = false);
                  },
                  isDark: isDark,
                  accentColor: const Color(0xFF6750A4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? accentColor,
  }) {
    final activeColor = accentColor ?? AppColors.indigo500;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: activeColor.withOpacity(0.6), width: 1) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? activeColor
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformGlyph(TargetPlatform platform, {double size = 16}) {
    final iconData = switch (platform) {
      TargetPlatform.windows => Icons.window,
      TargetPlatform.macOS => Icons.apple,
      TargetPlatform.linux => Icons.terminal,
      TargetPlatform.iOS => Icons.phone_iphone,
      TargetPlatform.android || TargetPlatform.fuchsia => Icons.android,
    };

    final color = switch (platform) {
      TargetPlatform.windows => const Color(0xFF0078D4),
      TargetPlatform.macOS => const Color(0xFF007AFF),
      TargetPlatform.linux => const Color(0xFF3584E4),
      TargetPlatform.iOS => const Color(0xFF34C759),
      TargetPlatform.android || TargetPlatform.fuchsia => const Color(0xFF6750A4),
    };

    return Icon(iconData, size: size, color: color);
  }

  String _shortTargetName(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}
