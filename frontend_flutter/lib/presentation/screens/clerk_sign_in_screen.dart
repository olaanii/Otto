import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/typography.dart';
import '../providers/auth_state_provider.dart';

/// Moonjar-style sleek Clerk sign-in screen.
class ClerkSignInScreen extends ConsumerStatefulWidget {
  const ClerkSignInScreen({super.key});

  @override
  ConsumerState<ClerkSignInScreen> createState() => _ClerkSignInScreenState();
}

class _ClerkSignInScreenState extends ConsumerState<ClerkSignInScreen> {
  final TextEditingController _ticketController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final ticket = _ticketController.text.trim();
    if (ticket.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).signInWithTicket(ticket);
    if (mounted) setState(() => _isLoading = false);

    if (!success && mounted) {
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
            constraints: const BoxConstraints(maxWidth: 420),
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
                  'Atomic PR Slicing & Git Stacking Client',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.zinc400 : AppColors.zinc500,
                  ),
                ),
                const SizedBox(height: 28),

                // Clerk Ticket / Session Input
                Text(
                  'Clerk Auth Ticket / Dev Session Token',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.zinc300 : AppColors.zinc700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _ticketController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'clerk_ticket_...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.zinc600 : AppColors.zinc400,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleSignIn(),
                ),
                const SizedBox(height: 18),

                // Sign In Button
                FilledButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.indigo600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Authenticate with Clerk',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 16),

                // Quick Demo Auth
                OutlinedButton(
                  onPressed: () {
                    _ticketController.text = 'demo_clerk_session_${DateTime.now().millisecondsSinceEpoch}';
                    _handleSignIn();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Quick Demo Sign-In',
                    style: TextStyle(fontSize: 12.5),
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
