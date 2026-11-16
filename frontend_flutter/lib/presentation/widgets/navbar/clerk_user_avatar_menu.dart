import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../providers/auth_state_provider.dart';

/// Clerk User profile button and dropdown menu in the top bar.
class ClerkUserAvatarMenu extends ConsumerWidget {
  final VoidCallback? onOpenSettings;

  const ClerkUserAvatarMenu({super.key, this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.session;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: 'Clerk User Profile',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AppColors.zinc100 : AppColors.zinc900,
                ),
              ),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.zinc400 : AppColors.zinc500,
                ),
              ),
              if (user.isGithubConnected) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.link, size: 12, color: AppColors.emerald500),
                    const SizedBox(width: 4),
                    Text(
                      '@${user.githubUsername ?? "github"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.emerald500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: const Row(
            children: [
              Icon(Icons.tune, size: 16),
              SizedBox(width: 8),
              Text('Guardrails & LLMs', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 16, color: AppColors.rose500),
              const SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(fontSize: 12.5, color: AppColors.rose500),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'settings') {
          onOpenSettings?.call();
        } else if (value == 'signout') {
          ref.read(authStateProvider.notifier).signOut();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.indigo500.withOpacity(0.2),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo500,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.zinc500),
          ],
        ),
      ),
    );
  }
}
