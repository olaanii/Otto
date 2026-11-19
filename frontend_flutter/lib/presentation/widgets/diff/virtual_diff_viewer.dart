import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/workspace_provider.dart';
import 'diff_line_row.dart';
import 'hunk_action_bar.dart';
import 'split_diff_view.dart';

/// Flat virtual item for 120 FPS SliverList recycling.
sealed class VirtualDiffItem {
  const VirtualDiffItem();
}

class VirtualHunkHeaderItem extends VirtualDiffItem {
  final DiffHunk hunk;
  final bool isSelected;
  const VirtualHunkHeaderItem(this.hunk, this.isSelected);
}

class VirtualLineItem extends VirtualDiffItem {
  final String hunkId;
  final DiffLine line;
  final bool isSelected;
  const VirtualLineItem(this.hunkId, this.line, this.isSelected);
}

/// 120 FPS Virtualized Diff Viewer using custom slivers and row recycling.
class VirtualDiffViewer extends ConsumerWidget {
  final List<FileDiff> fileDiffs;
  final VoidCallback? onCommitRequested;

  const VirtualDiffViewer({
    super.key,
    required this.fileDiffs,
    this.onCommitRequested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diffState = ref.watch(diffViewerProvider);
    final diffNotifier = ref.read(diffViewerProvider.notifier);
    final workspace = ref.watch(workspaceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (fileDiffs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.emerald500),
            const SizedBox(height: 12),
            Text(
              'Working tree clean',
              style: AppTypography.uiFont.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.zinc200 : AppColors.zinc800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No uncommitted changes detected in repository.',
              style: TextStyle(color: isDark ? AppColors.zinc400 : AppColors.zinc500),
            ),
          ],
        ),
      );
    }

    // Determine current active file
    final activeFile = fileDiffs.firstWhere(
      (f) => f.filePath == diffState.activeFilePath,
      orElse: () => fileDiffs.first,
    );

    // Calculate staged LOC across all files
    final totalStagedAdditions = fileDiffs.fold<int>(
      0,
      (sum, f) =>
          sum +
          f.hunks.fold<int>(
            0,
            (hSum, h) =>
                hSum +
                h.lines
                    .where((l) =>
                        diffState.selectedLineIds.contains(l.id) &&
                        l.type == DiffLineType.addition)
                    .length,
          ),
    );
    final totalStagedDeletions = fileDiffs.fold<int>(
      0,
      (sum, f) =>
          sum +
          f.hunks.fold<int>(
            0,
            (hSum, h) =>
                hSum +
                h.lines
                    .where((l) =>
                        diffState.selectedLineIds.contains(l.id) &&
                        l.type == DiffLineType.deletion)
                    .length,
          ),
    );
    final totalStagedLoc = totalStagedAdditions + totalStagedDeletions;
    final maxLoc = workspace.guardrailPolicy.maxLocPerCommit;
    final isExceedingGuardrail = totalStagedLoc > maxLoc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // File tabs bar
        _buildFileTabBar(context, ref, activeFile),

        // Controls bar (View mode, Syntax toggle, Select all, Staged LOC counter)
        _buildControlsBar(
          context,
          diffState,
          diffNotifier,
          activeFile,
          totalStagedLoc,
          maxLoc,
          isExceedingGuardrail,
        ),

        // Virtualized Scroll List for 120 FPS performance
        Expanded(
          child: diffState.mode == DiffViewMode.split
              ? SingleChildScrollView(
                  child: SplitDiffView(
                    fileDiff: activeFile,
                    selectedHunkIds: diffState.selectedHunkIds,
                    selectedLineIds: diffState.selectedLineIds,
                    showSyntax: diffState.showSyntaxHighlighting,
                    onToggleHunk: diffNotifier.toggleHunkSelection,
                    onToggleLine: diffNotifier.toggleLineSelection,
                  ),
                )
              : _buildVirtualUnifiedDiff(activeFile, diffState, diffNotifier),
        ),
      ],
    );
  }

  Widget _buildFileTabBar(
    BuildContext context,
    WidgetRef ref,
    FileDiff activeFile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileDiffs.length,
        itemBuilder: (context, index) {
          final file = fileDiffs[index];
          final isActive = file.filePath == activeFile.filePath;

          return InkWell(
            onTap: () {
              ref.read(diffViewerProvider.notifier).setActiveFile(file.filePath);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? AppColors.cardDark : Colors.white)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppColors.indigo500 : Colors.transparent,
                    width: 2,
                  ),
                  right: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    file.isNew
                        ? Icons.add_circle_outline
                        : file.isDeleted
                            ? Icons.remove_circle_outline
                            : Icons.insert_drive_file_outlined,
                    size: 14,
                    color: file.isNew
                        ? AppColors.emerald500
                        : file.isDeleted
                            ? AppColors.rose500
                            : (isDark ? AppColors.zinc400 : AppColors.zinc600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    file.filePath.split('/').last,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? (isDark ? AppColors.zinc100 : AppColors.zinc900)
                          : (isDark ? AppColors.zinc400 : AppColors.zinc600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${file.additions} -${file.deletions}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColors.zinc500 : AppColors.zinc400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsBar(
    BuildContext context,
    DiffViewerState diffState,
    DiffViewerNotifier diffNotifier,
    FileDiff activeFile,
    int totalStagedLoc,
    int maxLoc,
    bool isExceedingGuardrail,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.paperLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View Mode Selector
            SegmentedButton<DiffViewMode>(
              segments: const [
                ButtonSegment(
                  value: DiffViewMode.unified,
                  label: Text('Unified', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.reorder, size: 14),
                ),
                ButtonSegment(
                  value: DiffViewMode.split,
                  label: Text('Split', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.vertical_split, size: 14),
                ),
              ],
              selected: {diffState.mode},
              onSelectionChanged: (set) => diffNotifier.setMode(set.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),

            // Stage All in File
            TextButton.icon(
              onPressed: () => diffNotifier.selectAllHunks(activeFile.hunks),
              icon: const Icon(Icons.select_all, size: 14),
              label: const Text('Stage File', style: TextStyle(fontSize: 11)),
            ),
            TextButton(
              onPressed: diffNotifier.clearSelection,
              child: const Text('Clear', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 16),

            // Atomic Guardrail LOC Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isExceedingGuardrail
                    ? (isDark ? AppColors.diffRemovedBgDark : AppColors.diffRemovedBgLight)
                    : (isDark ? AppColors.zinc800 : AppColors.zinc200),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isExceedingGuardrail ? AppColors.rose500 : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExceedingGuardrail ? Icons.warning_amber_rounded : Icons.speed,
                    size: 13,
                    color: isExceedingGuardrail
                        ? AppColors.rose500
                        : (isDark ? AppColors.zinc400 : AppColors.zinc600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$totalStagedLoc / $maxLoc LOC',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isExceedingGuardrail
                          ? AppColors.rose500
                          : (isDark ? AppColors.zinc200 : AppColors.zinc800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Commit Staged Lines Action Button
            FilledButton.icon(
              onPressed: totalStagedLoc > 0 ? onCommitRequested : null,
              icon: const Icon(Icons.commit, size: 15),
              label: Text(
                'Commit Staged ($totalStagedLoc LOC)',
                style: const TextStyle(fontSize: 12),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualUnifiedDiff(
    FileDiff activeFile,
    DiffViewerState diffState,
    DiffViewerNotifier diffNotifier,
  ) {
    // Flatten hunks and lines into virtual items for 120 FPS recycling
    final virtualItems = <VirtualDiffItem>[];
    for (final hunk in activeFile.hunks) {
      final isHunkSelected = diffState.selectedHunkIds.contains(hunk.id);
      virtualItems.add(VirtualHunkHeaderItem(hunk, isHunkSelected));

      for (final line in hunk.lines) {
        final isLineSelected = diffState.selectedLineIds.contains(line.id);
        virtualItems.add(VirtualLineItem(hunk.id, line, isLineSelected));
      }
    }

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = virtualItems[index];
              return switch (item) {
                VirtualHunkHeaderItem(:final hunk, :final isSelected) =>
                  HunkActionBar(
                    hunk: hunk,
                    isSelected: isSelected,
                    onToggleStage: () => diffNotifier.toggleHunkSelection(hunk),
                  ),
                VirtualLineItem(:final hunkId, :final line, :final isSelected) =>
                  DiffLineRow(
                    line: line,
                    isSelected: isSelected,
                    showSyntax: diffState.showSyntaxHighlighting,
                    onToggleSelect: () => diffNotifier.toggleLineSelection(hunkId, line),
                  ),
              };
            },
            childCount: virtualItems.length,
          ),
        ),
      ],
    );
  }
}
