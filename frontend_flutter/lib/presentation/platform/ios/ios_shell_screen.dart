import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/rebase_canvas_provider.dart';
import '../../providers/workspace_provider.dart';
import 'ios_cupertino_theme.dart';
import 'ios_navigation_bar.dart';
import 'ios_sheet_modal.dart';
import 'ios_swipeable_commit_card.dart';
import 'ios_tab_bar.dart';

/// Complete Apple iOS 17/18 Human Interface Guidelines companion shell screen
/// for Otto, integrating Riverpod state management, Cupertino styling,
/// collapsible large title headers, and native swipe gestures.
class IosShellScreen extends ConsumerStatefulWidget {
  const IosShellScreen({super.key});

  @override
  ConsumerState<IosShellScreen> createState() => _IosShellScreenState();
}

class _IosShellScreenState extends ConsumerState<IosShellScreen> {
  int _currentTab = 1; // Default to Stacked PRs

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final rebaseState = ref.watch(rebaseCanvasProvider);

    final uncommittedCount = workspace.uncommittedDiffs.fold<int>(
      0,
      (acc, file) => acc + file.hunks.length,
    );
    final stackCount = workspace.stackGraph.commits.length;

    return CupertinoTheme(
      data: IosCupertinoTheme.isDark(context)
          ? IosCupertinoTheme.darkTheme
          : IosCupertinoTheme.lightTheme,
      child: CupertinoPageScaffold(
        backgroundColor: IosColors.resolve(IosColors.systemGroupedBackground, context),
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: const [
                  _IosDiffReviewView(),
                  _IosStackedPrsView(),
                  _IosRebasePlaygroundView(),
                  _IosAiRefinerView(),
                ],
              ),
            ),
            IosTabBar(
              currentIndex: _currentTab,
              onTabSelected: (index) => setState(() => _currentTab = index),
              diffCount: uncommittedCount > 0 ? uncommittedCount : null,
              stackCount: stackCount > 0 ? stackCount : null,
              hasRebaseChanges: rebaseState.isDirty,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 0: DIFF REVIEW VIEW
// =============================================================================

class _IosDiffReviewView extends ConsumerStatefulWidget {
  const _IosDiffReviewView();

  @override
  ConsumerState<_IosDiffReviewView> createState() => _IosDiffReviewViewState();
}

class _IosDiffReviewViewState extends ConsumerState<_IosDiffReviewView> {
  int _filterSegment = 0; // 0: All Diffs, 1: Staged Only
  final TextEditingController _summaryController = TextEditingController();
  String _selectedCommitType = 'feat';
  bool _isCommitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final diffNotifier = ref.read(diffViewerProvider.notifier);
    final isDark = IosCupertinoTheme.isDark(context);

    final allHunks = workspace.uncommittedDiffs.expand((f) => f.hunks).toList();
    final stagedHunks = allHunks
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    final displayedFiles = _filterSegment == 0
        ? workspace.uncommittedDiffs
        : workspace.uncommittedDiffs
            .map((f) => FileDiff(
                  filePath: f.filePath,
                  oldPath: f.oldPath,
                  hunks: f.hunks
                      .where((h) => diffState.selectedHunkIds.contains(h.id))
                      .toList(),
                ))
            .where((f) => f.hunks.isNotEmpty)
            .toList();

    return CupertinoPageScaffold(
      backgroundColor: IosColors.resolve(IosColors.systemGroupedBackground, context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Collapsible Large Title Navigation Bar
          IosSliverNavigationBar(
            title: 'Diff Review',
            branchName: workspace.currentBranch,
            onAvatarTap: () => _openClerkProfile(context),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: () => _openAiRefiner(context),
              child: Icon(
                CupertinoIcons.sparkles,
                size: 22,
                color: IosColors.resolve(IosColors.systemIndigo, context),
              ),
            ),
          ),

          // Pull to Refresh
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await workspaceNotifier.refreshWorkspace();
            },
          ),

          // Segmented Control Filter (All Changes vs Staged)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: IosSegmentedControl<int>(
                groupValue: _filterSegment,
                children: {
                  0: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('All Changes (${allHunks.length})'),
                  ),
                  1: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Staged (${stagedHunks.length})'),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) setState(() => _filterSegment = val);
                },
              ),
            ),
          ),

          // Quick Stage Actions Row
          if (allHunks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${stagedHunks.length} of ${allHunks.length} hunks selected',
                      style: IosTypography.footnote.copyWith(
                        color: IosColors.resolve(IosColors.secondaryLabel, context),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 28,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (stagedHunks.length == allHunks.length) {
                          diffNotifier.clearSelection();
                        } else {
                          diffNotifier.selectAllHunks(allHunks);
                        }
                      },
                      child: Text(
                        stagedHunks.length == allHunks.length ? 'Deselect All' : 'Stage All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: IosColors.resolve(IosColors.systemIndigo, context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Empty State
          if (displayedFiles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 48,
                        color: IosColors.systemGreen.color,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _filterSegment == 1 ? 'No Staged Hunks' : 'Working Tree Clean',
                        style: IosTypography.title3.copyWith(
                          color: IosColors.resolve(IosColors.label, context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filterSegment == 1
                            ? 'Select hunks from "All Changes" to stage for an atomic commit.'
                            : 'All changes have been sliced and committed to the stack.',
                        textAlign: TextAlign.center,
                        style: IosTypography.footnote.copyWith(
                          color: IosColors.resolve(IosColors.secondaryLabel, context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Grouped File Diffs
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, fileIndex) {
                  final file = displayedFiles[fileIndex];
                  return _buildFileDiffSection(file, diffState, diffNotifier, context);
                },
                childCount: displayedFiles.length,
              ),
            ),

          // Quick Commit Strip (Bottom Inset Toolbar)
          if (stagedHunks.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildQuickCommitBar(stagedHunks, workspaceNotifier, context),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildFileDiffSection(
    FileDiff file,
    DiffViewerState diffState,
    DiffViewerNotifier diffNotifier,
    BuildContext context,
  ) {
    final fileName = file.filePath.split('/').last;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: IosColors.resolve(IosColors.secondarySystemGroupedBackground, context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: IosColors.resolve(IosColors.separator, context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 16,
                  color: IosColors.resolve(IosColors.systemIndigo, context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: IosTypography.headline.copyWith(
                      fontSize: 14,
                      color: IosColors.resolve(IosColors.label, context),
                    ),
                  ),
                ),
                Text(
                  file.filePath,
                  style: IosTypography.caption2.copyWith(
                    color: IosColors.resolve(IosColors.secondaryLabel, context),
                  ),
                ),
              ],
            ),
          ),
          const CupertinoDivider(),

          // Hunks in this file
          ...file.hunks.map((hunk) {
            final isStaged = diffState.selectedHunkIds.contains(hunk.id);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                diffNotifier.toggleHunkSelection(hunk);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isStaged
                      ? IosColors.resolve(IosColors.systemIndigo, context).withOpacity(0.06)
                      : CupertinoColors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: IosColors.resolve(IosColors.separator, context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isStaged
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 18,
                          color: isStaged
                              ? IosColors.resolve(IosColors.systemIndigo, context)
                              : IosColors.resolve(IosColors.tertiaryLabel, context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${hunk.header} (+${hunk.additionsCount} -${hunk.deletionsCount})',
                          style: IosTypography.monoCode.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: IosColors.resolve(IosColors.secondaryLabel, context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Snippet of diff lines
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: IosColors.resolve(IosColors.systemFill, context).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: hunk.lines.take(4).map((line) {
                          final isAdd = line.type == DiffLineType.addition;
                          final isDel = line.type == DiffLineType.deletion;
                          return Text(
                            line.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: IosTypography.monoCode.copyWith(
                              fontSize: 10.5,
                              color: isAdd
                                  ? IosColors.systemGreen.color
                                  : isDel
                                      ? IosColors.systemRed.color
                                      : IosColors.resolve(IosColors.secondaryLabel, context),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickCommitBar(
    List<DiffHunk> stagedHunks,
    WorkspaceNotifier workspaceNotifier,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IosColors.resolve(IosColors.secondarySystemGroupedBackground, context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: IosColors.resolve(IosColors.systemIndigo, context).withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'COMMIT ${stagedHunks.length} STAGED HUNKS',
                style: IosTypography.caption2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: IosColors.resolve(IosColors.systemIndigo, context),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // AI Generate Commit Title
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 24,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final res = await ref
                      .read(llmSelectorProvider.notifier)
                      .generateConventionalCommit(stagedHunks);
                  setState(() {
                    _selectedCommitType = res.type;
                    _summaryController.text = res.summary;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      size: 13,
                      color: IosColors.resolve(IosColors.systemIndigo, context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Synthesis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: IosColors.resolve(IosColors.systemIndigo, context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Conventional Type Segment
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: IosColors.resolve(IosColors.systemFill, context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedCommitType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: IosColors.resolve(IosColors.systemIndigo, context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  controller: _summaryController,
                  placeholder: 'Atomic commit summary...',
                  placeholderStyle: IosTypography.subheadline.copyWith(
                    color: IosColors.resolve(IosColors.tertiaryLabel, context),
                    fontSize: 13,
                  ),
                  style: IosTypography.subheadline.copyWith(
                    color: IosColors.resolve(IosColors.label, context),
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: IosColors.resolve(IosColors.systemFill, context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minSize: 34,
                borderRadius: BorderRadius.circular(8),
                onPressed: _isCommitting
                    ? null
                    : () async {
                        final summary = _summaryController.text.trim();
                        if (summary.isEmpty) return;
                        HapticFeedback.mediumImpact();
                        setState(() => _isCommitting = true);
                        try {
                          await workspaceNotifier.commitSelectedHunks(
                            summary: summary,
                            type: _selectedCommitType,
                            hunks: stagedHunks,
                          );
                          _summaryController.clear();
                          ref.read(diffViewerProvider.notifier).clearSelection();
                        } finally {
                          if (mounted) setState(() => _isCommitting = false);
                        }
                      },
                child: _isCommitting
                    ? const CupertinoActivityIndicator(radius: 6, color: CupertinoColors.white)
                    : const Text('Commit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1: STACKED PRS VIEW
// =============================================================================

class _IosStackedPrsView extends ConsumerWidget {
  const _IosStackedPrsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final commits = workspace.stackGraph.commits;

    return CupertinoPageScaffold(
      backgroundColor: IosColors.resolve(IosColors.systemGroupedBackground, context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Collapsible Large Title Navigation Bar
          IosSliverNavigationBar(
            title: 'Stacked PRs',
            branchName: workspace.currentBranch,
            isSyncing: workspace.isLoading,
            onAvatarTap: () => _openClerkProfile(context),
            onSyncTap: () async {
              HapticFeedback.mediumImpact();
              await workspaceNotifier.pushStack();
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 32,
                  onPressed: () => _openAiRefiner(context),
                  child: Icon(
                    CupertinoIcons.sparkles,
                    size: 20,
                    color: IosColors.resolve(IosColors.systemIndigo, context),
                  ),
                ),
                const SizedBox(width: 6),
                IosClerkAvatarButton(onTap: () => _openClerkProfile(context)),
              ],
            ),
          ),

          // Pull to Refresh
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await workspaceNotifier.refreshWorkspace();
            },
          ),

          // Header Summary Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.layers_alt,
                    size: 14,
                    color: IosColors.resolve(IosColors.systemIndigo, context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LINEAR ATOMIC STACK (${commits.length})',
                    style: IosTypography.caption2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: IosColors.resolve(IosColors.secondaryLabel, context),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Swipe cards for actions',
                    style: IosTypography.caption2.copyWith(
                      color: IosColors.resolve(IosColors.tertiaryLabel, context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Empty Stack State
          if (commits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.square_stack_3d_up_slash,
                        size: 48,
                        color: IosColors.resolve(IosColors.tertiaryLabel, context),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Stack Is Empty',
                        style: IosTypography.title3.copyWith(
                          color: IosColors.resolve(IosColors.label, context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stage and slice git changes in Diff Review to construct atomic PRs.',
                        textAlign: TextAlign.center,
                        style: IosTypography.footnote.copyWith(
                          color: IosColors.resolve(IosColors.secondaryLabel, context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Interactive Swipeable Commit Cards
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final commit = commits[index];
                  final isSelected = commit.id == workspace.selectedCommitId;

                  return IosSwipeableCommitCard(
                    commit: commit,
                    isSelected: isSelected,
                    onTap: () => workspaceNotifier.selectCommit(commit.id),
                    onPush: () async {
                      HapticFeedback.lightImpact();
                      await workspaceNotifier.pushStack();
                    },
                    onStage: () {
                      HapticFeedback.lightImpact();
                    },
                    onSplit: () {
                      HapticFeedback.mediumImpact();
                      _openAiRefiner(context);
                    },
                    onDiscard: () {
                      HapticFeedback.heavyImpact();
                    },
                  );
                },
                childCount: commits.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 2: REBASE PLAYGROUND VIEW
// =============================================================================

class _IosRebasePlaygroundView extends ConsumerWidget {
  const _IosRebasePlaygroundView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rebaseState = ref.watch(rebaseCanvasProvider);
    final rebaseNotifier = ref.read(rebaseCanvasProvider.notifier);
    final workspace = ref.watch(workspaceProvider);

    final commitMap = {for (final c in workspace.stackGraph.commits) c.id: c};

    return CupertinoPageScaffold(
      backgroundColor: IosColors.resolve(IosColors.systemGroupedBackground, context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Collapsible Large Title Navigation Bar
          IosSliverNavigationBar(
            title: 'Rebase Stack',
            branchName: workspace.currentBranch,
            onAvatarTap: () => _openClerkProfile(context),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rebaseState.isDirty)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 32,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      rebaseNotifier.reset();
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 14,
                        color: IosColors.resolve(IosColors.systemOrange, context),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 32,
                  onPressed: (rebaseState.isDirty && rebaseState.isValid && !rebaseState.isRebasing)
                      ? () async {
                          HapticFeedback.mediumImpact();
                          await rebaseNotifier.executeRebase();
                        }
                      : null,
                  child: rebaseState.isRebasing
                      ? const CupertinoActivityIndicator(radius: 8)
                      : Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: (rebaseState.isDirty && rebaseState.isValid)
                                ? IosColors.resolve(IosColors.systemIndigo, context)
                                : IosColors.resolve(IosColors.tertiaryLabel, context),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Pull to Refresh
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await ref.read(workspaceProvider.notifier).refreshWorkspace();
            },
          ),

          // DAG Order Warning Banner
          if (!rebaseState.isValid && rebaseState.errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IosColors.systemRed.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: IosColors.systemRed.color.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, color: IosColors.systemRed.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rebaseState.errorMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: IosColors.systemRed.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Reorder Instruction Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'DRAG COMMITS TO REORDER STACKED PR GRAPH',
                style: IosTypography.caption2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: IosColors.resolve(IosColors.secondaryLabel, context),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Reorderable Commit Items
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final commitId = rebaseState.orderedCommitIds[index];
                final commit = commitMap[commitId];
                if (commit == null) return const SizedBox.shrink();

                return Container(
                  key: ValueKey(commit.id),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: IosColors.resolve(IosColors.secondarySystemGroupedBackground, context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: IosColors.resolve(IosColors.separator, context),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Order Number Capsule
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: IosColors.resolve(IosColors.systemFill, context),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: IosTypography.monoCodeBold.copyWith(
                              fontSize: 11,
                              color: IosColors.resolve(IosColors.label, context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Commit Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              commit.conventionalTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: IosTypography.headline.copyWith(
                                fontSize: 13.5,
                                color: IosColors.resolve(IosColors.label, context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${commit.branchName} • +${commit.additions} -${commit.deletions} LOC',
                              style: IosTypography.caption2.copyWith(
                                color: IosColors.resolve(IosColors.secondaryLabel, context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // iOS Drag Handle Icon
                      Icon(
                        CupertinoIcons.bars,
                        size: 18,
                        color: IosColors.resolve(IosColors.tertiaryLabel, context),
                      ),
                    ],
                  ),
                );
              },
              childCount: rebaseState.orderedCommitIds.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 3: AI REFINER VIEW
// =============================================================================

class _IosAiRefinerView extends ConsumerWidget {
  const _IosAiRefinerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final llmState = ref.watch(llmSelectorProvider);
    final llmNotifier = ref.read(llmSelectorProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: IosColors.resolve(IosColors.systemGroupedBackground, context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Collapsible Large Title Navigation Bar
          IosSliverNavigationBar(
            title: 'AI Refiner',
            branchName: workspace.currentBranch,
            onAvatarTap: () => _openClerkProfile(context),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: () => _openAiRefiner(context),
              child: Icon(
                CupertinoIcons.wand_stars,
                size: 20,
                color: IosColors.resolve(IosColors.systemIndigo, context),
              ),
            ),
          ),

          // Active Agent Swimlanes Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'ACTIVE IDE AGENT SWIMLANES',
                style: IosTypography.caption2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: IosColors.resolve(IosColors.secondaryLabel, context),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Agents List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final agent = workspace.activeAgents[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: IosColors.resolve(IosColors.secondarySystemGroupedBackground, context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: IosColors.resolve(IosColors.separator, context),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: IosColors.resolve(IosColors.systemIndigo, context).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.sparkles,
                            size: 16,
                            color: IosColors.resolve(IosColors.systemIndigo, context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: IosTypography.headline.copyWith(
                                fontSize: 14,
                                color: IosColors.resolve(IosColors.label, context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              agent.isActive ? 'Active in workspace' : 'Standby',
                              style: IosTypography.caption2.copyWith(
                                color: agent.isActive
                                    ? IosColors.systemGreen.color
                                    : IosColors.resolve(IosColors.tertiaryLabel, context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minSize: 28,
                        borderRadius: BorderRadius.circular(8),
                        color: IosColors.resolve(IosColors.systemIndigo, context).withOpacity(0.12),
                        onPressed: () => _openAiRefiner(context),
                        child: Text(
                          'Slice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: IosColors.resolve(IosColors.systemIndigo, context),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: workspace.activeAgents.length,
            ),
          ),

          // Launch AI Sheet Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _openAiRefiner(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.sparkles, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Launch AI Stack Refiner Sheet',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// =============================================================================
// MODAL SHEET HELPERS
// =============================================================================

void _openAiRefiner(BuildContext context) {
  showIosModalSheet(
    context: context,
    builder: (_) => const IosAiRefinerSheet(),
  );
}

void _openClerkProfile(BuildContext context) {
  showIosModalSheet(
    context: context,
    builder: (_) => const IosClerkProfileSheet(),
  );
}
