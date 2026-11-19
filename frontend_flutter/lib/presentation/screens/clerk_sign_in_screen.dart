import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/typography.dart';
import '../providers/auth_state_provider.dart';

/// Otto sign-in screen â€” Production RFC 8252 Loopback Browser OAuth (Google & GitHub).
class ClerkSignInScreen extends ConsumerStatefulWidget {
  const ClerkSignInScreen({super.key});

  @override
  ConsumerState<ClerkSignInScreen> createState() => _ClerkSignInScreenState();
}

class _ClerkSignInScreenState extends ConsumerState<ClerkSignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isWaitingForBrowser = false;
  bool _showManualEntry = false;
  Timer? _authPollTimer;

  static const String _clerkAuthUrl =
      'https://tough-escargot-7465.accounts.dev/sign-in?redirect_url=http://localhost:3000/auth/callback';

  @override
  void dispose() {
    _authPollTimer?.cancel();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openExternalBrowser(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('Error launching external browser: $e');
    }
  }

  /// Triggers RFC 8252 Loopback OAuth in system default browser
  Future<void> _handleBrowserOAuthSignIn() async {
    setState(() {
      _isLoading = true;
      _isWaitingForBrowser = true;
    });

    await _openExternalBrowser(_clerkAuthUrl);

    // Poll local daemon session handshake every 1.5s
    _authPollTimer?.cancel();
    _authPollTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      await ref.read(authStateProvider.notifier).checkActiveSession();
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isWaitingForBrowser = false;
          });
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    });

    // Auto-timeout after 90 seconds
    Future.delayed(const Duration(seconds: 90), () {
      if (mounted && _isWaitingForBrowser) {
        _authPollTimer?.cancel();
        setState(() {
          _isLoading = false;
          _isWaitingForBrowser = false;
        });
      }
    });
  }

  void _cancelBrowserWait() {
    _authPollTimer?.cancel();
    setState(() {
      _isLoading = false;
      _isWaitingForBrowser = false;
    });
  }

  /// Manual sign-in using custom entered email and name.
  Future<void> _handleCustomSignIn() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email address to connect.'),
          backgroundColor: AppColors.rose500,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final ticket = '$email|$name|manual';
    final success = await ref.read(authStateProvider.notifier).signInWithTicket(ticket);
    if (mounted) setState(() => _isLoading = false);

    if (success && mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else if (!success && mounted) {
      final err = ref.read(authStateProvider).errorMessage ?? 'Sign in failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.rose500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.paperLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.indigo600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle
                Text(
                  'Welcome to Otto',
                  textAlign: TextAlign.center,
                  style: AppTypography.uiFont.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Production Atomic PR Slicing & Git Stacking Client',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.zinc400 : AppColors.zinc500,
                  ),
                ),
                const SizedBox(height: 28),

                if (_isWaitingForBrowser) ...[
                  // Waiting for browser handshake state
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4285F4)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Waiting for browser authentication...',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4285F4)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please complete sign-in in your default browser. Otto will automatically sync once authenticated.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: _cancelBrowserWait,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: const Text('Cancel / Try Another Method', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Primary Google Sign-In Button
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _handleBrowserOAuthSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 1,
                    ),
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary GitHub Sign-In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleBrowserOAuthSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
                        width: 1,
                      ),
                    ),
                    icon: Icon(Icons.code_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
                    label: const Text(
                      'Sign in with GitHub',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider / Manual Entry Toggle
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextButton(
                          onPressed: () => setState(() => _showManualEntry = !_showManualEntry),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showManualEntry ? 'Hide manual entry' : 'Or enter email manually',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                                ),
                              ),
                              Icon(
                                _showManualEntry ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                size: 16,
                                color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ],
                  ),

                  // Expandable Optional Manual Fields
                  if (_showManualEntry) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.zinc300 : AppColors.zinc700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'developer@example.com',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.zinc600 : AppColors.zinc400,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Display Name (Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.zinc300 : AppColors.zinc700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Jane Doe',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.zinc600 : AppColors.zinc400,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : _handleCustomSignIn,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.indigo600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Connect Account',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ],

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Connected to Otto daemon at localhost:3000 (zero token fees)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.zinc500 : AppColors.zinc400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
