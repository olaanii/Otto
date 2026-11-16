import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/platform/window_manager_service.dart';
import '../../../core/theme/typography.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/hotkey_hud_provider.dart';
import '../../providers/workspace_provider.dart';
import 'quick_commit_strip.dart';

/// Compact floating popover HUD displayed when `Ctrl+Shift+K` is triggered.
class FloatingHudCard extends ConsumerWidget {
  const FloatingHudCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hudState = ref.watch(hotkeyHudProvider);
    final hudNotifier = ref.read(hotkeyHudProvider.notifier);
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wm = WindowManagerService.instance;

    // Collect all selected hunks across files
    final selectedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.hudGlassDark : AppColors.hudGlassLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // HUD Window Titlebar & Drag Handle
            GestureDetector(
              onPanStart: (_) => wm.startDragging(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, size: 16, color: AppColors.amber500),
                    const SizedBox(width: 8),
                    Text(
                      'Otto Quick HUD',
                      style: AppTypography.uiFont.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        hudState.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 15,
                        color: hudState.isPinned ? AppColors.indigo500 : AppColors.zinc500,
                      ),
                      tooltip: 'Pin on top',
                      onPressed: hudNotifier.togglePinned,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: hudNotifier.toggleHud,
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedHunks.length} hunks staged',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.zinc300 : AppColors.zinc700,
                          ),
                        ),
                        Text(
                          'Branch: ${workspace.currentBranch}',
                          style: AppTypography.codeFont.copyWith(
                            fontSize: 11,
                            color: isDark ? AppColors.zinc400 : AppColors.zinc500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick Commit Strip
                    QuickCommitStrip(
                      stagedHunks: selectedHunks,
                      onCommit: ({
                        required String summary,
                        String? description,
                        required String type,
                        String? scope,
                      }) async {
                        await workspaceNotifier.commitSelectedHunks(
                          summary: summary,
                          description: description,
                          type: type,
                          scope: scope,
                          hunks: selectedHunks,
                        );
                        hudNotifier.toggleHud();
                      },
                    ),
                    const Spacer(),

                    // Push shortcut
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            workspaceNotifier.pushStack();
                            hudNotifier.toggleHud();
                          },
                          icon: const Icon(Icons.upload, size: 14),
                          label: const Text('Push Stack to GitHub', style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
