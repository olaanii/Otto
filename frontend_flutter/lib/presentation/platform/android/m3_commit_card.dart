import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/guardrail_policy.dart';
import 'android_material3_theme.dart';

/// Material 3 Card style variants for commits in the stacked PR chain.
enum M3CommitCardVariant {
  elevated,
  filledTonal,
  outlined,
}

/// Official Android Material Design 3 Commit Card with 16px corner radii,
/// tonal elevation, LOC badges, and interactive atomic PR compliance score bar.
class M3CommitCard extends StatelessWidget {
  final AtomicCommitUnit commit;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onInspectDiff;
  final VoidCallback? onRebase;
  final M3CommitCardVariant variant;
  final GuardrailPolicy guardrailPolicy;

  const M3CommitCard({
    super.key,
    required this.commit,
    this.isSelected = false,
    this.onTap,
    this.onInspectDiff,
    this.onRebase,
    this.variant = M3CommitCardVariant.elevated,
    this.guardrailPolicy = const GuardrailPolicy(),
  });

  /// Calculates the Atomic PR Compliance Score (0.0 to 1.0) against guardrail thresholds.
  double get complianceScore {
    double score = 1.0;

    // LOC threshold evaluation
    final maxLoc = guardrailPolicy.maxLocPerCommit;
    if (commit.totalLoc > maxLoc) {
      final locOverhang = commit.totalLoc - maxLoc;
      final penalty = (locOverhang / maxLoc).clamp(0.0, 0.6);
      score -= penalty;
    }

    // Files touched threshold evaluation
    final maxFiles = guardrailPolicy.maxFilesPerCommit;
    if (commit.changedFiles.length > maxFiles) {
      final filesOverhang = commit.changedFiles.length - maxFiles;
      final penalty = (filesOverhang * 0.15).clamp(0.0, 0.4);
      score -= penalty;
    }

    // Conventional commit conformance
    if (!guardrailPolicy.allowedCommitTypes.contains(commit.type.toLowerCase())) {
      score -= 0.2;
    }

    if (commit.summary.trim().isEmpty) {
      score -= 0.3;
    }

    return score.clamp(0.0, 1.0);
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<GitM3SemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? GitM3SemanticColors.dark
            : GitM3SemanticColors.light);

    final score = complianceScore;
    final scorePercentage = (score * 100).toInt();

    // Compliance color coding
    final (scoreColor, scoreTrackColor, scoreLabel) = switch (score) {
      >= 0.85 => (
          semantic.complianceHigh,
          semantic.gitAddedContainer.withOpacity(0.4),
          '$scorePercentage% Atomic • Guardrails Passed',
        ),
      >= 0.60 => (
          semantic.complianceMedium,
          semantic.gitModifiedContainer.withOpacity(0.4),
          '$scorePercentage% Atomic • Caution: Oversized PR',
        ),
      _ => (
          semantic.complianceLow,
          semantic.gitRemovedContainer.withOpacity(0.4),
          '$scorePercentage% Atomic • Guardrail Violations',
        ),
    };

    // Conventional commit type color tokens
    final (typeBg, typeFg) = switch (commit.type.toLowerCase()) {
      'feat' => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      'fix' => (semantic.gitAddedContainer, semantic.onGitAddedContainer),
      'refactor' => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      'perf' => (colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
      'chore' || 'docs' => (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
      _ => (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
    };

    // Determine container background based on card variant
    final cardBgColor = switch (variant) {
      M3CommitCardVariant.elevated => isSelected
          ? colorScheme.primaryContainer.withOpacity(0.35)
          : colorScheme.surfaceContainerLow,
      M3CommitCardVariant.filledTonal => isSelected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      M3CommitCardVariant.outlined => isSelected
          ? colorScheme.primaryContainer.withOpacity(0.2)
          : colorScheme.surface,
    };

    final borderSide = BorderSide(
      color: isSelected
          ? colorScheme.primary
          : (variant == M3CommitCardVariant.outlined
              ? colorScheme.outlineVariant
              : colorScheme.outlineVariant.withOpacity(0.4)),
      width: isSelected ? 1.8 : 1.0,
    );

    return Card(
      elevation: variant == M3CommitCardVariant.elevated ? (isSelected ? 3 : 1) : 0,
      color: cardBgColor,
      surfaceTintColor: colorScheme.surfaceTint,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Official 16px corner radii
        side: borderSide,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Commit Type Pill, Scope, Status Badge & Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // M3 Conventional Commit Type Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      commit.type.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: typeFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  if (commit.scope != null && commit.scope!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '(${commit.scope})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // PR Status Pill
                  _M3PrStatusChip(status: commit.status, prNumber: commit.prNumber),

                  const SizedBox(width: 8),

                  // Relative time
                  Text(
                    _formatRelativeTime(commit.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Commit Summary
              Text(
                commit.summary,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.25,
                ),
              ),

              if (commit.description != null && commit.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  commit.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Badges Row: Branch chip, LOC Additions, Deletions, Files touched
              Row(
                children: [
                  // Branch chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fork_right_rounded,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            commit.branchName,
                            overflow: TextOverflow.ellipsis,
                            style: AndroidMaterial3Theme.monoStyle(
                              fontSize: 10.5,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // LOC Additions Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: semantic.gitAddedContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${commit.additions}',
                      style: AndroidMaterial3Theme.monoStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: semantic.onGitAddedContainer,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // LOC Deletions Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: semantic.gitRemovedContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${commit.deletions}',
                      style: AndroidMaterial3Theme.monoStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: semantic.onGitRemovedContainer,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Files touched badge
                  Text(
                    '${commit.changedFiles.length} file${commit.changedFiles.length == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: commit.exceedsFileThreshold
                          ? semantic.gitRemoved
                          : colorScheme.onSurfaceVariant,
                      fontWeight: commit.exceedsFileThreshold
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  // Quick Diff Inspector Action
                  if (onInspectDiff != null)
                    IconButton(
                      icon: const Icon(Icons.difference_outlined, size: 18),
                      tooltip: 'Inspect atomic diff',
                      visualDensity: VisualDensity.compact,
                      onPressed: onInspectDiff,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Material 3 Compliance Score Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        scoreLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        '${commit.totalLoc}/${guardrailPolicy.maxLocPerCommit} LOC',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score,
                      minHeight: 5,
                      backgroundColor: scoreTrackColor,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Material 3 PR Status Pill Chip.
class _M3PrStatusChip extends StatelessWidget {
  final CommitStatus status;
  final int? prNumber;

  const _M3PrStatusChip({
    required this.status,
    this.prNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<GitM3SemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? GitM3SemanticColors.dark
            : GitM3SemanticColors.light);

    final (color, bgColor, text, icon) = switch (status) {
      CommitStatus.draft => (
          colorScheme.onSurfaceVariant,
          colorScheme.surfaceContainerHighest,
          'Draft',
          Icons.edit_note_rounded,
        ),
      CommitStatus.inReview => (
          semantic.complianceMedium,
          semantic.gitModifiedContainer,
          prNumber != null ? '#$prNumber Review' : 'In Review',
          Icons.rate_review_outlined,
        ),
      CommitStatus.readyToPush => (
          colorScheme.primary,
          colorScheme.primaryContainer,
          'Ready to Push',
          Icons.arrow_upward_rounded,
        ),
      CommitStatus.pushed => (
          semantic.complianceHigh,
          semantic.gitAddedContainer,
          prNumber != null ? '#$prNumber Pushed' : 'Pushed',
          Icons.cloud_done_rounded,
        ),
      CommitStatus.merged => (
          const Color(0xFF6750A4),
          const Color(0xFFEADDFF),
          prNumber != null ? '#$prNumber Merged' : 'Merged',
          Icons.merge_type_rounded,
        ),
      CommitStatus.conflicted => (
          semantic.complianceLow,
          semantic.gitRemovedContainer,
          'Conflict',
          Icons.error_outline_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
