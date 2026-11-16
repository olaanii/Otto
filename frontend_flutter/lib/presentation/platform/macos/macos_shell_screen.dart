import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/hotkey_hud_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/rebase_canvas_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/agent/prompt_stream_ticker.dart';
import '../../widgets/diff/virtual_diff_viewer.dart';
import '../../widgets/hud/floating_hud_card.dart';
import '../../widgets/hud/quick_commit_strip.dart';
import '../../widgets/stack/commit_card_item.dart';
import '../../widgets/stack/reorder_drag_handle.dart';
import '../../widgets/stack/stacked_pr_tree_view.dart';
import 'macos_hig_theme.dart';
import 'macos_sheet_modal.dart';
import 'macos_translucent_sidebar.dart';
import 'macos_unified_toolbar.dart';

/// Complete macOS Sonoma / Sequoia HIG Desktop Workspace Screen.
/// Orchestrates unified AppKit window toolbar, frosted translucent sidebar,
/// segmented view switching (Sliced Diff, Rebase Playground, Stacked Pipeline),
/// and native sliding AppKit sheet modals.
class MacOSShellScreen extends ConsumerStatefulWidget {
  const MacOSShellScreen({super.key});

  @override
  ConsumerState<MacOSShellScreen> createState() => _MacOSShellScreenState();
}

/// Alias for compatibility with adaptive shell platform routers.
typedef MacosShellScreen = MacOSShellScreen;

class _MacOSShellScreenState extends ConsumerState<MacOSShellScreen> {
  MacOSWorkspaceView _currentView = MacOSWorkspaceView.slicedDiff;
  bool _isSidebarVisible = true;

  void _openSettings() {
    showMacOSSheet(
      context: context,
      builder: (_) => const MacOSSettingsSheet(),
    );
  }

  void _openClerkAuth() {
    showMacOSSheet(
      context: context,
      builder: (_) => const MacOSClerkAuthSheet(),
    );
  }

  void _openCommitSplit(List<DiffHunk> stagedHunks) {
    showMacOSSheet(
      context: context,
      builder: (_) => MacOSCommitSplitSheet(stagedHunks: stagedHunks),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final hudState = ref.watch(hotkeyHudProvider);
    final llmState = ref.watch(llmSelectorProvider);

    // Collect currently staged hunks across all files
    final stagedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () {
          setState(() => _currentView = MacOSWorkspaceView.slicedDiff);
        },
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () {
          setState(() => _currentView = MacOSWorkspaceView.rebasePlayground);
        },
        const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () {
          setState(() => _currentView = MacOSWorkspaceView.stackedPipeline);
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          setState(() => _isSidebarVisible = !_isSidebarVisible);
        },
        const SingleActivator(LogicalKeyboardKey.comma, meta: true): _openSettings,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          ref.read(hotkeyHudProvider.notifier).toggleHud();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: MacOSTheme.windowBackground(isDark),
          body: Stack(
            children: [
              // Main Window Frame
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Unified AppKit Window Toolbar
                  MacOSUnifiedToolbar(
                    currentView: _currentView,
                    onViewChanged: (view) => setState(() => _currentView = view),
                    isSidebarVisible: _isSidebarVisible,
                    onToggleSidebar: () {
                      setState(() => _isSidebarVisible = !_isSidebarVisible);
                    },
                    onOpenSettings: _openSettings,
                    onOpenClerkAuth: _openClerkAuth,
                  ),

                  // 2. Main Desktop Split-View (Sidebar + Active View)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Collapsible Translucent Sidebar
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: SizedBox(
                            width: _isSidebarVisible ? 280.0 : 0.0,
                            child: _isSidebarVisible
                                ? MacOSTranslucentSidebar(
                                    width: 280.0,
                                    onOpenCommitSplit: () => _openCommitSplit(stagedHunks),
                                    onOpenRebasePlayground: () {
                                      setState(() => _currentView =
                                          MacOSWorkspaceView.rebasePlayground);
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),

                        // Active View Switcher Content
                        Expanded(
                          child: Container(
                            color: MacOSTheme.contentBackground(isDark),
                            child: switch (_currentView) {
                              MacOSWorkspaceView.slicedDiff =>
                                _buildSlicedDiffView(
                                  context,
                                  ref,
                                  workspace,
                                  workspaceNotifier,
                                  diffState,
                                  llmState,
                                  stagedHunks,
                                  isDark,
                                ),
                              MacOSWorkspaceView.rebasePlayground =>
                                _buildRebasePlaygroundView(
                                  context,
                                  ref,
                                  workspace,
                                  isDark,
                                ),
                              MacOSWorkspaceView.stackedPipeline =>
                                _buildStackedPipelineView(
                                  context,
                                  workspace,
                                  workspaceNotifier,
                                  isDark,
                                ),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. Floating HUD Overlay (Picture-in-Picture Quick Commit)
              if (hudState.isHudVisible)
                Positioned(
                  top: 56,
                  right: 20,
                  width: 520,
                  height: 440,
                  child: Material(
                    type: MaterialType.transparency,
                    child: MacOSVisualEffectBox(
                      blur: 32.0,
                      backgroundColor: MacOSTheme.cardBackground(isDark).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      shadows: MacOSTheme.sheetShadow,
                      child: const FloatingHudCard(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // VIEW 1: Sliced Diff View (120 FPS Diff Virtualization & Commit Slicing)
  // ===========================================================================
  Widget _buildSlicedDiffView(
    BuildContext context,
    WidgetRef ref,
    WorkspaceState workspace,
    WorkspaceNotifier workspaceNotifier,
    DiffViewerState diffState,
    LlmSelectorState llmState,
    List<DiffHunk> stagedHunks,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Prompt Ticker if AI is actively refining
        if (llmState.activeStreamingText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: MacOSTheme.systemPurple(isDark).withOpacity(0.08),
              border: Border(
                bottom: BorderSide(
                  color: MacOSTheme.systemPurple(isDark).withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: PromptStreamTicker(
              text: llmState.activeStreamingText!,
              isStreaming: llmState.isRefining,
            ),
          ),

        // Virtualized Diff Viewer
        Expanded(
          child: VirtualDiffViewer(
            fileDiffs: workspace.uncommittedDiffs,
            onCommitRequested: () => _openCommitSplit(stagedHunks),
          ),
        ),

        // Bottom macOS Commit Slicing Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: MacOSTheme.toolbarBackground(isDark),
            border: Border(
              top: BorderSide(
                color: MacOSTheme.border(isDark),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: QuickCommitStrip(
                  stagedHunks: stagedHunks,
                  onCommit: ({
                    required String summary,
                    String? description,
                    required String type,
                    String? scope,
                  }) async {
                    await workspaceNotifier.commitSelectedHunks(
                      summary: summary,
                      description: description,
                      type: type,
                      scope: scope,
                      hunks: stagedHunks,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Advanced Inspector Sheet Trigger
              Tooltip(
                message: 'Open Inspector Sheet for deep hunk inspection',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: stagedHunks.isEmpty ? null : () => _openCommitSplit(stagedHunks),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: MacOSTheme.subtleBorder(isDark),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: MacOSTheme.secondaryLabel(isDark),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Inspect Slice',
                            style: MacOSTheme.subheadline(isDark: isDark).copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 2: Rebase Playground View (Interactive Drag & Drop Canvas)
  // ===========================================================================
  Widget _buildRebasePlaygroundView(
    BuildContext context,
    WidgetRef ref,
    WorkspaceState workspace,
    bool isDark,
  ) {
    final rebaseState = ref.watch(rebaseCanvasProvider);
    final rebaseNotifier = ref.read(rebaseCanvasProvider.notifier);
    final commitMap = {for (final c in workspace.stackGraph.commits) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-Toolbar for Rebase Canvas
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: MacOSTheme.toolbarBackground(isDark),
            border: Border(
              bottom: BorderSide(
                color: MacOSTheme.border(isDark),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.swap_vert_rounded,
                size: 16,
                color: MacOSTheme.systemBlue(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                'Interactive Stack Rebase & Squash Canvas',
                style: MacOSTheme.headline(isDark: isDark).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (rebaseState.isDirty) ...[
                TextButton(
                  onPressed: rebaseNotifier.reset,
                  child: Text(
                    'Reset Order',
                    style: TextStyle(
                      fontSize: 12,
                      color: MacOSTheme.secondaryLabel(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: (rebaseState.isDirty && rebaseState.isValid && !rebaseState.isRebasing)
                    ? () async {
                        final success = await rebaseNotifier.executeRebase();
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Stack successfully reordered and rebased!'),
                              backgroundColor: MacOSTheme.systemGreen(isDark),
                            ),
                          );
                        }
                      }
                    : null,
                icon: rebaseState.isRebasing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 14),
                label: const Text('Apply Rebase', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: MacOSTheme.systemBlue(isDark),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // Error / DAG Validation Banner
        if (!rebaseState.isValid && rebaseState.errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: MacOSTheme.systemRed(isDark).withOpacity(0.14),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, size: 15, color: MacOSTheme.systemRed(isDark)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rebaseState.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: MacOSTheme.systemRed(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Drag & Drop Reorderable List
        Expanded(
          child: rebaseState.orderedCommitIds.isEmpty
              ? Center(
                  child: Text(
                    'No commits in the current branch stack to rebase.',
                    style: MacOSTheme.body(isDark: isDark).copyWith(
                      color: MacOSTheme.secondaryLabel(isDark),
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: rebaseState.orderedCommitIds.length,
                  onReorder: rebaseNotifier.reorderCommit,
                  itemBuilder: (context, index) {
                    final commitId = rebaseState.orderedCommitIds[index];
                    final commit = commitMap[commitId];
                    if (commit == null) return SizedBox.shrink(key: ValueKey(commitId));

                    return Container(
                      key: ValueKey(commit.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // AppKit Number Badge
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MacOSTheme.subtleBorder(isDark),
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: MacOSTheme.code(
                                  isDark: isDark,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Reorderable Commit Card
                          Expanded(
                            child: CommitCardItem(
                              commit: commit,
                              isSelected: false,
                              leading: ReorderDragHandle(index: index),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 3: Stacked Pipeline View (Tree Visualization & Inspector)
  // ===========================================================================
  Widget _buildStackedPipelineView(
    BuildContext context,
    WorkspaceState workspace,
    WorkspaceNotifier notifier,
    bool isDark,
  ) {
    final selectedCommit = workspace.stackGraph.commits.firstWhere(
      (c) => c.id == workspace.selectedCommitId,
      orElse: () => workspace.stackGraph.commits.isNotEmpty
          ? workspace.stackGraph.commits.first
          : AtomicCommitUnit(
              id: 'none',
              branchName: workspace.currentBranch,
              summary: 'No Commit Selected',
              type: 'chore',
              additions: 0,
              deletions: 0,
              changedFiles: [],
              parentCommitId: null,
              createdAt: DateTime.now(),
            ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Stacked PR Tree
        Expanded(
          flex: 3,
          child: StackedPrTreeView(
            commits: workspace.stackGraph.commits,
            selectedCommitId: workspace.selectedCommitId,
            onCommitSelected: (c) => notifier.selectCommit(c.id),
            onOpenRebaseCanvas: () {
              setState(() => _currentView = MacOSWorkspaceView.rebasePlayground);
            },
          ),
        ),

        // Split Divider
        VerticalDivider(
          width: 1,
          thickness: 0.5,
          color: MacOSTheme.border(isDark),
        ),

        // Right Column: Commit Inspector Panel
        Expanded(
          flex: 2,
          child: _buildCommitInspectorPanel(context, selectedCommit, isDark),
        ),
      ],
    );
  }

  /// AppKit-style Inspector pane displaying selected commit details and PR status.
  Widget _buildCommitInspectorPanel(
    BuildContext context,
    AtomicCommitUnit commit,
    bool isDark,
  ) {
    if (commit.id == 'none') {
      return Center(
        child: Text(
          'Select a commit to inspect properties',
          style: MacOSTheme.callout(isDark: isDark),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inspector Header
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: MacOSTheme.systemBlue(isDark)),
              const SizedBox(width: 6),
              Text(
                'COMMIT INSPECTOR',
                style: MacOSTheme.footnote(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary & Type
          Text(
            commit.summary,
            style: MacOSTheme.title2(isDark: isDark).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Hash & Branch Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MacOSTheme.systemBlue(isDark).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  commit.type,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MacOSTheme.systemBlue(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SHA: ${commit.id.substring(0, commit.id.length > 7 ? 7 : commit.id.length)}',
                style: MacOSTheme.code(
                  isDark: isDark,
                  fontSize: 10.5,
                  color: MacOSTheme.secondaryLabel(isDark),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Guardrail LOC Statistics
          _buildInspectorProperty(
            title: 'Changed Lines (LOC)',
            value: '+${commit.additions} / -${commit.deletions} (${commit.totalLoc} total)',
            isDark: isDark,
          ),
          _buildInspectorProperty(
            title: 'Branch Name',
            value: commit.branchName,
            isDark: isDark,
          ),
          _buildInspectorProperty(
            title: 'Parent Commit',
            value: commit.parentCommitId ?? 'Root commit',
            isDark: isDark,
          ),
          if (commit.prNumber != null)
            _buildInspectorProperty(
              title: 'GitHub PR',
              value: '#${commit.prNumber} (${commit.status.name})',
              isDark: isDark,
            ),

          const SizedBox(height: 16),
          Text(
            'Touched Files (${commit.changedFiles.length})',
            style: MacOSTheme.subheadline(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...commit.changedFiles.map(
            (file) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 13,
                    color: MacOSTheme.secondaryLabel(isDark),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      file,
                      style: MacOSTheme.code(
                        isDark: isDark,
                        fontSize: 11,
                        color: MacOSTheme.label(isDark),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorProperty({
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MacOSTheme.footnote(isDark: isDark).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: MacOSTheme.body(isDark: isDark).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
