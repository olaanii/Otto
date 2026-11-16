import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/platform/window_manager_service.dart';
import '../../../core/theme/typography.dart';
import '../../providers/workspace_provider.dart';
import 'clerk_user_avatar_menu.dart';

/// Top application navigation bar providing window controls, branch context,
/// and GitHub stack sync status.
class GithubSyncNavbar extends ConsumerWidget {
  final VoidCallback? onOpenRebase;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleHud;

  const GithubSyncNavbar({
    super.key,
    this.onOpenRebase,
    this.onOpenSettings,
    this.onToggleHud,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wm = WindowManagerService.instance;

    return GestureDetector(
      onPanStart: (_) => wm.startDragging(),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            // Brand Logo & Title
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.indigo600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Otto',
                  style: AppTypography.uiFont.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Active Branch Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fork_right,
                    size: 13,
                    color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    workspace.currentBranch,
                    style: AppTypography.codeFont.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.zinc200 : AppColors.zinc800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Live Daemon Sync Indicator
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.emerald500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Daemon Connected',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.zinc400 : AppColors.zinc500,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // HUD Toggle button
            if (onToggleHud != null)
              IconButton(
                onPressed: onToggleHud,
                icon: const Icon(Icons.picture_in_picture_alt_outlined, size: 18),
                tooltip: 'Toggle Quick HUD Overlay (Ctrl+Shift+K)',
              ),

            // Rebase Canvas Shortcut
            if (onOpenRebase != null) ...[
              TextButton.icon(
                onPressed: onOpenRebase,
                icon: const Icon(Icons.swap_vert, size: 16),
                label: const Text('Rebase Stack', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
            ],

            // Push Stack to GitHub Button
            FilledButton.icon(
              onPressed: workspace.isLoading ? null : () => workspaceNotifier.pushStack(),
              icon: workspace.isLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload, size: 15),
              label: const Text('Push Stack', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),

            // Clerk User Menu
            ClerkUserAvatarMenu(onOpenSettings: onOpenSettings),

            // Frameless Window Controls on Desktop
            if (wm.isDesktop) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: wm.minimize,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.crop_square, size: 15),
                onPressed: wm.maximizeOrRestore,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: wm.close,
                visualDensity: VisualDensity.compact,
                hoverColor: AppColors.rose500.withOpacity(0.2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
