import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../../domain/models/ide_agent_profile.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/hotkey_hud_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/rebase_canvas_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/agent/agent_swimlane_card.dart';
import '../../widgets/agent/prompt_stream_ticker.dart';
import '../../widgets/diff/virtual_diff_viewer.dart';
import '../../widgets/hud/floating_hud_card.dart';
import '../../widgets/stack/commit_card_item.dart';
import '../../widgets/stack/reorder_drag_handle.dart';
import '../../widgets/stack/stacked_pr_tree_view.dart';
import '../../screens/settings_dialog.dart';
import 'windows_command_bar.dart';
import 'windows_content_dialog.dart';
import 'windows_fluent_theme.dart';
import 'windows_navigation_view.dart';
import 'windows_title_bar.dart';

/// Complete Windows 11 Fluent Desktop Workspace screen.
/// Implements authentic Fluent Design System 2 guidelines (Mica, Acrylic,
/// Segoe UI Variable typography, CommandBar, NavigationView, ContentDialogs),
/// integrating diff viewing, stacked PR tree, rebase playground, and agent swimlanes.
class WindowsShellScreen extends ConsumerStatefulWidget {
  const WindowsShellScreen({super.key});

  @override
  ConsumerState<WindowsShellScreen> createState() => _WindowsShellScreenState();
}

class _WindowsShellScreenState extends ConsumerState<WindowsShellScreen> {
  int _selectedTabIndex = 0;
  bool _isAutoPilot = false;
  String _searchFilter = '';

  // Quick commit controllers
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  String _selectedCommitType = 'feat';
  bool _isGeneratingAiCommit = false;
  bool _isCommitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  void _showFluentInfoBar({required String message, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? FluentMicaColors.closeButtonPressed : const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(8),
            boxShadow: FluentElevation.flyout(true),
            border: Border.all(
              color: isError ? FluentMicaColors.closeButtonHover : FluentMicaColors.gitAdded,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: FluentTypography.bodyStrong.copyWith(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSyncNow() async {
    final workspace = ref.read(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);

    final shouldPush = await FluentContentDialog.show<bool>(
      context: context,
      builder: (_) => GitConfirmationDialog(
        commits: workspace.stackGraph.commits,
        branch: workspace.currentBranch,
        onConfirmPush: ({required bool forceWithLease}) async {
          return await workspaceNotifier.pushStack();
        },
      ),
    );

    if (shouldPush == true) {
      _showFluentInfoBar(
        message: 'Successfully pushed ${workspace.stackGraph.commits.length} atomic commits to GitHub!',
      );
    }
  }

  Future<void> _handleSplitCommit(List<DiffHunk> stagedHunks) async {
    final workspaceNotifier = ref.read(workspaceProvider.notifier);

    await FluentContentDialog.show(
      context: context,
      builder: (_) => SplitCommitDialog(
        hunks: stagedHunks,
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
          _showFluentInfoBar(message: 'Atomic PR commit "$type($scope): $summary" created.');
        },
      ),
    );
  }

  Future<void> _generateAiCommit(List<DiffHunk> stagedHunks) async {
    if (stagedHunks.isEmpty) return;
    setState(() => _isGeneratingAiCommit = true);
    try {
      final res = await ref
          .read(llmSelectorProvider.notifier)
          .generateConventionalCommit(stagedHunks);

      setState(() {
        _selectedCommitType = res.type;
        _summaryController.text = res.summary;
        if (res.scope != null) _scopeController.text = res.scope!;
      });
    } catch (e) {
      _showFluentInfoBar(message: 'Failed to generate commit: $e', isError: true);
    } finally {
      setState(() => _isGeneratingAiCommit = false);
    }
  }

  Future<void> _submitQuickCommit(List<DiffHunk> stagedHunks) async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty || stagedHunks.isEmpty) return;

    setState(() => _isCommitting = true);
    try {
      final commit = await ref.read(workspaceProvider.notifier).commitSelectedHunks(
            summary: summary,
            type: _selectedCommitType,
            scope: _scopeController.text.trim().isEmpty ? null : _scopeController.text.trim(),
            hunks: stagedHunks,
          );

      if (commit != null) {
        _summaryController.clear();
        _scopeController.clear();
        final hashStr = commit.id.length >= 7 ? commit.id.substring(0, 7) : commit.id;
        _showFluentInfoBar(message: 'Committed $hashStr: ${commit.conventionalTitle}');
      }
    } catch (e) {
      _showFluentInfoBar(message: 'Commit failed: $e', isError: true);
    } finally {
      setState(() => _isCommitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final hudState = ref.watch(hotkeyHudProvider);
    final llmState = ref.watch(llmSelectorProvider);
    final rebaseState = ref.watch(rebaseCanvasProvider);
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Current staged hunks across all files
    final stagedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    // Filter uncommitted diffs based on search input
    final filteredDiffs = _searchFilter.isEmpty
        ? workspace.uncommittedDiffs
        : workspace.uncommittedDiffs
            .where((f) =>
                f.filePath.toLowerCase().contains(_searchFilter.toLowerCase()) ||
                f.hunks.any((h) => h.lines.any(
                    (l) => l.content.toLowerCase().contains(_searchFilter.toLowerCase()))))
            .toList();

    final navItems = [
      FluentNavigationItem(
        label: 'Stacked PRs',
        icon: Icons.account_tree_outlined,
        selectedIcon: Icons.account_tree_rounded,
        badgeCount: workspace.stackGraph.commits.length,
      ),
      FluentNavigationItem(
        label: 'Diff Viewer',
        icon: Icons.difference_outlined,
        selectedIcon: Icons.difference_rounded,
        badgeCount: workspace.uncommittedDiffs.length,
      ),
      FluentNavigationItem(
        label: 'Rebase Playground',
        icon: Icons.tune_rounded,
        selectedIcon: Icons.tune,
        badgeText: rebaseState.isDirty ? 'DIRTY' : null,
        badgeColor: rebaseState.isDirty ? FluentMicaColors.gitModified : null,
      ),
      FluentNavigationItem(
        label: 'AI Agents',
        icon: Icons.smart_toy_outlined,
        selectedIcon: Icons.smart_toy_rounded,
        badgeCount: workspace.activeAgents.where((a) => a.isActive).length,
        badgeColor: FluentMicaColors.gitAdded,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FluentMicaBackdrop(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Windows 11 Titlebar
                WindowsTitleBar(
                  title: 'Otto',
                  subtitle: 'Windows 11 Fluent Workspace • ${workspace.currentBranch}',
                ),

                // 2. Main Navigation Rail + Workspace Canvas
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left: Fluent NavigationView
                      WindowsNavigationView(
                        selectedIndex: _selectedTabIndex,
                        onIndexChanged: (idx) => setState(() => _selectedTabIndex = idx),
                        items: navItems,
                        activeAgents: workspace.activeAgents,
                        onSearchChanged: (val) => setState(() => _searchFilter = val),
                        onAgentSelected: (agent) {
                          setState(() {
                            _selectedTabIndex = 3; // Switch to AI agents tab
                          });
                        },
                        onSliceAgentChanges: (agent) {
                          ref.read(llmSelectorProvider.notifier).refineUncommittedDiffs(
                                instructions: 'Slice changes by ${agent.name}',
                              );
                        },
                        onOpenSettings: () {
                          showDialog(
                            context: context,
                            builder: (_) => const SettingsDialog(),
                          );
                        },
                      ),

                      // Center: Workspace Body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top CommandBar
                            WindowsCommandBar(
                              currentBranch: workspace.currentBranch,
                              pendingCommitCount: workspace.stackGraph.commits.length,
                              isSyncing: workspace.isLoading,
                              isRefining: llmState.isRefining,
                              isAutoPilot: _isAutoPilot,
                              userSession: authState.session,
                              onSyncNow: _handleSyncNow,
                              onRefineWithAi: () => ref
                                  .read(llmSelectorProvider.notifier)
                                  .refineUncommittedDiffs(),
                              onAutoPilotChanged: (val) {
                                setState(() => _isAutoPilot = val);
                                _showFluentInfoBar(
                                  message: val
                                      ? 'Auto-Pilot enabled: autonomous atomic hunk slicing active'
                                      : 'Auto-Pilot disabled',
                                );
                              },
                              onOpenRebase: () => setState(() => _selectedTabIndex = 2),
                              onToggleHud: () =>
                                  ref.read(hotkeyHudProvider.notifier).toggleHud(),
                              onOpenSettings: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const SettingsDialog(),
                                );
                              },
                              onSignOut: () =>
                                  ref.read(authStateProvider.notifier).signOut(),
                            ),

                            // AI Streaming Ticker Bar
                            if (llmState.activeStreamingText != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? FluentMicaColors.layerBackgroundDark
                                      : FluentMicaColors.layerBackgroundLight,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark
                                          ? FluentMicaColors.dividerStrokeDark
                                          : FluentMicaColors.dividerStrokeLight,
                                    ),
                                  ),
                                ),
                                child: PromptStreamTicker(
                                  text: llmState.activeStreamingText!,
                                  isStreaming: llmState.isRefining,
                                ),
                              ),

                            // Dynamic Workspace Content
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: switch (_selectedTabIndex) {
                                  0 => _buildStackedPrAndDiffView(
                                      context: context,
                                      workspace: workspace,
                                      diffs: filteredDiffs,
                                      stagedHunks: stagedHunks,
                                      isDark: isDark,
                                    ),
                                  1 => _buildDiffViewerOnlyView(
                                      context: context,
                                      diffs: filteredDiffs,
                                      stagedHunks: stagedHunks,
                                      isDark: isDark,
                                    ),
                                  2 => _buildRebasePlaygroundView(
                                      context: context,
                                      workspace: workspace,
                                      rebaseState: rebaseState,
                                      isDark: isDark,
                                    ),
                                  3 => _buildAgentSwimlanesView(
                                      context: context,
                                      workspace: workspace,
                                      isDark: isDark,
                                    ),
                                  _ => const SizedBox.shrink(),
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Floating HUD Overlay (Activated via CommandBar or hotkey)
            if (hudState.isHudVisible)
              const Positioned(
                top: 50,
                right: 20,
                width: 520,
                height: 430,
                child: FloatingHudCard(),
              ),
          ],
        ),
      ),
    );
  }

  /// Primary 2-pane workspace: Stacked PR tree on left, Virtual Diff on right.
  Widget _buildStackedPrAndDiffView({
    required BuildContext context,
    required WorkspaceState workspace,
    required List<FileDiff> diffs,
    required List<DiffHunk> stagedHunks,
    required bool isDark,
  }) {
    final workspaceNotifier = ref.read(workspaceProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Sub-Pane: Stacked PR Tree (~340px)
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: isDark
                ? FluentMicaColors.layerBackgroundAltDark
                : FluentMicaColors.layerBackgroundAltLight,
            border: Border(
              right: BorderSide(
                color: isDark
                    ? FluentMicaColors.dividerStrokeDark
                    : FluentMicaColors.dividerStrokeLight,
              ),
            ),
          ),
          child: Column(
            children: [
              // Stack Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? FluentMicaColors.dividerStrokeDark
                          : FluentMicaColors.dividerStrokeLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.layers_rounded,
                      size: 16,
                      color: isDark
                          ? FluentMicaColors.accentLight
                          : FluentMicaColors.accentIndigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stacked PR Chain',
                      style: FluentTypography.bodyStrong.copyWith(
                        fontSize: 13,
                        color: isDark
                            ? FluentMicaColors.textPrimaryDark
                            : FluentMicaColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${workspace.stackGraph.commits.length} commits',
                        style: FluentTypography.captionStrong.copyWith(
                          fontSize: 10,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stack Tree
              Expanded(
                child: StackedPrTreeView(
                  commits: workspace.stackGraph.commits,
                  selectedCommitId: workspace.selectedCommitId,
                  onCommitSelected: (c) => workspaceNotifier.selectCommit(c.id),
                  onOpenRebaseCanvas: () => setState(() => _selectedTabIndex = 2),
                ),
              ),
            ],
          ),
        ),

        // Center Sub-Pane: Diff Viewer + Fluent Quick Commit Strip
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: VirtualDiffViewer(fileDiffs: diffs),
              ),
              _buildFluentQuickCommitStrip(stagedHunks: stagedHunks, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }

  /// Full-width Diff Viewer tab view.
  Widget _buildDiffViewerOnlyView({
    required BuildContext context,
    required List<FileDiff> diffs,
    required List<DiffHunk> stagedHunks,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: VirtualDiffViewer(fileDiffs: diffs),
        ),
        _buildFluentQuickCommitStrip(stagedHunks: stagedHunks, isDark: isDark),
      ],
    );
  }

  /// Interactive Rebase Playground tab view with DAG validation and drag-and-drop reordering.
  Widget _buildRebasePlaygroundView({
    required BuildContext context,
    required WorkspaceState workspace,
    required RebaseCanvasState rebaseState,
    required bool isDark,
  }) {
    final rebaseNotifier = ref.read(rebaseCanvasProvider.notifier);
    final commitMap = {for (final c in workspace.stackGraph.commits) c.id: c};

    return Container(
      color: isDark
          ? FluentMicaColors.layerBackgroundDark
          : FluentMicaColors.layerBackgroundLight,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rebase Header Toolbar
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault,
              ),
              const SizedBox(width: 10),
              Text(
                'Interactive Rebase Canvas',
                style: FluentTypography.subtitle.copyWith(
                  color: isDark
                      ? FluentMicaColors.textPrimaryDark
                      : FluentMicaColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 14),

              // DAG Validation Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rebaseState.isValid
                      ? (isDark
                          ? FluentMicaColors.gitAddedSubtleDark
                          : FluentMicaColors.gitAddedSubtleLight)
                      : (isDark
                          ? FluentMicaColors.gitRemovedSubtleDark
                          : FluentMicaColors.gitRemovedSubtleLight),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: rebaseState.isValid
                        ? FluentMicaColors.gitAdded
                        : FluentMicaColors.gitRemoved,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rebaseState.isValid
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 13,
                      color: rebaseState.isValid
                          ? FluentMicaColors.gitAdded
                          : FluentMicaColors.gitRemoved,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rebaseState.isValid ? 'DAG VALID' : 'DAG CONFLICT',
                      style: FluentTypography.captionStrong.copyWith(
                        fontSize: 11,
                        color: rebaseState.isValid
                            ? FluentMicaColors.gitAdded
                            : FluentMicaColors.gitRemoved,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              if (rebaseState.isDirty)
                FluentButton(
                  onPressed: rebaseNotifier.reset,
                  style: FluentButtonStyle.subtle,
                  child: const Text('Reset Order'),
                ),

              const SizedBox(width: 10),

              FluentButton(
                onPressed: (rebaseState.isDirty && rebaseState.isValid && !rebaseState.isRebasing)
                    ? () {
                        FluentContentDialog.show(
                          context: context,
                          builder: (_) => RebaseActionDialog(
                            reorderedCommitCount: rebaseState.orderedCommitIds.length,
                            isValid: rebaseState.isValid,
                            onExecuteRebase: () async {
                              final success = await rebaseNotifier.executeRebase();
                              if (success) {
                                _showFluentInfoBar(
                                  message: 'Stack rebase successfully executed and linearized!',
                                );
                              }
                            },
                          ),
                        );
                      }
                    : null,
                style: FluentButtonStyle.accent,
                child: Text(rebaseState.isRebasing ? 'Rebasing...' : 'Apply Rebase'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Drag and drop commits to reorganize your linear stack. Dependencies and parent SHAs will be automatically validated.',
            style: FluentTypography.body.copyWith(
              color: isDark
                  ? FluentMicaColors.textSecondaryDark
                  : FluentMicaColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: 16),

          // Reorderable Commit List
          Expanded(
            child: rebaseState.orderedCommitIds.isEmpty
                ? Center(
                    child: Text(
                      'No stacked commits found in workspace.',
                      style: FluentTypography.body.copyWith(
                        color: isDark
                            ? FluentMicaColors.textTertiaryDark
                            : FluentMicaColors.textTertiaryLight,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: rebaseState.orderedCommitIds.length,
                    onReorder: (oldIndex, newIndex) {
                      rebaseNotifier.reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final id = rebaseState.orderedCommitIds[index];
                      final commit = commitMap[id];
                      if (commit == null) return SizedBox.shrink(key: ValueKey(id));

                      return Container(
                        key: ValueKey(commit.id),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            ReorderDragHandle(index: index),
                            Expanded(
                              child: CommitCardItem(
                                commit: commit,
                                isSelected: workspace.selectedCommitId == commit.id,
                                onTap: () => workspaceNotifier.selectCommit(commit.id),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// AI Agent Swimlanes tab view.
  Widget _buildAgentSwimlanesView({
    required BuildContext context,
    required WorkspaceState workspace,
    required bool isDark,
  }) {
    return Container(
      color: isDark
          ? FluentMicaColors.layerBackgroundDark
          : FluentMicaColors.layerBackgroundLight,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentIndigo,
              ),
              const SizedBox(width: 10),
              Text(
                'IDE AI Agent Swimlanes',
                style: FluentTypography.subtitle.copyWith(
                  color: isDark
                      ? FluentMicaColors.textPrimaryDark
                      : FluentMicaColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              FluentButton(
                onPressed: () => ref
                    .read(llmSelectorProvider.notifier)
                    .refineUncommittedDiffs(instructions: 'Re-analyze all active agent changes'),
                style: FluentButtonStyle.accent,
                icon: Icons.auto_awesome_rounded,
                child: const Text('Slice All Agent Changes'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final agent in workspace.activeAgents)
                  FluentCard(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(16),
                    child: AgentSwimlaneCard(
                      agent: agent,
                      onSliceAgentChanges: () {
                        ref.read(llmSelectorProvider.notifier).refineUncommittedDiffs(
                              instructions: 'Slice changes by ${agent.name}',
                            );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Windows 11 Fluent Quick Commit Strip at the bottom of the Diff Viewer.
  Widget _buildFluentQuickCommitStrip({
    required List<DiffHunk> stagedHunks,
    required bool isDark,
  }) {
    final hasStaged = stagedHunks.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? FluentMicaColors.layerBackgroundDark
            : FluentMicaColors.layerBackgroundLight,
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
        children: [
          // Staged Hunks Counter Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasStaged
                  ? (isDark
                      ? FluentMicaColors.accentLight.withOpacity(0.18)
                      : FluentMicaColors.accentDefault.withOpacity(0.12))
                  : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEFEFEF)),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: hasStaged
                    ? (isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_box_outlined,
                  size: 13,
                  color: hasStaged
                      ? (isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault)
                      : (isDark ? FluentMicaColors.textTertiaryDark : FluentMicaColors.textTertiaryLight),
                ),
                const SizedBox(width: 6),
                Text(
                  '${stagedHunks.length} hunks staged',
                  style: FluentTypography.captionStrong.copyWith(
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: hasStaged
                        ? (isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault)
                        : (isDark ? FluentMicaColors.textTertiaryDark : FluentMicaColors.textTertiaryLight),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Conventional Commit Type Dropdown
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark
                    ? FluentMicaColors.cardStrokeDark
                    : FluentMicaColors.cardStrokeLight,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCommitType,
                style: FluentTypography.bodyStrong.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? FluentMicaColors.textPrimaryDark
                      : FluentMicaColors.textPrimaryLight,
                ),
                dropdownColor: isDark
                    ? FluentMicaColors.layerBackgroundDark
                    : FluentMicaColors.layerBackgroundLight,
                items: ['feat', 'fix', 'refactor', 'perf', 'docs', 'test', 'chore']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCommitType = val);
                },
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Scope Input
          Container(
            width: 100,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF9F9F9),
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
                hintText: '(scope)',
                hintStyle: FluentTypography.caption.copyWith(
                  color: isDark
                      ? FluentMicaColors.textTertiaryDark
                      : FluentMicaColors.textTertiaryLight,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Summary Input
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark
                      ? FluentMicaColors.cardStrokeDark
                      : FluentMicaColors.cardStrokeLight,
                ),
              ),
              child: TextField(
                controller: _summaryController,
                onSubmitted: (_) => _submitQuickCommit(stagedHunks),
                style: FluentTypography.body.copyWith(fontSize: 12.5),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  hintText: 'Commit summary (Ctrl+Enter to commit)',
                  hintStyle: FluentTypography.caption.copyWith(
                    color: isDark
                        ? FluentMicaColors.textTertiaryDark
                        : FluentMicaColors.textTertiaryLight,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // AI Generate Message Button
          FluentButton(
            onPressed: (hasStaged && !_isGeneratingAiCommit)
                ? () => _generateAiCommit(stagedHunks)
                : null,
            style: FluentButtonStyle.subtle,
            tooltip: 'Generate Conventional Commit with AI',
            child: _isGeneratingAiCommit
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 14),
          ),

          const SizedBox(width: 6),

          // Split Commit Dialog Launcher
          FluentButton(
            onPressed: hasStaged ? () => _handleSplitCommit(stagedHunks) : null,
            style: FluentButtonStyle.standard,
            tooltip: 'Slice staged diffs into dedicated atomic PR commit',
            child: const Text('Split Commit...'),
          ),

          const SizedBox(width: 6),

          // Commit Staged Button (Accent Style)
          FluentButton(
            onPressed: (hasStaged && !_isCommitting && _summaryController.text.trim().isNotEmpty)
                ? () => _submitQuickCommit(stagedHunks)
                : null,
            style: FluentButtonStyle.accent,
            tooltip: 'Commit staged hunks to stack',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isCommitting) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                ],
                const Text('Commit Staged'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
