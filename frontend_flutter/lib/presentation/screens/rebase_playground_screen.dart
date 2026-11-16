import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/typography.dart';
import '../providers/rebase_canvas_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/stack/commit_card_item.dart';
import '../widgets/stack/reorder_drag_handle.dart';

/// Interactive Rebase Playground canvas allowing developers to visually
/// reorder, squash, and reorganize stacked PR commits with DAG validation.
class RebasePlaygroundScreen extends ConsumerWidget {
  const RebasePlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rebaseState = ref.watch(rebaseCanvasProvider);
    final rebaseNotifier = ref.read(rebaseCanvasProvider.notifier);
    final workspace = ref.watch(workspaceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final commitMap = {for (final c in workspace.stackGraph.commits) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.tune, size: 20, color: AppColors.indigo500),
            const SizedBox(width: 10),
            Text(
              'Interactive Stack Rebase Playground',
              style: AppTypography.uiFont.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (rebaseState.isDirty)
            TextButton(
              onPressed: rebaseNotifier.reset,
              child: const Text('Reset Order'),
            ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: FilledButton.icon(
              onPressed: (rebaseState.isDirty && rebaseState.isValid && !rebaseState.isRebasing)
                  ? () async {
                      final success = await rebaseNotifier.executeRebase();
                      if (context.mounted && success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stack successfully reordered and rebased!'),
                            backgroundColor: AppColors.emerald500,
                          ),
                        );
                      }
                    }
                  : null,
              icon: rebaseState.isRebasing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 16),
              label: const Text('Apply Rebase'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Validation / Warning Banner
          if (!rebaseState.isValid && rebaseState.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? AppColors.diffRemovedBgDark : AppColors.diffRemovedBgLight,
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16, color: AppColors.rose500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rebaseState.errorMessage!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.rose500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Reorderable Canvas
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              itemCount: rebaseState.orderedCommitIds.length,
              onReorder: rebaseNotifier.reorderCommit,
              itemBuilder: (context, index) {
                final commitId = rebaseState.orderedCommitIds[index];
                final commit = commitMap[commitId];

                if (commit == null) return SizedBox.shrink(key: ValueKey(commitId));

                return Container(
                  key: ValueKey(commit.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Order Number Pill
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.codeFont.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reorderable Item Card
                      Expanded(
                        child: CommitCardItem(
                          commit: commit,
                          isSelected: false,
                          leading: ReorderDragHandle(index: index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
