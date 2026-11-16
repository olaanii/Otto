import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available platform options for runtime design simulation.
enum PlatformOverrideOption {
  auto,
  windows,
  macos,
  linux,
  ios,
  android;

  String get displayName {
    return switch (this) {
      PlatformOverrideOption.auto => 'Auto Detect',
      PlatformOverrideOption.windows => 'Windows (Fluent)',
      PlatformOverrideOption.macos => 'macOS (HIG)',
      PlatformOverrideOption.linux => 'Linux (Adwaita)',
      PlatformOverrideOption.ios => 'iOS (Cupertino)',
      PlatformOverrideOption.android => 'Android (Material 3)',
    };
  }

  String get shortName {
    return switch (this) {
      PlatformOverrideOption.auto => 'Auto',
      PlatformOverrideOption.windows => 'Windows',
      PlatformOverrideOption.macos => 'macOS',
      PlatformOverrideOption.linux => 'Linux',
      PlatformOverrideOption.ios => 'iOS',
      PlatformOverrideOption.android => 'Android',
    };
  }

  String get designLanguage {
    return switch (this) {
      PlatformOverrideOption.auto => 'Native Host OS',
      PlatformOverrideOption.windows => 'Fluent Design System',
      PlatformOverrideOption.macos => 'Human Interface Guidelines',
      PlatformOverrideOption.linux => 'GNOME Adwaita',
      PlatformOverrideOption.ios => 'Cupertino Design',
      PlatformOverrideOption.android => 'Material You (M3)',
    };
  }
}

/// Immutable state containing active platform override and resolved target platform.
@immutable
class PlatformOverrideState {
  final PlatformOverrideOption overrideOption;

  const PlatformOverrideState({
    this.overrideOption = PlatformOverrideOption.auto,
  });

  /// The effective target platform: resolved from the developer override,
  /// or falling back to [defaultTargetPlatform] when [PlatformOverrideOption.auto] is selected.
  TargetPlatform get effectiveTargetPlatform {
    return switch (overrideOption) {
      PlatformOverrideOption.auto => defaultTargetPlatform,
      PlatformOverrideOption.windows => TargetPlatform.windows,
      PlatformOverrideOption.macos => TargetPlatform.macOS,
      PlatformOverrideOption.linux => TargetPlatform.linux,
      PlatformOverrideOption.ios => TargetPlatform.iOS,
      PlatformOverrideOption.android => TargetPlatform.android,
    };
  }

  /// True if the developer explicitly picked a preview platform rather than host OS auto-detection.
  bool get isOverridden => overrideOption != PlatformOverrideOption.auto;

  /// True if the effective target platform is a desktop environment (Windows, macOS, Linux).
  bool get isDesktop =>
      effectiveTargetPlatform == TargetPlatform.windows ||
      effectiveTargetPlatform == TargetPlatform.macOS ||
      effectiveTargetPlatform == TargetPlatform.linux;

  /// True if the effective target platform is a mobile environment (iOS, Android).
  bool get isMobile =>
      effectiveTargetPlatform == TargetPlatform.iOS ||
      effectiveTargetPlatform == TargetPlatform.android;

  /// Human-readable title of the active platform.
  String get activeTitle => isOverridden
      ? '${overrideOption.displayName} [Preview]'
      : 'Auto (${_targetPlatformName(defaultTargetPlatform)})';

  /// Human-friendly name of any [TargetPlatform].
  static String _targetPlatformName(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  PlatformOverrideState copyWith({
    PlatformOverrideOption? overrideOption,
  }) {
    return PlatformOverrideState(
      overrideOption: overrideOption ?? this.overrideOption,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformOverrideState &&
          runtimeType == other.runtimeType &&
          overrideOption == other.overrideOption;

  @override
  int get hashCode => overrideOption.hashCode;
}

/// Riverpod StateNotifier controlling the live platform override.
class PlatformOverrideNotifier extends StateNotifier<PlatformOverrideState> {
  PlatformOverrideNotifier() : super(const PlatformOverrideState());

  /// Sets the active platform preview.
  void setPlatform(PlatformOverrideOption option) {
    state = state.copyWith(overrideOption: option);
  }

  /// Sets by [TargetPlatform].
  void setTargetPlatform(TargetPlatform platform) {
    final option = switch (platform) {
      TargetPlatform.windows => PlatformOverrideOption.windows,
      TargetPlatform.macOS => PlatformOverrideOption.macos,
      TargetPlatform.linux => PlatformOverrideOption.linux,
      TargetPlatform.iOS => PlatformOverrideOption.ios,
      TargetPlatform.android => PlatformOverrideOption.android,
      _ => PlatformOverrideOption.auto,
    };
    state = state.copyWith(overrideOption: option);
  }

  /// Resets platform override back to auto-detection of the host operating system.
  void resetToAuto() {
    state = state.copyWith(overrideOption: PlatformOverrideOption.auto);
  }
}

/// Global provider for platform override state across the entire Flutter application.
final platformOverrideProvider =
    StateNotifierProvider<PlatformOverrideNotifier, PlatformOverrideState>((ref) {
  return PlatformOverrideNotifier();
});
