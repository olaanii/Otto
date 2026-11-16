import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/ide_agent_profile.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/workspace_provider.dart';
import 'macos_hig_theme.dart';

/// Authentic macOS translucent sidebar matching macOS Sonoma & Sequoia Finder / Xcode layout.
/// Features frosted liquid glass vibrancy, repository/branch switcher, active IDE AI agent profiles,
/// uncommitted LOC badges, and full-width macOS selection pills.
class MacOSTranslucentSidebar extends ConsumerWidget {
  final double width;
  final VoidCallback? onOpenCommitSplit;
  final VoidCallback? onOpenRebasePlayground;

  const MacOSTranslucentSidebar({
    super.key,
    this.width = 290.0,
    this.onOpenCommitSplit,
    this.onOpenRebasePlayground,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);

    // Compute uncommitted stats
    final totalAdditions = workspace.uncommittedDiffs.fold<int>(
      0,
      (sum, file) => sum + file.additions,
    );
    final totalDeletions = workspace.uncommittedDiffs.fold<int>(
      0,
      (sum, file) => sum + file.deletions,
    );
    final totalFiles = workspace.uncommittedDiffs.length;
    final totalLoc = totalAdditions + totalDeletions;

    return MacOSVisualEffectBox(
      width: width,
      blur: 30.0,
      backgroundColor: MacOSTheme.sidebarBackground(isDark),
      border: Border(
        right: BorderSide(
          color: MacOSTheme.border(isDark),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Repository & Branch Selector Header
          _buildRepositoryHeader(context, workspace, isDark),

          // 2. Uncommitted Working Tree LOC Badge Card
          _buildUncommittedStatsCard(
            context,
            totalAdditions: totalAdditions,
            totalDeletions: totalDeletions,
            totalFiles: totalFiles,
            totalLoc: totalLoc,
            maxLoc: workspace.guardrailPolicy.maxLocPerCommit,
            isDark: isDark,
          ),

          const SizedBox(height: 8),

          // 3. Scrollable Sidebar Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                // SECTION: Active IDE AI Agents
                _buildSectionHeader(
                  title: 'ACTIVE IDE AGENTS',
                  icon: Icons.smart_toy_outlined,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: MacOSTheme.systemGreen(isDark).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${workspace.activeAgents.where((a) => a.isActive).length} LIVE',
                      style: MacOSTheme.footnote(isDark: isDark).copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: MacOSTheme.systemGreen(isDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ...workspace.activeAgents.map(
                  (agent) => _AgentProfileRow(
                    agent: agent,
                    onSliceChanges: () {
                      ref.read(llmSelectorProvider.notifier).refineUncommittedDiffs(
                            instructions: 'Slice changes originated from ${agent.name}',
                          );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // SECTION: Stacked PR Pipeline & Commits
                _buildSectionHeader(
                  title: 'STACKED PR COMMITS',
                  icon: Icons.layers_outlined,
                  isDark: isDark,
                  trailing: Text(
                    '${workspace.stackGraph.commits.length} in stack',
                    style: MacOSTheme.footnote(isDark: isDark).copyWith(fontSize: 10),
                  ),
                ),
                const SizedBox(height: 4),
                if (workspace.stackGraph.commits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: Text(
                      'No stacked commits yet. Select hunks and commit to grow your stack.',
                      style: MacOSTheme.callout(isDark: isDark).copyWith(
                        fontSize: 11.5,
                        color: MacOSTheme.tertiaryLabel(isDark),
                      ),
                    ),
                  )
                else
                  ...workspace.stackGraph.commits.map(
                    (commit) => _StackedCommitRow(
                      commit: commit,
                      isSelected: commit.id == workspace.selectedCommitId,
                      onSelect: () => workspaceNotifier.selectCommit(commit.id),
                    ),
                  ),

                const SizedBox(height: 16),

                // SECTION: Atomic Git Guardrail Meter
                _buildGuardrailMeter(
                  totalLoc: totalLoc,
                  maxLoc: workspace.guardrailPolicy.maxLocPerCommit,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // 4. AppKit Bottom Status Bar
          _buildBottomStatusBar(context, workspaceNotifier, isDark),
        ],
      ),
    );
  }

  /// Top Repository & Branch Selector Header.
  Widget _buildRepositoryHeader(
    BuildContext context,
    WorkspaceState workspace,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MacOSTheme.subtleBorder(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Git Repo Icon (18x18 system size)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: MacOSTheme.systemBlue(isDark).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.source_outlined,
                  size: 14,
                  color: MacOSTheme.systemBlue(isDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'otto-workspace',
                      style: MacOSTheme.headline(isDark: isDark).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'git@github.com:otto/core.git',
                      style: MacOSTheme.footnote(isDark: isDark).copyWith(
                        fontSize: 9.5,
                        color: MacOSTheme.tertiaryLabel(isDark),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Branch Switcher Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33000000) : const Color(0x12000000),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: MacOSTheme.subtleBorder(isDark),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fork_right_rounded,
                  size: 13,
                  color: MacOSTheme.systemBlue(isDark),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    workspace.currentBranch,
                    style: MacOSTheme.code(
                      isDark: isDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MacOSTheme.label(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 13,
                  color: MacOSTheme.secondaryLabel(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Working tree uncommitted additions/deletions card.
  Widget _buildUncommittedStatsCard(
    BuildContext context, {
    required int totalAdditions,
    required int totalDeletions,
    required int totalFiles,
    required int totalLoc,
    required int maxLoc,
    required bool isDark,
  }) {
    final isExceeded = totalLoc > maxLoc;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x2EFFFFFF) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExceeded
              ? MacOSTheme.systemRed(isDark).withOpacity(0.5)
              : MacOSTheme.subtleBorder(isDark),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uncommitted Changes',
                style: MacOSTheme.subheadline(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              Text(
                '$totalFiles ${totalFiles == 1 ? "file" : "files"}',
                style: MacOSTheme.footnote(isDark: isDark).copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Additions Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MacOSTheme.systemGreen(isDark).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+$totalAdditions LOC',
                  style: MacOSTheme.code(
                    isDark: isDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: MacOSTheme.systemGreen(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Deletions Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MacOSTheme.systemRed(isDark).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-$totalDeletions LOC',
                  style: MacOSTheme.code(
                    isDark: isDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: MacOSTheme.systemRed(isDark),
                  ),
                ),
              ),

              const Spacer(),

              // Guardrail alert icon if exceeded
              if (isExceeded)
                Tooltip(
                  message: 'Exceeds Atomic Guardrail limit ($totalLoc / $maxLoc LOC)',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: MacOSTheme.systemRed(isDark),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Apple HIG styled sidebar section header.
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isDark,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: MacOSTheme.tertiaryLabel(isDark),
          ),
          const SizedBox(width: 5),
          Text(
            title,
            style: MacOSTheme.footnote(isDark: isDark).copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: MacOSTheme.tertiaryLabel(isDark),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Atomic PR Guardrail health gauge.
  Widget _buildGuardrailMeter({
    required int totalLoc,
    required int maxLoc,
    required bool isDark,
  }) {
    final progress = (totalLoc / (maxLoc > 0 ? maxLoc : 100)).clamp(0.0, 1.0);
    final isWarning = totalLoc > maxLoc;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x22FFFFFF) : const Color(0x10000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MacOSTheme.subtleBorder(isDark),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 13,
                    color: isWarning
                        ? MacOSTheme.systemRed(isDark)
                        : MacOSTheme.systemBlue(isDark),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Atomic Guardrail',
                    style: MacOSTheme.subheadline(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                '$totalLoc / $maxLoc LOC',
                style: MacOSTheme.code(
                  isDark: isDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isWarning
                      ? MacOSTheme.systemRed(isDark)
                      : MacOSTheme.secondaryLabel(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
              valueColor: AlwaysStoppedAnimation<Color>(
                isWarning ? MacOSTheme.systemRed(isDark) : MacOSTheme.systemBlue(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom AppKit Status Bar.
  Widget _buildBottomStatusBar(
    BuildContext context,
    WorkspaceNotifier notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: MacOSTheme.subtleBorder(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Live Daemon ping dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: MacOSTheme.systemGreen(isDark),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MacOSTheme.systemGreen(isDark).withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SSE Daemon Live',
            style: MacOSTheme.footnote(isDark: isDark).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Refresh Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => notifier.refreshWorkspace(),
              child: Icon(
                Icons.refresh_rounded,
                size: 14,
                color: MacOSTheme.secondaryLabel(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Agent profile row with active pulse indicator and quick action.
class _AgentProfileRow extends StatelessWidget {
  final IdeAgentProfile agent;
  final VoidCallback onSliceChanges;

  const _AgentProfileRow({
    required this.agent,
    required this.onSliceChanges,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: agent.isActive
              ? (isDark ? const Color(0x28FFFFFF) : Colors.white.withOpacity(0.6))
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Agent Avatar / Icon (18x18 system size)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(int.parse(agent.colorHex.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      agent.name.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (agent.isActive)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: MacOSTheme.systemGreen(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MacOSTheme.sidebarBackground(isDark),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),

            // Agent Name & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name,
                    style: MacOSTheme.body(isDark: isDark).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    agent.description,
                    style: MacOSTheme.footnote(isDark: isDark).copyWith(
                      fontSize: 9.5,
                      color: MacOSTheme.tertiaryLabel(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Slice Button
            GestureDetector(
              onTap: onSliceChanges,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: MacOSTheme.systemBlue(isDark).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Slice',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: MacOSTheme.systemBlue(isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width macOS selection pill for stacked commits in sidebar.
class _StackedCommitRow extends StatelessWidget {
  final AtomicCommitUnit commit;
  final bool isSelected;
  final VoidCallback onSelect;

  const _StackedCommitRow({
    required this.commit,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? MacOSTheme.systemBlueDark : MacOSTheme.systemBlueLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // Commit type icon (16x16)
              Icon(
                Icons.commit_rounded,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : MacOSTheme.secondaryLabel(isDark),
              ),
              const SizedBox(width: 7),

              // Commit Summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commit.summary,
                      style: MacOSTheme.body(isDark: isDark).copyWith(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : MacOSTheme.label(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${commit.id.substring(0, 7)} · ${commit.totalLoc} LOC',
                      style: MacOSTheme.code(
                        isDark: isDark,
                        fontSize: 9.5,
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : MacOSTheme.tertiaryLabel(isDark),
                      ),
                    ),
                  ],
                ),
              ),

              // PR Status pill if linked
              if (commit.prNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : MacOSTheme.systemGreen(isDark).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '#${commit.prNumber}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : MacOSTheme.systemGreen(isDark),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
