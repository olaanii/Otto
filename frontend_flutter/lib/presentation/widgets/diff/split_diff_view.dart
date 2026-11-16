import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../domain/models/diff_hunk.dart';
import 'diff_line_row.dart';
import 'hunk_action_bar.dart';

/// Side-by-side split diff renderer showing old file version on the left
/// and new modified version on the right.
class SplitDiffView extends StatelessWidget {
  final FileDiff fileDiff;
  final Set<String> selectedHunkIds;
  final Set<String> selectedLineIds;
  final bool showSyntax;
  final void Function(DiffHunk) onToggleHunk;
  final void Function(String hunkId, DiffLine line) onToggleLine;

  const SplitDiffView({
    super.key,
    required this.fileDiff,
    required this.selectedHunkIds,
    required this.selectedLineIds,
    this.showSyntax = true,
    required this.onToggleHunk,
    required this.onToggleLine,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fileDiff.hunks.map((hunk) {
        final isHunkSelected = selectedHunkIds.contains(hunk.id);

        // Separate lines for side-by-side alignment
        final leftLines = hunk.lines
            .where((l) => l.type != DiffLineType.addition)
            .toList();
        final rightLines = hunk.lines
            .where((l) => l.type != DiffLineType.deletion)
            .toList();

        final maxCount = leftLines.length > rightLines.length
            ? leftLines.length
            : rightLines.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HunkActionBar(
                hunk: hunk,
                isSelected: isHunkSelected,
                onToggleStage: () => onToggleHunk(hunk),
              ),
              ...List.generate(maxCount, (index) {
                final left = index < leftLines.length ? leftLines[index] : null;
                final right = index < rightLines.length ? rightLines[index] : null;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left (Old version)
                    Expanded(
                      child: left != null
                          ? DiffLineRow(
                              line: left,
                              isSelected: selectedLineIds.contains(left.id),
                              showSyntax: showSyntax,
                              onToggleSelect: () => onToggleLine(hunk.id, left),
                            )
                          : Container(
                              height: 24,
                              color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                            ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    // Right (New version)
                    Expanded(
                      child: right != null
                          ? DiffLineRow(
                              line: right,
                              isSelected: selectedLineIds.contains(right.id),
                              showSyntax: showSyntax,
                              onToggleSelect: () => onToggleLine(hunk.id, right),
                            )
                          : Container(
                              height: 24,
                              color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                            ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
