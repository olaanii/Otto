import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../domain/models/clerk_user_session.dart';

/// Renders the Google Antigravity identity & subscription card in Settings.
class AntigravityIdentityTab extends StatelessWidget {
  final ClerkUserSession? user;
  final bool isConnected, isSyncing, isDark;
  final Map<String, dynamic>? antigravityData;
  final VoidCallback onSync, onReauthenticate;

  const AntigravityIdentityTab({
    super.key, required this.user, required this.isConnected, this.antigravityData,
    required this.isSyncing, required this.onSync, required this.onReauthenticate, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? (antigravityData?['user']?['email'] as String? ?? 'olaaniishaambal@gmail.com');
    final name = user?.fullName ?? (antigravityData?['user']?['name'] as String? ?? 'Olani Shambel');
    final model = antigravityData?['model'] as String? ?? 'Gemini 3.8 Flash (High)';

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Google Antigravity Identity & Subscription',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.zinc200 : AppColors.zinc800)),
        const SizedBox(height: 6),
        Text('Otto harnesses your Google Antigravity Pro Plan subscription via Clerk OAuth, guaranteeing \$0 extra token fees.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.zinc400 : AppColors.zinc600)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E241E) : const Color(0xFFF1F8F1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isConnected ? const Color(0xFF2E7D32) : AppColors.borderDark, width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(4)),
                    child: Text(isConnected ? 'CONNECTED' : 'STANDBY', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF81C784)))),
                ]),
                Text(email, style: TextStyle(fontSize: 12, color: isDark ? AppColors.zinc400 : AppColors.zinc600)),
              ])),
            ]),
            const Divider(height: 24),
            _row('Subscription Plan', 'Google AI Pro Plan (\$0 token fees)', isDark),
            const SizedBox(height: 6),
            _row('Autonomous Model', model, isDark),
            const SizedBox(height: 6),
            _row('Security Standard', 'RFC 8252 Loopback Browser OAuth (Clerk)', isDark),
            const SizedBox(height: 16),
            Row(children: [
              FilledButton.icon(onPressed: isSyncing ? null : onSync, icon: const Icon(Icons.sync_rounded, size: 16),
                label: Text(isSyncing ? 'Syncing...' : 'Sync Subscription'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32))),
              const SizedBox(width: 10),
              OutlinedButton.icon(onPressed: onReauthenticate, icon: const Icon(Icons.login_rounded, size: 16), label: const Text('Re-authenticate with Google')),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _row(String label, String value, bool isDark) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.zinc400 : AppColors.zinc600)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.zinc200 : AppColors.zinc800)),
        ],
      );
}
