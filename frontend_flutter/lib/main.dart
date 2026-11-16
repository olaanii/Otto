import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/platform/window_manager_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop window customizations (frameless design for Moonjar custom titlebar)
  await WindowManagerService.instance.initializeDesktopWindow();

  runApp(
    const ProviderScope(
      child: OttoApp(),
    ),
  );
}
