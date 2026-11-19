import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/diff_hunk.dart';
import 'windows_fluent_theme.dart';

/// Foundational Windows 11 Fluent ContentDialog widget.
/// Follows Microsoft's Fluent 2 specs: 8px corner radius, 1px stroke outline,
/// modal barrier blur, and standard primary/secondary/close action buttons.
class FluentContentDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;

  const FluentContentDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.maxWidth = 480,
  });

  /// Displays the ContentDialog with an authentic Acrylic smoke barrier.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x66000000),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? FluentMicaColors.layerBackgroundDark
                  : FluentMicaColors.layerBackgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? FluentMicaColors.cardStrokeDark
                    : FluentMicaColors.cardStrokeLight,
                width: 1,
              ),
              boxShadow: FluentElevation.dialog(isDark),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Area
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: DefaultTextStyle(
                      style: FluentTypography.subtitle.copyWith(
                        color: isDark
                            ? FluentMicaColors.textPrimaryDark
                            : FluentMicaColors.textPrimaryLight,
                      ),
                      child: title!,
                    ),
                  ),

                // Content Area
                Padding(
                  padding: EdgeInsets.fromLTRB(24, title == null ? 20 : 0, 24, 20),
                  child: DefaultTextStyle(
                    style: FluentTypography.body.copyWith(
                      color: isDark
                          ? FluentMicaColors.textSecondaryDark
                          : FluentMicaColors.textSecondaryLight,
                    ),
                    child: content,
                  ),
                ),

                // Action Footer Area
                if (actions != null && actions!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FluentMicaColors.layerBackgroundAltDark
                          : FluentMicaColors.layerBackgroundAltLight,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? FluentMicaColors.dividerStrokeDark
                              : FluentMicaColors.dividerStrokeLight,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < actions!.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          actions![i],
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Windows 11 ContentDialog for Git Remote Push Confirmation.
class GitConfirmationDialog extends StatefulWidget {
  final List<AtomicCommitUnit> commits;
  final String branch;
  final Future<bool> Function({required bool forceWithLease}) onConfirmPush;

  const GitConfirmationDialog({
    super.key,
    required this.commits,
    required this.branch,
    required this.onConfirmPush,
  });

  @override
  State<GitConfirmationDialog> createState() => _GitConfirmationDialogState();
}

class _GitConfirmationDialogState extends State<GitConfirmationDialog> {
  bool _forceWithLease = false;
  bool _isPushing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FluentContentDialog(
      maxWidth: 520,
      title: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 20,
            color: isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault,
          ),
          const SizedBox(width: 10),
          const Text('Push Atomic Stack to GitHub'),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You are about to push ${widget.commits.length} atomic commit(s) on branch "${widget.branch}" to GitHub remote.',
            style: FluentTypography.body.copyWith(
              color: isDark
                  ? FluentMicaColors.textPrimaryDark
                  : FluentMicaColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 14),

          // Commits summary list
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? FluentMicaColors.layerBackgroundAltDark
                  : FluentMicaColors.layerBackgroundAltLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? FluentMicaColors.cardStrokeDark
                    : FluentMicaColors.cardStrokeLight,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.commits.length,
              separatorBuilder: (_, __) => Divider(
                height: 8,
                color: isDark
                    ? FluentMicaColors.dividerStrokeDark
                    : FluentMicaColors.dividerStrokeLight,
              ),
              itemBuilder: (context, idx) {
                final c = widget.commits[idx];
                return Row(
                  children: [
                    Text(
                      c.id.length >= 7 ? c.id.substring(0, 7) : c.id,
                      style: FluentTypography.diffLineStyle(
                        isDark: isDark,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? FluentMicaColors.accentLight
                            : FluentMicaColors.accentDefault,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.conventionalTitle,
                        style: FluentTypography.body.copyWith(
                          fontSize: 12,
                          color: isDark
                              ? FluentMicaColors.textPrimaryDark
                              : FluentMicaColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Force push option
          Row(
            children: [
              Checkbox(
                value: _forceWithLease,
                onChanged: (val) => setState(() => _forceWithLease = val ?? false),
                activeColor: isDark
                    ? FluentMicaColors.accentLight
                    : FluentMicaColors.accentDefault,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Force push with lease (--force-with-lease) for rebased stack DAGs',
                  style: FluentTypography.caption.copyWith(
                    color: isDark
                        ? FluentMicaColors.textSecondaryDark
                        : FluentMicaColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        FluentButton(
          onPressed: _isPushing ? null : () => Navigator.of(context).pop(false),
          style: FluentButtonStyle.subtle,
          child: const Text('Cancel'),
        ),
        FluentButton(
          onPressed: _isPushing
              ? null
              : () async {
                  setState(() => _isPushing = true);
                  final nav = Navigator.of(context);
                  final success = await widget.onConfirmPush(forceWithLease: _forceWithLease);
                  if (mounted) {
                    nav.pop(success);
                  }
                },
          style: FluentButtonStyle.accent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isPushing) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Text(_isPushing ? 'Pushing Stack...' : 'Confirm & Push'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Windows 11 ContentDialog for Slicing Diffs into an Atomic Commit.
class SplitCommitDialog extends StatefulWidget {
  final List<DiffHunk> hunks;
  final Future<void> Function({
    required String summary,
    String? description,
    required String type,
    String? scope,
  }) onCommit;

  const SplitCommitDialog({
    super.key,
    required this.hunks,
    required this.onCommit,
  });

  @override
  State<SplitCommitDialog> createState() => _SplitCommitDialogState();
}

class _SplitCommitDialogState extends State<SplitCommitDialog> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedType = 'feat';
  bool _isCommitting = false;

  final List<String> _types = [
    'feat',
    'fix',
    'refactor',
    'perf',
    'style',
    'test',
    'docs',
    'chore'
  ];

  @override
  void dispose() {
    _summaryController.dispose();
    _scopeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FluentContentDialog(
      maxWidth: 540,
      title: Row(
        children: [
          Icon(
            Icons.call_split_rounded,
            size: 20,
            color: isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentIndigo,
          ),
          const SizedBox(width: 10),
          const Text('Slice Diff into Atomic Commit'),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Creating an atomic PR commit from ${widget.hunks.length} selected diff hunk(s).',
            style: FluentTypography.body.copyWith(
              color: isDark
                  ? FluentMicaColors.textSecondaryDark
                  : FluentMicaColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),

          // Conventional Commit Type & Scope
          Row(
            children: [
              // Type dropdown
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? FluentMicaColors.layerBackgroundAltDark
                      : FluentMicaColors.layerBackgroundAltLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark
                        ? FluentMicaColors.cardStrokeDark
                        : FluentMicaColors.cardStrokeLight,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    style: FluentTypography.bodyStrong.copyWith(
                      fontSize: 12,
                      color: isDark
                          ? FluentMicaColors.textPrimaryDark
                          : FluentMicaColors.textPrimaryLight,
                    ),
                    dropdownColor: isDark
                        ? FluentMicaColors.layerBackgroundDark
                        : FluentMicaColors.layerBackgroundLight,
                    items: _types
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Scope input
              Expanded(
                flex: 2,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? FluentMicaColors.layerBackgroundAltDark
                        : FluentMicaColors.layerBackgroundAltLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? FluentMicaColors.cardStrokeDark
                          : FluentMicaColors.cardStrokeLight,
                    ),
                  ),
                  child: TextField(
                    controller: _scopeController,
                    style: FluentTypography.body.copyWith(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                      hintText: 'scope (optional)',
                      hintStyle: FluentTypography.caption.copyWith(
                        color: isDark
                            ? FluentMicaColors.textTertiaryDark
                            : FluentMicaColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Summary input
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? FluentMicaColors.layerBackgroundAltDark
                  : FluentMicaColors.layerBackgroundAltLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark
                    ? FluentMicaColors.cardStrokeDark
                    : FluentMicaColors.cardStrokeLight,
              ),
            ),
            child: TextField(
              controller: _summaryController,
              style: FluentTypography.body.copyWith(fontSize: 12.5),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                hintText: 'Commit summary (e.g., implement fluent caption bar)',
                hintStyle: FluentTypography.caption.copyWith(
                  color: isDark
                      ? FluentMicaColors.textTertiaryDark
                      : FluentMicaColors.textTertiaryLight,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Description input
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? FluentMicaColors.layerBackgroundAltDark
                  : FluentMicaColors.layerBackgroundAltLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark
                    ? FluentMicaColors.cardStrokeDark
                    : FluentMicaColors.cardStrokeLight,
              ),
            ),
            child: TextField(
              controller: _descController,
              maxLines: null,
              style: FluentTypography.body.copyWith(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Optional PR description & rationale...',
                hintStyle: FluentTypography.caption.copyWith(
                  color: isDark
                      ? FluentMicaColors.textTertiaryDark
                      : FluentMicaColors.textTertiaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        FluentButton(
          onPressed: _isCommitting ? null : () => Navigator.of(context).pop(),
          style: FluentButtonStyle.subtle,
          child: const Text('Cancel'),
        ),
        FluentButton(
          onPressed: (_isCommitting || _summaryController.text.trim().isEmpty)
              ? null
              : () async {
                  setState(() => _isCommitting = true);
                  final nav = Navigator.of(context);
                  await widget.onCommit(
                    summary: _summaryController.text.trim(),
                    description: _descController.text.trim().isEmpty
                        ? null
                        : _descController.text.trim(),
                    type: _selectedType,
                    scope: _scopeController.text.trim().isEmpty
                        ? null
                        : _scopeController.text.trim(),
                  );
                  if (mounted) nav.pop();
                },
          style: FluentButtonStyle.accent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCommitting) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              const Text('Create Atomic Commit'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Windows 11 ContentDialog for Rebase / Squash / Reorder Execution.
class RebaseActionDialog extends StatelessWidget {
  final int reorderedCommitCount;
  final bool isValid;
  final VoidCallback onExecuteRebase;

  const RebaseActionDialog({
    super.key,
    required this.reorderedCommitCount,
    required this.isValid,
    required this.onExecuteRebase,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FluentContentDialog(
      maxWidth: 480,
      title: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: 20,
            color: isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault,
          ),
          const SizedBox(width: 10),
          const Text('Confirm Stack Rebase & Reorder'),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You are executing an in-memory stack rebase affecting $reorderedCommitCount commits in the dependency graph.',
            style: FluentTypography.body.copyWith(
              color: isDark
                  ? FluentMicaColors.textPrimaryDark
                  : FluentMicaColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isValid
                  ? (isDark
                      ? FluentMicaColors.gitAddedSubtleDark
                      : FluentMicaColors.gitAddedSubtleLight)
                  : (isDark
                      ? FluentMicaColors.gitRemovedSubtleDark
                      : FluentMicaColors.gitRemovedSubtleLight),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isValid ? FluentMicaColors.gitAdded : FluentMicaColors.gitRemoved,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                  size: 16,
                  color: isValid ? FluentMicaColors.gitAdded : FluentMicaColors.gitRemoved,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isValid
                        ? 'Stack DAG validation passed. No circular dependencies detected.'
                        : 'DAG validation error: Cyclic dependencies or invalid parent links.',
                    style: FluentTypography.caption.copyWith(
                      color: isValid ? FluentMicaColors.gitAdded : FluentMicaColors.gitRemoved,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FluentButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FluentButtonStyle.subtle,
          child: const Text('Cancel'),
        ),
        FluentButton(
          onPressed: isValid
              ? () {
                  Navigator.of(context).pop();
                  onExecuteRebase();
                }
              : null,
          style: FluentButtonStyle.accent,
          child: const Text('Execute Rebase'),
        ),
      ],
    );
  }
}

/// Windows 11 Fluent Keyboard Shortcuts Dialog (Figma 90:479).
class Windows11KeyboardShortcutsDialog extends StatelessWidget {
  const Windows11KeyboardShortcutsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: const Color(0x59000000), // rgba(0,0,0,0.35)
      builder: (ctx) => const Windows11KeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 680,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3A3A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7A000000),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keyboard shortcuts',
                        style: TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Otto · Ctrl-based shortcuts on Windows',
                        style: TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFB3B3B3),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFB3B3B3)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('WORKSPACE', [
                          _buildShortcutRow('Open HUD', ['Ctrl', 'Shift', 'K']),
                          _buildShortcutRow('Stacked PRs', ['Ctrl', '1']),
                          _buildShortcutRow('Diff Viewer', ['Ctrl', '2']),
                          _buildShortcutRow('Rebase Canvas', ['Ctrl', '3']),
                          _buildShortcutRow('AI Agents', ['Ctrl', '4']),
                          _buildShortcutRow('Settings', ['Ctrl', ',']),
                        ]),
                        const SizedBox(height: 16),
                        _buildSection('GLOBAL', [
                          _buildShortcutRow('Sync now', ['Ctrl', 'R']),
                          _buildShortcutRow('Toggle Auto-Pilot', ['Ctrl', 'Alt', 'P']),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Column 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('COMMIT', [
                          _buildShortcutRow('Generate message', ['Ctrl', 'Shift', 'G']),
                          _buildShortcutRow('Stage hunk', ['Ctrl', 'Shift', 'S']),
                          _buildShortcutRow('Unstage hunk', ['Ctrl', 'Shift', 'U']),
                          _buildShortcutRow('Commit', ['Ctrl', 'Enter']),
                        ]),
                        const SizedBox(height: 16),
                        _buildSection('REBASE CANVAS', [
                          _buildShortcutRow('Move commit up', ['Alt', 'Up']),
                          _buildShortcutRow('Move commit down', ['Alt', 'Down']),
                          _buildShortcutRow('Apply rebase', ['Ctrl', 'Enter']),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Footer with Close button (Figma 90:630)
              Align(
                alignment: Alignment.centerRight,
                child: FluentButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FluentButtonStyle.accent,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: FluentTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB3B3B3),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _buildShortcutRow(String label, List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: FluentTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < keys.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 11,
                        color: Color(0xFFB3B3B3),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF383838),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF4A4A4A)),
                  ),
                  child: Text(
                    keys[i],
                    style: const TextStyle(
                      fontFamily: FluentTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
