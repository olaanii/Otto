import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/platform/window_manager_service.dart';

Future<void> _ensureDaemonRunning() async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 400);
    final req = await client.getUrl(Uri.parse('http://localhost:3000/api/antigravity/status'));
    final resp = await req.close();
    if (resp.statusCode == 200) return;
  } catch (_) {}

  final candidates = [
    r'C:\Users\olani\Desktop\olani\Otto\Otto.exe',
    r'..\..\..\..\Otto.exe',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) {
      try {
        await Process.start(
          path,
          ['--daemon-only'],
          mode: ProcessStartMode.detached,
          workingDirectory: File(path).parent.path,
        );
        break;
      } catch (_) {}
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _ensureDaemonRunning().ignore();

  // Initialize desktop window customizations (frameless design for Moonjar custom titlebar)
  await WindowManagerService.instance.initializeDesktopWindow();

  runApp(
    const ProviderScope(
      child: OttoApp(),
    ),
  );
}
