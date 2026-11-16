import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/diff_hunk.dart';

/// Header strip above a diff hunk providing granular staging and commit actions.
class HunkActionBar extends StatelessWidget {
  final DiffHunk hunk;
  final bool isSelected;
  final VoidCallback onToggleStage;
  final VoidCallback? onSplitHunk;
  final VoidCallback? onAiExplain;

  const HunkActionBar({
    super.key,
    required this.hunk,
    required this.isSelected,
    required this.onToggleStage,
    this.onSplitHunk,
    this.onAiExplain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Checkbox for whole hunk staging
          InkWell(
            onTap: onToggleStage,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: isSelected ? AppColors.indigo500 : AppColors.zinc500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSelected ? 'Staged for Commit' : 'Unstaged',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (isDark ? AppColors.indigo400 : AppColors.indigo600)
                          : AppColors.zinc500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Hunk range specifier
          Text(
            '@@ -${hunk.oldStart},${hunk.oldLines} +${hunk.newStart},${hunk.newLines} @@',
            style: AppTypography.codeFont.copyWith(
              fontSize: 11.5,
              color: isDark ? AppColors.zinc400 : AppColors.zinc600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hunk.header.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hunk.header,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.codeFont.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.zinc500 : AppColors.zinc400,
                ),
              ),
            ),
          ] else
            const Spacer(),

          // Additions & Deletions metrics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.diffAddedBgDark : AppColors.diffAddedBgLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${hunk.additionsCount}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.diffRemovedBgDark : AppColors.diffRemovedBgLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${hunk.deletionsCount}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.rose400 : AppColors.rose600,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Quick actions
          if (onSplitHunk != null)
            IconButton(
              icon: const Icon(Icons.call_split_outlined, size: 15),
              tooltip: 'Split Hunk into Independent Atomic Commit',
              visualDensity: VisualDensity.compact,
              onPressed: onSplitHunk,
            ),
          if (onAiExplain != null)
            IconButton(
              icon: const Icon(Icons.auto_awesome, size: 15),
              tooltip: 'AI Context Summary',
              visualDensity: VisualDensity.compact,
              onPressed: onAiExplain,
            ),
        ],
      ),
    );
  }
}
