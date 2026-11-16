import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../domain/models/atomic_commit_unit.dart';

/// Visual status pill for atomic commits in stacked PR chains.
class PrStatusBadge extends StatelessWidget {
  final CommitStatus status;
  final int? prNumber;

  const PrStatusBadge({
    super.key,
    required this.status,
    this.prNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (label, bgColor, textColor, icon) = switch (status) {
      CommitStatus.draft => (
          'Draft',
          isDark ? AppColors.zinc800 : AppColors.zinc200,
          isDark ? AppColors.zinc300 : AppColors.zinc700,
          Icons.edit_note,
        ),
      CommitStatus.inReview => (
          prNumber != null ? 'PR #$prNumber In Review' : 'In Review',
          isDark ? const Color(0x33F59E0B) : const Color(0xFFFEF3C7),
          AppColors.amber500,
          Icons.hourglass_top,
        ),
      CommitStatus.readyToPush => (
          'Ready to Push',
          isDark ? const Color(0x336366F1) : AppColors.indigo50,
          isDark ? AppColors.indigo400 : AppColors.indigo600,
          Icons.upload,
        ),
      CommitStatus.pushed => (
          prNumber != null ? 'PR #$prNumber Pushed' : 'Pushed',
          isDark ? const Color(0x3310B981) : const Color(0xFFD1FAE5),
          isDark ? AppColors.emerald400 : AppColors.emerald600,
          Icons.cloud_done,
        ),
      CommitStatus.merged => (
          prNumber != null ? 'PR #$prNumber Merged' : 'Merged',
          isDark ? const Color(0x338B5CF6) : const Color(0xFFEDE9FE),
          const Color(0xFF8B5CF6),
          Icons.merge_type,
        ),
      CommitStatus.conflicted => (
          'Conflicted',
          isDark ? AppColors.diffRemovedBgDark : AppColors.diffRemovedBgLight,
          isDark ? AppColors.rose400 : AppColors.rose600,
          Icons.error_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
