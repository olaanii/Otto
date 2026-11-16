import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/platform/adaptive_shell_screen.dart';
import 'presentation/platform/platform_override_provider.dart';
import 'presentation/providers/auth_state_provider.dart';
import 'presentation/screens/clerk_sign_in_screen.dart';
import 'presentation/screens/desktop_shell_screen.dart';
import 'presentation/screens/hud_overlay_window.dart';
import 'presentation/screens/mobile_shell_screen.dart';
import 'presentation/screens/rebase_playground_screen.dart';

/// Main application widget with Clerk authentication gating and responsive multiplatform routing.
class OttoApp extends ConsumerWidget {
  const OttoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final platformOverride = ref.watch(platformOverrideProvider);

    return MaterialApp(
      title: 'Otto - Atomic PR & Git Stacking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(platform: platformOverride.effectiveTargetPlatform),
      darkTheme: AppTheme.darkTheme.copyWith(platform: platformOverride.effectiveTargetPlatform),
      themeMode: ThemeMode.system,
      routes: {
        '/hud': (_) => const HudOverlayWindow(),
        '/rebase': (_) => const RebasePlaygroundScreen(),
      },
      home: switch (authState.status) {
        AuthStatus.initial || AuthStatus.authenticating => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        AuthStatus.authenticated => const AdaptiveShellScreen(),
        AuthStatus.unauthenticated || AuthStatus.error => const ClerkSignInScreen(),
      },
    );
  }
}
