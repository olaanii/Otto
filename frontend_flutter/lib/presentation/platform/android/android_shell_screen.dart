import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/clerk_user_session.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../screens/rebase_playground_screen.dart';
import '../../widgets/agent/agent_swimlane_card.dart';
import '../../widgets/diff/virtual_diff_viewer.dart';
import '../../widgets/hud/quick_commit_strip.dart';
import 'android_material3_theme.dart';
import 'm3_commit_card.dart';
import 'm3_navigation_bar.dart';
import 'm3_top_app_bar.dart';

/// Complete Android Material Design 3 Mobile & Tablet Companion Workspace.
///
/// Implements official Material You guidelines:
/// - Dynamic M3 tonal elevations and color schemes
/// - Medium collapsible TopAppBar with search, GitHub sync pill, and Clerk profile menu
/// - M3 NavigationBar with stadium pill indicators (phone) & NavigationRail (foldables/tablets)
/// - M3 Commit Cards with 16px corner radii, LOC badges, and compliance score bars
/// - Extended FloatingActionButton for instant "Stage & Push Stack" action
/// - M3 ModalBottomSheet for Quick Diff Inspector and Clerk Authentication
class AndroidShellScreen extends ConsumerStatefulWidget {
  const AndroidShellScreen({super.key});

  @override
  ConsumerState<AndroidShellScreen> createState() => _AndroidShellScreenState();
}

class _AndroidShellScreenState extends ConsumerState<AndroidShellScreen> {
  int _currentTab = 0;
  String _searchFilter = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeData = isDark
        ? AndroidMaterial3Theme.dark()
        : AndroidMaterial3Theme.light();

    return Theme(
      data: themeData,
      child: Builder(
        builder: (themedContext) => _buildScaffold(themedContext),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final authState = ref.watch(authStateProvider);
    final diffState = ref.watch(diffViewerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final stagedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    final uncommittedCount = workspace.uncommittedDiffs.length;
    final activeAgentsCount = workspace.activeAgents.where((a) => a.isActive).length;

    // Navigation items with badges
    final navItems = [
      M3NavigationItem(
        icon: Icons.layers_outlined,
        selectedIcon: Icons.layers_rounded,
        label: 'Stack',
        badgeCount: workspace.stackGraph.commits.isNotEmpty
            ? workspace.stackGraph.commits.length
            : null,
      ),
      M3NavigationItem(
        icon: Icons.difference_outlined,
        selectedIcon: Icons.difference_rounded,
        label: 'Diffs',
        badgeCount: uncommittedCount > 0 ? uncommittedCount : null,
      ),
      M3NavigationItem(
        icon: Icons.smart_toy_outlined,
        selectedIcon: Icons.smart_toy_rounded,
        label: 'Agents',
        showBadgeDot: activeAgentsCount > 0,
      ),
      const M3NavigationItem(
        icon: Icons.verified_outlined,
        selectedIcon: Icons.verified_rounded,
        label: 'Guardrails',
      ),
    ];

    // Determine GitHub sync status
    final GithubSyncStatus syncStatus = workspace.isLoading
        ? GithubSyncStatus.syncing
        : (workspace.stackGraph.commits.any((c) => !c.isPushed)
            ? GithubSyncStatus.pendingPush
            : GithubSyncStatus.synced);

    return LayoutBuilder(
      builder: (context, constraints) {
        return M3AdaptiveNavigationScaffold(
          selectedIndex: _currentTab,
          onDestinationSelected: (index) => setState(() => _currentTab = index),
          items: navItems,
          floatingActionButton: _buildExtendedFab(
            context,
            workspace,
            workspaceNotifier,
            stagedHunks,
          ),
          railLeading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'O',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
          railTrailing: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Rebase Playground',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RebasePlaygroundScreen()),
                );
              },
            ),
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              M3SliverMediumTopAppBar(
                title: 'Otto Stacking',
                currentBranch: workspace.currentBranch,
                syncStatus: syncStatus,
                clerkSession: authState.session,
                onSyncTap: () => workspaceNotifier.pushStack(),
                onBranchTap: () => _showBranchSelector(context, workspace),
                onClerkProfileTap: () => _showClerkAuthSheet(context),
                onSearchChanged: (query) => setState(() => _searchFilter = query),
                onSearchClosed: () => setState(() => _searchFilter = ''),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () => workspaceNotifier.refreshWorkspace(),
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHigh,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  // Tab 0: Stacked PRs Chain
                  _buildStackTab(context, workspace, workspaceNotifier),

                  // Tab 1: Virtual Diffs & Hunk Staging
                  _buildDiffsTab(context, workspace, stagedHunks, workspaceNotifier),

                  // Tab 2: AI Agents Swimlanes
                  _buildAgentsTab(context, workspace),

                  // Tab 3: Guardrail Policy & Compliance
                  _buildGuardrailsTab(context, workspace),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Extended FloatingActionButton for instant atomic actions.
  Widget _buildExtendedFab(
    BuildContext context,
    WorkspaceState workspace,
    WorkspaceNotifier workspaceNotifier,
    List<DiffHunk> stagedHunks,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_currentTab == 0) {
      // Stack Tab: "Stage & Push Stack"
      final unpushedCount = workspace.stackGraph.commits.where((c) => !c.isPushed).length;
      final label = workspace.isLoading
          ? 'Pushing Stack...'
          : (unpushedCount > 0 ? 'Push Stack ($unpushedCount)' : 'Stage & Push Stack');

      return FloatingActionButton.extended(
        onPressed: workspace.isLoading
            ? null
            : () async {
                final success = await workspaceNotifier.pushStack();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Stacked PRs successfully pushed to GitHub!'
                            : (workspace.errorMessage ?? 'Push failed'),
                      ),
                      backgroundColor: success
                          ? const Color(0xFF137333)
                          : colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
        icon: workspace.isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : const Icon(Icons.cloud_upload_rounded),
        label: Text(label),
      );
    } else if (_currentTab == 1) {
      // Diffs Tab: "Commit Staged"
      return FloatingActionButton.extended(
        onPressed: stagedHunks.isNotEmpty
            ? () => _showQuickCommitSheet(context, stagedHunks)
            : null,
        icon: const Icon(Icons.commit_rounded),
        label: Text(
          stagedHunks.isNotEmpty
              ? 'Commit Staged (${stagedHunks.length})'
              : 'Stage Changes to Commit',
        ),
      );
    } else if (_currentTab == 2) {
      // Agents Tab
      return FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All IDE agents active and listening to workspace events.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text('Agent Actions'),
      );
    }

    return const SizedBox.shrink();
  }

  /// Tab 0: Stacked PRs Tree View with M3 Commit Cards.
  Widget _buildStackTab(
    BuildContext context,
    WorkspaceState workspace,
    WorkspaceNotifier workspaceNotifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commits = workspace.stackGraph.commits.where((c) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return c.summary.toLowerCase().contains(q) ||
          c.branchName.toLowerCase().contains(q) ||
          (c.scope != null && c.scope!.toLowerCase().contains(q)) ||
          c.author.toLowerCase().contains(q);
    }).toList();

    if (commits.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.layers_clear_outlined,
                  size: 36,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _searchFilter.isNotEmpty
                    ? 'No matching commits found'
                    : 'Stacked PR Chain is Empty',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchFilter.isNotEmpty
                    ? 'Try searching with a different term or clear the filter.'
                    : 'Stage diff hunks in the Diffs tab and commit to create your first atomic PR in the stack.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (_searchFilter.isEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _currentTab = 1),
                  icon: const Icon(Icons.difference_outlined),
                  label: const Text('Go to Diffs & Stage'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: commits.length,
      itemBuilder: (context, index) {
        final commit = commits[index];
        final isSelected = commit.id == workspace.selectedCommitId;
        final isTop = index == 0;
        final isBottom = index == commits.length - 1;

        return Stack(
          children: [
            // Connecting vertical tree line
            Positioned(
              left: 28,
              top: isTop ? 32 : 0,
              bottom: isBottom ? 32 : 0,
              child: Container(
                width: 2.5,
                color: colorScheme.outlineVariant.withOpacity(0.6),
              ),
            ),

            // Node Circle Marker with M3 tonal color
            Positioned(
              left: 23,
              top: 32,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                    width: 2,
                  ),
                ),
              ),
            ),

            // M3 Commit Card
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: M3CommitCard(
                commit: commit,
                isSelected: isSelected,
                guardrailPolicy: workspace.guardrailPolicy,
                variant: isSelected
                    ? M3CommitCardVariant.filledTonal
                    : M3CommitCardVariant.elevated,
                onTap: () {
                  workspaceNotifier.selectCommit(commit.id);
                  _showDiffInspectorSheet(context, commit);
                },
                onInspectDiff: () => _showDiffInspectorSheet(context, commit),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tab 1: Virtual Diffs & Uncommitted hunks viewer.
  Widget _buildDiffsTab(
    BuildContext context,
    WorkspaceState workspace,
    List<DiffHunk> stagedHunks,
    WorkspaceNotifier workspaceNotifier,
  ) {
    return Column(
      children: [
        Expanded(
          child: VirtualDiffViewer(fileDiffs: workspace.uncommittedDiffs),
        ),
        if (stagedHunks.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
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
      ],
    );
  }

  /// Tab 2: AI Agents Swimlanes.
  Widget _buildAgentsTab(BuildContext context, WorkspaceState workspace) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: workspace.activeAgents.map((agent) {
        return AgentSwimlaneCard(
          agent: agent,
          onSliceAgentChanges: () {
            setState(() => _currentTab = 1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Changes staged for ${agent.name}. Ready to commit!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      }).toList(),
    );
  }

  /// Tab 3: Repository Guardrails and Atomic PR policy overview.
  Widget _buildGuardrailsTab(BuildContext context, WorkspaceState workspace) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final policy = workspace.guardrailPolicy;
    final totalCommits = workspace.stackGraph.commits.length;
    final compliantCommits = workspace.stackGraph.commits
        .where((c) => !c.exceedsLocThreshold && !c.exceedsFileThreshold)
        .length;
    final complianceRate = totalCommits > 0
        ? ((compliantCommits / totalCommits) * 100).toInt()
        : 100;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compliance Overview Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Atomic PR Health Score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$complianceRate% Compliant',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: complianceRate >= 80
                            ? const Color(0xFF137333)
                            : colorScheme.error,
                      ),
                    ),
                    Text(
                      '$compliantCommits of $totalCommits Commits',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: complianceRate / 100.0,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      complianceRate >= 80
                          ? const Color(0xFF137333)
                          : colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Active Policies List
        Text(
          'Active Repository Guardrails',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        _buildPolicyTile(
          icon: Icons.format_size_rounded,
          title: 'Max Lines of Code (LOC)',
          subtitle: 'Maximum of ${policy.maxLocPerCommit} LOC per atomic commit unit.',
          context: context,
        ),
        _buildPolicyTile(
          icon: Icons.insert_drive_file_outlined,
          title: 'Max Files Changed',
          subtitle: 'Maximum of ${policy.maxFilesPerCommit} files per commit to enforce single responsibility.',
          context: context,
        ),
        _buildPolicyTile(
          icon: Icons.spellcheck_rounded,
          title: 'Conventional Commits',
          subtitle: 'Enforces type(scope): summary format. Types: ${policy.allowedCommitTypes.join(", ")}.',
          context: context,
        ),
      ],
    );
  }

  Widget _buildPolicyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      ),
    );
  }

  /// Material 3 ModalBottomSheet: Quick Diff Inspector.
  void _showDiffInspectorSheet(BuildContext context, AtomicCommitUnit commit) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Commit Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          commit.type.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          commit.summary,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (commit.description != null && commit.description!.isNotEmpty) ...[
                    Text(
                      commit.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Branch & Author Meta
                  Row(
                    children: [
                      Icon(Icons.fork_right_rounded, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        commit.branchName,
                        style: AndroidMaterial3Theme.monoStyle(
                          fontSize: 11.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'By ${commit.author}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // LOC & Guardrail Metrics
                  Text(
                    'Guardrail Metrics',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetricChip(
                        label: '+${commit.additions} LOC',
                        color: const Color(0xFF137333),
                        bgColor: const Color(0xFFC4EED0),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricChip(
                        label: '-${commit.deletions} LOC',
                        color: const Color(0xFFC5221F),
                        bgColor: const Color(0xFFF9DEDC),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricChip(
                        label: '${commit.changedFiles.length} files',
                        color: colorScheme.onSurfaceVariant,
                        bgColor: colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Changed Files List
                  Text(
                    'Changed Files (${commit.changedFiles.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...commit.changedFiles.map((file) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file_outlined, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file,
                              style: AndroidMaterial3Theme.monoStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Dismiss Inspector'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricChip({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Material 3 ModalBottomSheet: Clerk User Account & Profile.
  void _showClerkAuthSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.read(authStateProvider);
    final session = authState.session;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      session?.fullName.isNotEmpty == true
                          ? session!.fullName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                session?.fullName ?? 'Developer Account',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                session?.email ?? 'Otto Git Client Session',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // GitHub Linkage Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connected GitHub',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            session?.githubUsername != null
                                ? '@${session!.githubUsername}'
                                : 'Authenticated via Clerk OAuth',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF137333), size: 18),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sign Out Button
              FilledButton.tonalIcon(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (bottomSheetContext.mounted) {
                    Navigator.of(bottomSheetContext).pop();
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out of Clerk'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Material 3 ModalBottomSheet: Quick Commit Staged Hunks.
  void _showQuickCommitSheet(BuildContext context, List<DiffHunk> stagedHunks) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summaryController = TextEditingController();
    String selectedType = 'feat';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Atomic Commit (${stagedHunks.length} Hunks)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Conventional Type Segmented chips
                  Wrap(
                    spacing: 8,
                    children: ['feat', 'fix', 'refactor', 'perf', 'chore'].map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Commit summary adhering to guardrails',
                      hintText: 'e.g. implement android material 3 shell',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        tooltip: 'Synthesize with AI',
                        onPressed: () async {
                          final ai = await ref
                              .read(llmSelectorProvider.notifier)
                              .generateConventionalCommit(stagedHunks);
                          setSheetState(() {
                            selectedType = ai.type;
                            summaryController.text = ai.summary;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final summary = summaryController.text.trim();
                      if (summary.isEmpty) return;
                      await ref.read(workspaceProvider.notifier).commitSelectedHunks(
                        summary: summary,
                        type: selectedType,
                        hunks: stagedHunks,
                      );
                      if (bottomSheetContext.mounted) {
                        Navigator.of(bottomSheetContext).pop();
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Create Atomic Commit'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBranchSelector(BuildContext context, WorkspaceState workspace) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Branches in Stack',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.fork_right_rounded, color: colorScheme.primary),
              title: Text(workspace.currentBranch),
              trailing: const Icon(Icons.check_rounded, color: Color(0xFF137333)),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
