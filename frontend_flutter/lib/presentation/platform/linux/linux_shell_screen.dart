import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../../domain/models/guardrail_policy.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/rebase_canvas_provider.dart';
import '../../providers/workspace_provider.dart';
import '../widgets/agent/agent_swimlane_card.dart';
import '../widgets/agent/prompt_stream_ticker.dart';
import '../widgets/diff/virtual_diff_viewer.dart';
import '../widgets/stack/pr_status_badge.dart';
import 'adw_action_card.dart';
import 'adw_header_bar.dart';
import 'adw_view_switcher.dart';
import 'linux_adwaita_theme.dart';

/// Complete Linux GNOME Desktop Workspace for Otto.
/// Follows GNOME Human Interface Guidelines (HIG) and Libadwaita patterns:
/// - AdwHeaderBar with window dragging, centered pill view switcher, and native GNOME controls
/// - AdwViewSwitcher: Sliced Diff, Rebase Playground, and Stack Pipeline
/// - AdwPreferencesGroup & AdwActionRow for policy compliance and settings
/// - Flat modern cards with 12px border radii and crisp dark/light contrast
/// - Cantarell & Ubuntu typography
class LinuxShellScreen extends ConsumerStatefulWidget {
  const LinuxShellScreen({super.key});

  @override
  ConsumerState<LinuxShellScreen> createState() => _LinuxShellScreenState();
}

class _LinuxShellScreenState extends ConsumerState<LinuxShellScreen> {
  OttoLinuxView _activeView = OttoLinuxView.slicedDiff;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Quick commit state
  String _selectedCommitType = 'feat';
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _summaryController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  void _openPreferencesDialog() {
    showDialog(
      context: context,
      builder: (_) => const _AdwPreferencesDialog(),
    );
  }

  Future<void> _handleCommit(List<DiffHunk> stagedHunks) async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty || stagedHunks.isEmpty) return;

    setState(() => _isCommitting = true);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);

    final commit = await workspaceNotifier.commitSelectedHunks(
      summary: summary,
      type: _selectedCommitType,
      scope: _scopeController.text.trim().isEmpty
          ? null
          : _scopeController.text.trim(),
      hunks: stagedHunks,
    );

    if (mounted) {
      setState(() => _isCommitting = false);
      if (commit != null) {
        _summaryController.clear();
        _scopeController.clear();
        ref.read(diffViewerProvider.notifier).clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.adwaita.success,
            content: Text(
              'Atomic commit "${commit.conventionalTitle}" created in stack.',
              style: AdwaitaTypography.cantarell.copyWith(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final rebaseState = ref.watch(rebaseCanvasProvider);

    // Staged hunks calculation
    final stagedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          setState(() => _isSearchOpen = !_isSearchOpen);
        },
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
          setState(() => _activeView = OttoLinuxView.slicedDiff);
        },
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () {
          setState(() => _activeView = OttoLinuxView.rebasePlayground);
        },
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () {
          setState(() => _activeView = OttoLinuxView.stackPipeline);
        },
      },
      child: Focus(
        autofocus: true,
        child: Theme(
          data: Theme.of(context).brightness == Brightness.dark
              ? LinuxAdwaitaTheme.darkTheme
              : LinuxAdwaitaTheme.lightTheme,
          child: Scaffold(
            backgroundColor: tokens.windowBg,
            body: Column(
              children: [
                // 1. Libadwaita Header Bar
                AdwHeaderBar(
                  currentBranch: workspace.currentBranch,
                  isDaemonConnected: true,
                  isSearchActive: _isSearchOpen,
                  isPushing: workspace.isLoading,
                  titleWidget: AdwViewSwitcher(
                    activeView: _activeView,
                    onViewChanged: (view) => setState(() => _activeView = view),
                    diffBadgeCount: workspace.uncommittedDiffs.length,
                    rebaseBadgeCount: rebaseState.isDirty
                        ? rebaseState.orderedCommitIds.length
                        : null,
                    stackBadgeCount: workspace.stackGraph.commits.length,
                  ),
                  onToggleSearch: () {
                    setState(() => _isSearchOpen = !_isSearchOpen);
                  },
                  onOpenSettings: _openPreferencesDialog,
                  onPushStack: () async {
                    final success = await workspaceNotifier.pushStack();
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: tokens.success,
                          content: Text(
                            'Stacked PRs successfully pushed to GitHub!',
                            style: AdwaitaTypography.cantarell.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),

                // 2. Sliding Search Bar (GNOME In-App Search)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _isSearchOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.headerBarBg,
                      border: Border(
                        bottom: BorderSide(color: tokens.border, width: 1.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: _isSearchOpen,
                            style: AdwaitaTypography.cantarell.copyWith(
                              fontSize: 13,
                              color: tokens.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText:
                                  'Filter diffs, commit titles, or branch names...',
                              hintStyle: AdwaitaTypography.cantarell.copyWith(
                                fontSize: 13,
                                color: tokens.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          tooltip: 'Close Search (Esc)',
                          onPressed: () {
                            setState(() {
                              _isSearchOpen = false;
                              _searchController.clear();
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Active View Content
                Expanded(
                  child: switch (_activeView) {
                    OttoLinuxView.slicedDiff => _buildSlicedDiffView(
                        context,
                        workspace,
                        diffState,
                        stagedHunks,
                      ),
                    OttoLinuxView.rebasePlayground => _buildRebasePlaygroundView(
                        context,
                        workspace,
                        rebaseState,
                      ),
                    OttoLinuxView.stackPipeline => _buildStackPipelineView(
                        context,
                        workspace,
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: SLICED DIFF & ATOMIC COMMITS
  // ==========================================
  Widget _buildSlicedDiffView(
    BuildContext context,
    WorkspaceState workspace,
    DiffViewerState diffState,
    List<DiffHunk> stagedHunks,
  ) {
    final tokens = context.adwaita;
    final llmState = ref.watch(llmSelectorProvider);
    final llmNotifier = ref.read(llmSelectorProvider.notifier);
    final diffNotifier = ref.read(diffViewerProvider.notifier);

    // Calculate staged additions and deletions
    final stagedAdditions = stagedHunks.fold<int>(
      0,
      (sum, h) =>
          sum +
          h.lines
              .where((l) =>
                  diffState.selectedLineIds.contains(l.id) &&
                  l.type == DiffLineType.addition)
              .length,
    );
    final stagedDeletions = stagedHunks.fold<int>(
      0,
      (sum, h) =>
          sum +
          h.lines
              .where((l) =>
                  diffState.selectedLineIds.contains(l.id) &&
                  l.type == DiffLineType.deletion)
              .length,
    );
    final totalStagedLoc = stagedAdditions + stagedDeletions;
    final maxLoc = workspace.guardrailPolicy.maxLocPerCommit;
    final isExceeding = totalStagedLoc > maxLoc;

    // Filter files if search is active
    final filteredFiles = _searchQuery.isEmpty
        ? workspace.uncommittedDiffs
        : workspace.uncommittedDiffs
            .where((f) => f.filePath.toLowerCase().contains(_searchQuery))
            .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Sidebar: Agents, Files & Guardrail Policy (~330px)
        Container(
          width: 330,
          decoration: BoxDecoration(
            color: tokens.viewBg,
            border: Border(
              right: BorderSide(color: tokens.border, width: 1.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Agents Swimlane Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: tokens.headerBarBg.withOpacity(0.5),
                  border: Border(
                    bottom: BorderSide(color: tokens.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 15, color: tokens.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Active IDE AI Agents',
                      style: AdwaitaTypography.cantarell.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    AdwBadge(
                      label: '${workspace.activeAgents.where((a) => a.isActive).length} active',
                      variant: AdwBadgeVariant.success,
                    ),
                  ],
                ),
              ),

              // Active Agents Cards
              ...workspace.activeAgents.map(
                (agent) => AgentSwimlaneCard(
                  agent: agent,
                  onSliceAgentChanges: () {
                    llmNotifier.refineUncommittedDiffs(
                      instructions: 'Slice changes by ${agent.name}',
                    );
                  },
                ),
              ),

              // AI Slice Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: FilledButton.icon(
                  onPressed: llmState.isRefining
                      ? null
                      : () => llmNotifier.refineUncommittedDiffs(),
                  icon: llmState.isRefining
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 14),
                  label: Text(
                    llmState.isRefining
                        ? 'AI Analyzing Slices...'
                        : 'AI Slice & Refine Stack',
                    style: AdwaitaTypography.cantarell.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    minimumSize: const Size.fromHeight(34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Changed Files Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Changed Files (${filteredFiles.length})',
                      style: AdwaitaTypography.cantarell.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    AdwBadge(
                      label: '${stagedHunks.length} hunks staged',
                      variant: stagedHunks.isNotEmpty
                          ? AdwBadgeVariant.accent
                          : AdwBadgeVariant.neutral,
                    ),
                  ],
                ),
              ),

              // Changed Files List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    final isActive = file.filePath == diffState.activeFilePath;

                    return AdwCard(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      backgroundColor: isActive
                          ? tokens.accent.withOpacity(0.12)
                          : tokens.cardBg,
                      customBorder: Border.all(
                        color: isActive ? tokens.accent : tokens.border,
                        width: isActive ? 1.5 : 0.5,
                      ),
                      onTap: () {
                        diffNotifier.setActiveFile(file.filePath);
                      },
                      child: Row(
                        children: [
                          Icon(
                            file.isNew
                                ? Icons.add_circle_outline_rounded
                                : file.isDeleted
                                    ? Icons.remove_circle_outline_rounded
                                    : Icons.description_outlined,
                            size: 15,
                            color: file.isNew
                                ? tokens.success
                                : file.isDeleted
                                    ? tokens.destructive
                                    : tokens.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.filePath.split('/').last,
                                  style: AdwaitaTypography.cantarell.copyWith(
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                Text(
                                  file.filePath,
                                  overflow: TextOverflow.ellipsis,
                                  style: AdwaitaTypography.cantarell.copyWith(
                                    fontSize: 10,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${file.additions} -${file.deletions}',
                            style: AdwaitaTypography.monospace.copyWith(
                              fontSize: 10.5,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Atomic PR Guardrail Meter Card
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExceeding
                      ? tokens.destructive.withOpacity(0.12)
                      : tokens.cardBg,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  border: Border.all(
                    color: isExceeding ? tokens.destructive : tokens.border,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isExceeding
                              ? Icons.warning_rounded
                              : Icons.verified_rounded,
                          size: 14,
                          color: isExceeding
                              ? tokens.destructive
                              : tokens.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Atomic PR Guardrail',
                          style: AdwaitaTypography.cantarell.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isExceeding
                                ? tokens.destructive
                                : tokens.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$totalStagedLoc / $maxLoc LOC',
                          style: AdwaitaTypography.monospace.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isExceeding
                                ? tokens.destructive
                                : tokens.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (totalStagedLoc / maxLoc).clamp(0.0, 1.0),
                        backgroundColor: tokens.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isExceeding ? tokens.destructive : tokens.accent,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Center Pane: Diff Viewer + Libadwaita Commit Strip
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prompt stream ticker if active
              if (llmState.activeStreamingText != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PromptStreamTicker(
                    text: llmState.activeStreamingText!,
                    isStreaming: llmState.isRefining,
                  ),
                ),

              // Virtualized Diff Viewer
              Expanded(
                child: VirtualDiffViewer(
                  fileDiffs: filteredFiles,
                ),
              ),

              // Libadwaita Commit Action Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: tokens.cardBg,
                  border: Border(
                    top: BorderSide(color: tokens.border, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    // Conventional Commit Type Dropdown
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: tokens.viewBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tokens.border, width: 0.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCommitType,
                          items: const [
                            DropdownMenuItem(value: 'feat', child: Text('feat')),
                            DropdownMenuItem(value: 'fix', child: Text('fix')),
                            DropdownMenuItem(
                                value: 'refactor', child: Text('refactor')),
                            DropdownMenuItem(value: 'perf', child: Text('perf')),
                            DropdownMenuItem(value: 'chore', child: Text('chore')),
                            DropdownMenuItem(value: 'docs', child: Text('docs')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCommitType = val);
                            }
                          },
                          style: AdwaitaTypography.cantarell.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tokens.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Scope Input
                    SizedBox(
                      width: 100,
                      height: 34,
                      child: TextField(
                        controller: _scopeController,
                        style: AdwaitaTypography.cantarell.copyWith(
                          fontSize: 12,
                          color: tokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'scope',
                          hintStyle: AdwaitaTypography.cantarell.copyWith(
                            fontSize: 12,
                            color: tokens.textMuted,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: tokens.viewBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                BorderSide(color: tokens.border, width: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Summary Input
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: TextField(
                          controller: _summaryController,
                          style: AdwaitaTypography.cantarell.copyWith(
                            fontSize: 12.5,
                            color: tokens.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Atomic commit summary (e.g. support libadwaita tokens)...',
                            hintStyle: AdwaitaTypography.cantarell.copyWith(
                              fontSize: 12.5,
                              color: tokens.textMuted,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: tokens.viewBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  BorderSide(color: tokens.border, width: 0.5),
                            ),
                          ),
                          onSubmitted: (_) => _handleCommit(stagedHunks),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Commit Slice Button (Suggested Action)
                    FilledButton.icon(
                      onPressed: (_isCommitting ||
                              stagedHunks.isEmpty ||
                              _summaryController.text.trim().isEmpty)
                          ? null
                          : () => _handleCommit(stagedHunks),
                      icon: _isCommitting
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 15),
                      label: Text(
                        'Commit Slice (${stagedHunks.length})',
                        style: AdwaitaTypography.cantarell.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: REBASE PLAYGROUND & SQUASH CANVAS
  // ==========================================
  Widget _buildRebasePlaygroundView(
    BuildContext context,
    WorkspaceState workspace,
    RebaseCanvasState rebaseState,
  ) {
    final tokens = context.adwaita;
    final rebaseNotifier = ref.read(rebaseCanvasProvider.notifier);
    final commitMap = {for (final c in workspace.stackGraph.commits) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rebase Controls Header Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.cardBg,
            border: Border(
              bottom: BorderSide(color: tokens.border, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.swap_vert_rounded, size: 20, color: tokens.accent),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interactive Stack Rebase Playground',
                    style: AdwaitaTypography.cantarell.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    'Drag commits to reorder the stack chain. Otto enforces DAG parent-child invariants.',
                    style: AdwaitaTypography.cantarell.copyWith(
                      fontSize: 11.5,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Reset Order
              if (rebaseState.isDirty)
                OutlinedButton(
                  onPressed: rebaseNotifier.reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.textSecondary,
                    side: BorderSide(color: tokens.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Reset Order'),
                ),
              const SizedBox(width: 8),

              // Apply Rebase
              FilledButton.icon(
                onPressed: (rebaseState.isDirty &&
                        rebaseState.isValid &&
                        !rebaseState.isRebasing)
                    ? () async {
                        final success = await rebaseNotifier.executeRebase();
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: tokens.success,
                              content: Text(
                                'Rebase applied successfully!',
                                style: AdwaitaTypography.cantarell.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                icon: rebaseState.isRebasing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.done_all_rounded, size: 15),
                label: const Text('Apply Rebase'),
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Validation / Warning Banner
        if (!rebaseState.isValid && rebaseState.errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: tokens.destructive.withOpacity(0.15),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 16, color: tokens.destructive),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rebaseState.errorMessage!,
                    style: AdwaitaTypography.cantarell.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.destructive,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Reorderable Commit Canvas
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            itemCount: rebaseState.orderedCommitIds.length,
            onReorder: rebaseNotifier.reorderCommit,
            itemBuilder: (context, index) {
              final commitId = rebaseState.orderedCommitIds[index];
              final commit = commitMap[commitId];
              if (commit == null) return SizedBox.shrink(key: ValueKey(commitId));

              return Container(
                key: ValueKey(commit.id),
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Position index pill
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.borderCrisp),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AdwaitaTypography.monospace.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Commit Card
                    Expanded(
                      child: AdwCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Reorder Drag Handle
                            Icon(
                              Icons.drag_indicator_rounded,
                              size: 18,
                              color: tokens.textMuted,
                            ),
                            const SizedBox(width: 10),

                            // Conventional Commit Badge
                            AdwBadge(
                              label: commit.type,
                              variant: switch (commit.type.toLowerCase()) {
                                'feat' => AdwBadgeVariant.accent,
                                'fix' => AdwBadgeVariant.success,
                                'refactor' => AdwBadgeVariant.warning,
                                _ => AdwBadgeVariant.neutral,
                              },
                            ),
                            const SizedBox(width: 10),

                            // Commit title & branch
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    commit.summary,
                                    style: AdwaitaTypography.cantarell.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        commit.branchName,
                                        style: AdwaitaTypography.monospace.copyWith(
                                          fontSize: 10.5,
                                          color: tokens.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+${commit.additions} -${commit.deletions} LOC',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // PR Status
                            PrStatusBadge(
                              status: commit.status,
                              prNumber: commit.prNumber,
                            ),
                          ],
                        ),
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

  // ==========================================
  // VIEW 3: STACK PIPELINE & POLICY INSPECTOR
  // ==========================================
  Widget _buildStackPipelineView(
    BuildContext context,
    WorkspaceState workspace,
  ) {
    final tokens = context.adwaita;
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final commits = workspace.stackGraph.commits;

    final selectedCommit = commits.firstWhere(
      (c) => c.id == workspace.selectedCommitId,
      orElse: () => commits.isNotEmpty ? commits.first : _dummyCommit,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: Linear Stack DAG Chain
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree_rounded,
                        size: 18, color: tokens.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Stacked PR Pipeline Chain (${commits.length} PRs)',
                      style: AdwaitaTypography.cantarell.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tree list
                Expanded(
                  child: ListView.builder(
                    itemCount: commits.length,
                    itemBuilder: (context, index) {
                      final commit = commits[index];
                      final isSelected = commit.id == selectedCommit.id;
                      final isTop = index == 0;
                      final isBottom = index == commits.length - 1;

                      return Stack(
                        children: [
                          // Tree connector vertical line
                          Positioned(
                            left: 19,
                            top: isTop ? 20 : 0,
                            bottom: isBottom ? 20 : 0,
                            child: Container(
                              width: 2,
                              color: isSelected
                                  ? tokens.accent
                                  : tokens.borderCrisp,
                            ),
                          ),

                          // Node circle
                          Positioned(
                            left: 15,
                            top: 20,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isSelected ? tokens.accent : tokens.cardBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? tokens.accent
                                      : tokens.borderCrisp,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),

                          // Commit Card
                          Padding(
                            padding: const EdgeInsets.only(left: 32, bottom: 8),
                            child: AdwCard(
                              backgroundColor: isSelected
                                  ? tokens.accent.withOpacity(0.08)
                                  : tokens.cardBg,
                              customBorder: Border.all(
                                color: isSelected ? tokens.accent : tokens.border,
                                width: isSelected ? 1.5 : 0.5,
                              ),
                              onTap: () {
                                workspaceNotifier.selectCommit(commit.id);
                              },
                              child: Row(
                                children: [
                                  AdwBadge(
                                    label: commit.type,
                                    variant: switch (commit.type.toLowerCase()) {
                                      'feat' => AdwBadgeVariant.accent,
                                      'fix' => AdwBadgeVariant.success,
                                      'refactor' => AdwBadgeVariant.warning,
                                      _ => AdwBadgeVariant.neutral,
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          commit.summary,
                                          style: AdwaitaTypography.cantarell
                                              .copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'branch: ${commit.branchName} • ${commit.totalLoc} LOC',
                                          style: AdwaitaTypography.monospace
                                              .copyWith(
                                            fontSize: 10.5,
                                            color: tokens.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PrStatusBadge(
                                    status: commit.status,
                                    prNumber: commit.prNumber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Pane: Libadwaita Policy & Commit Inspector (~380px)
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: tokens.viewBg,
            border: Border(
              left: BorderSide(color: tokens.border, width: 1.0),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selected Commit Card
                AdwCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.commit_rounded,
                              size: 16, color: tokens.accent),
                          const SizedBox(width: 6),
                          Text(
                            selectedCommit.id.substring(0, 8),
                            style: AdwaitaTypography.monospace.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tokens.accent,
                            ),
                          ),
                          const Spacer(),
                          PrStatusBadge(
                            status: selectedCommit.status,
                            prNumber: selectedCommit.prNumber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedCommit.conventionalTitle,
                        style: AdwaitaTypography.cantarell.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Author: ${selectedCommit.author}',
                        style: AdwaitaTypography.cantarell.copyWith(
                          fontSize: 11,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Group 1: Atomic PR Guardrail Compliance
                AdwPreferencesGroup(
                  title: 'GUARDRAIL COMPLIANCE',
                  description: 'Policy validation against current repository rules.',
                  children: [
                    AdwActionRow(
                      icon: Icon(
                        selectedCommit.exceedsLocThreshold
                            ? Icons.cancel_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                        color: selectedCommit.exceedsLocThreshold
                            ? tokens.destructive
                            : tokens.success,
                      ),
                      title: 'Lines of Code (LOC)',
                      subtitle:
                          '${selectedCommit.totalLoc} / ${workspace.guardrailPolicy.maxLocPerCommit} LOC',
                      trailing: AdwBadge(
                        label: selectedCommit.exceedsLocThreshold
                            ? 'EXCEEDS LIMIT'
                            : 'PASS',
                        variant: selectedCommit.exceedsLocThreshold
                            ? AdwBadgeVariant.destructive
                            : AdwBadgeVariant.success,
                      ),
                    ),
                    AdwActionRow(
                      icon: Icon(
                        selectedCommit.exceedsFileThreshold
                            ? Icons.cancel_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                        color: selectedCommit.exceedsFileThreshold
                            ? tokens.destructive
                            : tokens.success,
                      ),
                      title: 'Files Changed',
                      subtitle:
                          '${selectedCommit.changedFiles.length} / ${workspace.guardrailPolicy.maxFilesPerCommit} files',
                      trailing: AdwBadge(
                        label: selectedCommit.exceedsFileThreshold
                            ? 'TOO BROAD'
                            : 'PASS',
                        variant: selectedCommit.exceedsFileThreshold
                            ? AdwBadgeVariant.destructive
                            : AdwBadgeVariant.success,
                      ),
                    ),
                    AdwActionRow(
                      icon: Icon(Icons.check_circle_rounded,
                          size: 18, color: tokens.success),
                      title: 'Conventional Commit Syntax',
                      subtitle: 'Prefix "${selectedCommit.type}" is recognized',
                      trailing: const AdwBadge(
                        label: 'COMPLIANT',
                        variant: AdwBadgeVariant.success,
                      ),
                    ),
                  ],
                ),

                // Group 2: Branch & PR Context
                AdwPreferencesGroup(
                  title: 'BRANCH & DEPENDENCY GRAPH',
                  children: [
                    AdwActionRow(
                      icon: const Icon(Icons.fork_right_rounded, size: 18),
                      title: 'Branch Name',
                      subtitle: selectedCommit.branchName,
                    ),
                    AdwActionRow(
                      icon: const Icon(Icons.north_east_rounded, size: 18),
                      title: 'Base Branch',
                      subtitle: workspace.currentBranch,
                    ),
                    if (selectedCommit.prNumber != null)
                      AdwActionRow(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        title: 'GitHub Pull Request',
                        subtitle: '#${selectedCommit.prNumber}',
                        onTap: () {},
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static final AtomicCommitUnit _dummyCommit = AtomicCommitUnit(
    summary: 'Initial stack workspace setup',
    branchName: 'main',
    type: 'chore',
  );
}

/// Authentic GNOME Libadwaita Preferences Modal.
class _AdwPreferencesDialog extends ConsumerStatefulWidget {
  const _AdwPreferencesDialog();

  @override
  ConsumerState<_AdwPreferencesDialog> createState() =>
      _AdwPreferencesDialogState();
}

class _AdwPreferencesDialogState
    extends ConsumerState<_AdwPreferencesDialog> {
  late double _maxLoc;
  late int _maxFiles;
  late bool _enforceConventional;

  @override
  void initState() {
    super.initState();
    final policy = ref.read(workspaceProvider).guardrailPolicy;
    _maxLoc = policy.maxLocPerCommit.toDouble();
    _maxFiles = policy.maxFilesPerCommit;
    _enforceConventional = policy.enforceConventionalCommits;
  }

  void _saveSettings() {
    final updatedPolicy = GuardrailPolicy(
      maxLocPerCommit: _maxLoc.toInt(),
      maxFilesPerCommit: _maxFiles,
      enforceConventionalCommits: _enforceConventional,
    );

    ref.read(workspaceProvider.notifier).updateGuardrailPolicy(updatedPolicy);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final llmState = ref.watch(llmSelectorProvider);
    final llmNotifier = ref.read(llmSelectorProvider.notifier);

    return Dialog(
      backgroundColor: tokens.windowBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.borderCrisp, width: 1.0),
      ),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: tokens.accent),
                  const SizedBox(width: 10),
                  Text(
                    'Preferences',
                    style: AdwaitaTypography.cantarell.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Group 1: Atomic PR Policy
              AdwPreferencesGroup(
                title: 'ATOMIC GIT GUARDRAILS',
                description:
                    'Automated repository limits enforced on commits and PRs.',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Lines of Code per Commit',
                              style: AdwaitaTypography.cantarell.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_maxLoc.toInt()} LOC',
                              style: AdwaitaTypography.monospace.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tokens.accent,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _maxLoc,
                          min: 30,
                          max: 200,
                          divisions: 17,
                          activeColor: tokens.accent,
                          onChanged: (val) => setState(() => _maxLoc = val),
                        ),
                      ],
                    ),
                  ),
                  AdwActionRow(
                    title: 'Max Files per Commit',
                    trailing: DropdownButton<int>(
                      value: _maxFiles,
                      items: [1, 2, 3, 5, 8]
                          .map((n) =>
                              DropdownMenuItem(value: n, child: Text('$n files')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _maxFiles = val);
                      },
                    ),
                  ),
                  AdwSwitchRow(
                    title: 'Enforce Conventional Commits',
                    subtitle: 'Requires feat, fix, refactor, or chore prefixes',
                    value: _enforceConventional,
                    onChanged: (val) =>
                        setState(() => _enforceConventional = val),
                  ),
                ],
              ),

              // Group 2: AI Provider
              AdwPreferencesGroup(
                title: 'AI DIFF REFINEMENT PROVIDER',
                children: [
                  AdwActionRow(
                    title: 'Provider Model',
                    trailing: DropdownButton<String>(
                      value: llmState.selectedProvider.id,
                      items: llmState.providers.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (${p.provider})'),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          final prov =
                              llmState.providers.firstWhere((p) => p.id == id);
                          llmNotifier.selectProvider(prov);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.textSecondary,
                      side: BorderSide(color: tokens.borderCrisp),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saveSettings,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accent,
                    ),
                    child: const Text('Save Changes'),
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
