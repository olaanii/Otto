import 'package:flutter/material.dart';
import '../../../domain/models/diff_hunk.dart';
import 'diff_line_row.dart';
import 'hunk_action_bar.dart';

/// Unified continuous diff renderer for a single file's hunks.
class UnifiedDiffView extends StatelessWidget {
  final FileDiff fileDiff;
  final Set<String> selectedHunkIds;
  final Set<String> selectedLineIds;
  final bool showSyntax;
  final void Function(DiffHunk) onToggleHunk;
  final void Function(String hunkId, DiffLine line) onToggleLine;
  final void Function(DiffHunk)? onSplitHunk;

  const UnifiedDiffView({
    super.key,
    required this.fileDiff,
    required this.selectedHunkIds,
    required this.selectedLineIds,
    this.showSyntax = true,
    required this.onToggleHunk,
    required this.onToggleLine,
    this.onSplitHunk,
  });

  @override
  Widget build(BuildContext context) {
    if (fileDiff.hunks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No modifications in this file.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fileDiff.hunks.map((hunk) {
        final isHunkSelected = selectedHunkIds.contains(hunk.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HunkActionBar(
                hunk: hunk,
                isSelected: isHunkSelected,
                onToggleStage: () => onToggleHunk(hunk),
                onSplitHunk: onSplitHunk != null ? () => onSplitHunk!(hunk) : null,
              ),
              ...hunk.lines.map((line) {
                final isLineSelected = selectedLineIds.contains(line.id);
                return DiffLineRow(
                  line: line,
                  isSelected: isLineSelected,
                  showSyntax: showSyntax,
                  onToggleSelect: () => onToggleLine(hunk.id, line),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
