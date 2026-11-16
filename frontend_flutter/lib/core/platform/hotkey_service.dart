import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// Global hotkey service listening for desktop keyboard shortcuts
/// (e.g. `Ctrl+Shift+K` / `Cmd+Shift+K`) to toggle the Otto HUD overlay.
class HotkeyService {
  HotkeyService._();
  static final HotkeyService instance = HotkeyService._();

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  HotKey? _hudHotKey;
  VoidCallback? _onHudTriggered;

  Future<void> initialize({required VoidCallback onHudToggle}) async {
    if (!isDesktop) return;

    _onHudTriggered = onHudToggle;

    try {
      await hotKeyManager.unregisterAll();

      final modifier = Platform.isMacOS ? KeyModifier.meta : KeyModifier.control;
      _hudHotKey = HotKey(
        KeyCode.keyK,
        modifiers: [modifier, KeyModifier.shift],
        scope: HotKeyScope.system,
      );

      await hotKeyManager.register(
        _hudHotKey!,
        keyDownHandler: (hotKey) {
          _onHudTriggered?.call();
        },
      );
    } catch (e) {
      debugPrint('Hotkey registration failure: $e');
    }
  }

  Future<void> dispose() async {
    if (isDesktop && _hudHotKey != null) {
      try {
        await hotKeyManager.unregister(_hudHotKey!);
      } catch (_) {}
    }
  }
}
