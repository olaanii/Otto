import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import 'pr_status_badge.dart';

/// Interactive card component representing an individual commit in the stack.
class CommitCardItem extends StatelessWidget {
  final AtomicCommitUnit commit;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  const CommitCardItem({
    super.key,
    required this.commit,
    this.isSelected = false,
    this.onTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final typeColor = switch (commit.type.toLowerCase()) {
      'feat' => AppColors.indigo500,
      'fix' => AppColors.emerald500,
      'refactor' => AppColors.amber500,
      'perf' => const Color(0xFF8B5CF6),
      _ => AppColors.zinc500,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.indigo950.withOpacity(0.3) : AppColors.indigo50)
            : (isDark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppColors.indigo500
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],

              // Commit Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  commit.type,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title and Branch info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (commit.scope != null && commit.scope!.isNotEmpty) ...[
                          Text(
                            '(${commit.scope}): ',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            commit.summary,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.uiFont.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.zinc100 : AppColors.zinc900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.call_split,
                          size: 11,
                          color: isDark ? AppColors.zinc500 : AppColors.zinc400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          commit.branchName,
                          style: AppTypography.codeFont.copyWith(
                            fontSize: 11,
                            color: isDark ? AppColors.zinc500 : AppColors.zinc500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // LOC Guardrail indicator
                        Text(
                          '+${commit.additions} -${commit.deletions} LOC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: commit.exceedsLocThreshold
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: commit.exceedsLocThreshold
                                ? AppColors.rose500
                                : (isDark ? AppColors.zinc400 : AppColors.zinc500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${commit.changedFiles.length} files',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: commit.exceedsFileThreshold
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: commit.exceedsFileThreshold
                                ? AppColors.rose500
                                : (isDark ? AppColors.zinc400 : AppColors.zinc500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              PrStatusBadge(
                status: commit.status,
                prNumber: commit.prNumber,
              ),

              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
