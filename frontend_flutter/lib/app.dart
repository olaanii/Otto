import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/platform/windows/windows_shell_screen.dart';
import 'presentation/providers/auth_state_provider.dart';
import 'presentation/screens/clerk_sign_in_screen.dart';
import 'presentation/screens/hud_overlay_window.dart';

/// Main Windows desktop application widget rendering the Windows 11 Fluent UI.
class OttoApp extends ConsumerWidget {
  const OttoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Otto - Atomic PR & Git Stacking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.windows),
      darkTheme: AppTheme.darkTheme.copyWith(platform: TargetPlatform.windows),
      themeMode: ThemeMode.dark,
      routes: {
        '/hud': (_) => const HudOverlayWindow(),
        '/sign-in': (_) => const ClerkSignInScreen(),
      },
      home: const WindowsShellScreen(),
    );
  }
}
