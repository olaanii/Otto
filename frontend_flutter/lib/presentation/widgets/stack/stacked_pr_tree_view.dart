import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../providers/workspace_provider.dart';
import 'commit_card_item.dart';

/// Vertical tree visualizer depicting the linear stacked PR chain with parent-child lines.
class StackedPrTreeView extends ConsumerWidget {
  final List<AtomicCommitUnit> commits;
  final String? selectedCommitId;
  final void Function(AtomicCommitUnit)? onCommitSelected;
  final VoidCallback? onOpenRebaseCanvas;

  const StackedPrTreeView({
    super.key,
    required this.commits,
    this.selectedCommitId,
    this.onCommitSelected,
    this.onOpenRebaseCanvas,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (commits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers_clear_outlined, size: 40, color: AppColors.zinc500),
              const SizedBox(height: 12),
              Text(
                'Stack is empty',
                style: AppTypography.uiFont.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.zinc200 : AppColors.zinc800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stage diff hunks and commit to create your first atomic PR in the stack.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_tree_outlined, size: 16, color: AppColors.indigo500),
              const SizedBox(width: 8),
              Text(
                'Stacked PR Chain (${commits.length})',
                style: AppTypography.uiFont.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onOpenRebaseCanvas != null)
                TextButton.icon(
                  onPressed: onOpenRebaseCanvas,
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('Rebase Canvas', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),

        // Stacked Commits List
        Expanded(
          child: ListView.builder(
            itemCount: commits.length,
            itemBuilder: (context, index) {
              final commit = commits[index];
              final isSelected = commit.id == selectedCommitId;
              final isTop = index == 0;
              final isBottom = index == commits.length - 1;

              return Stack(
                children: [
                  // Connecting Tree Vertical Line
                  Positioned(
                    left: 20,
                    top: isTop ? 24 : 0,
                    bottom: isBottom ? 24 : 0,
                    child: Container(
                      width: 2,
                      color: isDark ? AppColors.zinc700 : AppColors.zinc300,
                    ),
                  ),

                  // Node Circle Marker
                  Positioned(
                    left: 17,
                    top: 24,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.indigo500 : AppColors.zinc400,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.backgroundDark : AppColors.paperLight,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // Commit Card
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: CommitCardItem(
                      commit: commit,
                      isSelected: isSelected,
                      onTap: () => onCommitSelected?.call(commit),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
