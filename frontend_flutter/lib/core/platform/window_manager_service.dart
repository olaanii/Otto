import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Platform desktop window manager controlling frameless window decoration,
/// HUD popover geometry, and titlebar controls.
class WindowManagerService {
  WindowManagerService._();
  static final WindowManagerService instance = WindowManagerService._();

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> initializeDesktopWindow() async {
    if (!isDesktop) return;

    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1380, 880),
        minimumSize: Size(960, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden, // Frameless window for custom Moonjar titlebar
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('WindowManager initialization skipped or failed: $e');
    }
  }

  /// Reconfigures window into a floating HUD overlay (for quick commit/slicing).
  Future<void> setHudOverlayMode({required bool enabled}) async {
    if (!isDesktop) return;

    try {
      if (enabled) {
        await windowManager.setSize(const Size(580, 480));
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setAlignment(Alignment.topRight);
      } else {
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setSize(const Size(1380, 880));
        await windowManager.center();
      }
    } catch (e) {
      debugPrint('Failed to set HUD overlay mode: $e');
    }
  }

  Future<void> minimize() async {
    if (isDesktop) await windowManager.minimize();
  }

  Future<void> maximizeOrRestore() async {
    if (isDesktop) {
      final isMax = await windowManager.isMaximized();
      if (isMax) {
        await windowManager.restore();
      } else {
        await windowManager.maximize();
      }
    }
  }

  Future<void> close() async {
    if (isDesktop) await windowManager.close();
  }

  Future<void> startDragging() async {
    if (isDesktop) await windowManager.startDragging();
  }
}
