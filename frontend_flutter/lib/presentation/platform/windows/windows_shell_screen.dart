import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/diff_viewer_provider.dart';
import '../../providers/hotkey_hud_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/rebase_canvas_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/agent/prompt_stream_ticker.dart';
import '../../widgets/hud/floating_hud_card.dart';
import '../../screens/clerk_sign_in_screen.dart';
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

  // Figma Windows 11 Flow States
  int _stackedPrSubView = 0; // 0 = Stacked PRs (Figma 90:633), 1 = Working changes (Figma 90:707), 2 = Sync and recovery (Figma 90:969)
  int _selectedBranchIndex = 0;
  final Set<String> _checkedFiles = <String>{};
  int _selectedWorkingCommitIndex = 0;
  String? _selectedAgentId; // null = grid (Figma 90:1036), or agent name for detail (Figma 90:1141)
  bool _showSyncBanner = false; // Figma Sync and recovery (90:969)
  String _selectedRebaseRow = 'c04d8a1'; // Figma Rebase playground active row
  final Map<String, String> _rebaseActions = {
    'a1f3c2d': 'pick',
    '7b2e9f0': 'squash',
    'c04d8a1': 'pick',
    'e5a0b77': 'reword',
    '9d2c4e8': 'drop',
  };
  bool _permReadRepos = true;
  bool _permCreateBranches = true;
  bool _permOpenPrs = false;
  bool _permRunAgentTasks = true;
  bool _agentAutoPilot = false;

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

  Future<void> _openPullRequest(Map<String, dynamic> branch) async {
    final commit = branch['commit'] as AtomicCommitUnit?;
    final prNum = commit?.prNumber;
    String url = 'https://github.com';
    if (prNum != null && prNum > 0) {
      url = 'https://github.com/pulls';
    }
    await _openExternalBrowser(url);
  }

  Future<void> _openExternalBrowser(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (_) {}
  }

  Future<void> _handleOpenRepository() async {
    final controller = TextEditingController();
    final client = ref.read(apiClientProvider);
    String currentPath = '';
    List<String> recents = [];
    try {
      final res = await client.get<Map<String, dynamic>>(ApiEndpoints.workspaceRecent);
      currentPath = res.data?['current'] as String? ?? '';
      final rawRecents = res.data?['recent'] as List<dynamic>? ?? [];
      recents = rawRecents.map((e) => e.toString()).toList();
    } catch (_) {}
    controller.text = currentPath;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Open Git Repository', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter or select a local Git repository path:',
                style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  hintText: r'C:\Users\...\my-project',
                ),
              ),
              if (recents.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Recent Repositories:', style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 11.5)),
                const SizedBox(height: 6),
                for (final r in recents.take(4))
                  InkWell(
                    onTap: () => controller.text = r,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 12, color: Color(0xFF60CDFF)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r,
                              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                Navigator.of(ctx).pop();
                try {
                  final res = await client.post<Map<String, dynamic>>(
                    ApiEndpoints.workspaceOpen,
                    data: {'path': path, 'autoInit': true},
                  );
                  final ok = res.data?['ok'] == true;
                  if (ok) {
                    await ref.read(workspaceProvider.notifier).refreshWorkspace();
                    final isNew = res.data?['isNewRepo'] == true;
                    _showFluentInfoBar(
                      message: isNew
                          ? 'Initialized new Git repository: $path'
                          : 'Opened workspace: $path',
                    );
                  } else {
                    final err = res.data?['error'] ?? 'Could not open repository';
                    _showFluentInfoBar(message: '$err', isError: true);
                  }
                } catch (e) {
                  _showFluentInfoBar(message: 'Failed to open repository: $e', isError: true);
                }
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSplitCommit(List<DiffHunk> stagedHunks) async {
    final workspaceNotifier = ref.read(workspaceProvider.notifier);

    await FluentContentDialog.show<void>(
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
        badgeCount: workspace.stackGraph.commits.isNotEmpty ? workspace.stackGraph.commits.length : null,
      ),
      FluentNavigationItem(
        label: 'Diff Viewer',
        icon: Icons.difference_outlined,
        selectedIcon: Icons.difference_rounded,
        badgeCount: workspace.uncommittedDiffs.isNotEmpty ? workspace.uncommittedDiffs.length : null,
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
        badgeCount: workspace.activeAgents.where((a) => a.isActive).isNotEmpty
            ? workspace.activeAgents.where((a) => a.isActive).length
            : null,
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
                  subtitle: 'Windows 11 Fluent Workspace • ${workspace.repositoryName.isNotEmpty ? "${workspace.repositoryName} • " : ""}${workspace.currentBranch}',
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
                          showDialog<void>(
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
                              repositoryName: workspace.repositoryName,
                              pendingCommitCount: workspace.stackGraph.commits.length,
                              isSyncing: workspace.isLoading,
                              isRefining: llmState.isRefining,
                              isAutoPilot: _isAutoPilot,
                              userSession: authState.session,
                              isGithubConnected: workspace.isGithubConnected,
                              githubUser: workspace.githubUser,
                              githubAvatarUrl: workspace.githubAvatarUrl,
                              activeModelName: llmState.selectedProvider.name,
                              availableModels: llmState.providers.map((p) => p.name).toList(),
                              onSelectModel: (name) {
                                final match = llmState.providers.where((p) => p.name == name).firstOrNull;
                                if (match != null) {
                                  ref.read(llmSelectorProvider.notifier).selectProvider(match);
                                }
                              },
                              onConnectGithub: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => const SettingsDialog(),
                                );
                              },
                              onDisconnectGithub: () async {
                                final client = ref.read(apiClientProvider);
                                try {
                                  await client.post<void>(ApiEndpoints.githubDisconnect);
                                  await ref.read(workspaceProvider.notifier).refreshWorkspace();
                                  _showFluentInfoBar(message: 'GitHub account disconnected');
                                } catch (e) {
                                  _showFluentInfoBar(message: 'Failed to disconnect: $e');
                                }
                              },
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
                              onOpenShortcuts: () =>
                                  Windows11KeyboardShortcutsDialog.show(context),
                              onOpenSettings: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => const SettingsDialog(),
                                );
                              },
                              onSignIn: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const ClerkSignInScreen()),
                                );
                              },
                              onSignOut: () =>
                                  ref.read(authStateProvider.notifier).signOut(),
                              onOpenRepository: _handleOpenRepository,
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
                                child: KeyedSubtree(
                                  key: ValueKey(_selectedTabIndex),
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

  /// Primary workspace view for Tab 0 (Figma 90:633, 90:707 & 90:969).
  Widget _buildStackedPrAndDiffView({
    required BuildContext context,
    required WorkspaceState workspace,
    required List<FileDiff> diffs,
    required List<DiffHunk> stagedHunks,
    required bool isDark,
  }) {
    final title = switch (_stackedPrSubView) {
      0 => 'Stacked PRs',
      1 => 'Atomic commits',
      2 => 'Sync',
      _ => 'Stacked PRs',
    };
    final subtitle = switch (_stackedPrSubView) {
      0 => '${workspace.currentBranch} · ${workspace.stackGraph.commits.length} branches · graph valid',
      1 => '${diffs.length} files (${stagedHunks.length} hunks) · review before committing',
      2 => 'Last attempt 2 minutes ago',
      _ => '',
    };

    return Container(
      color: const Color(0xFF202020),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional Figma Sync and Recovery Error Banner (Figma 90:969)
          if (_showSyncBanner && _stackedPrSubView != 2) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3210),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF6B5A1E)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sync failed: remote rejected push (non fast-forward)',
                      style: TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFCE100),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FluentButton(
                    onPressed: () {
                      setState(() => _stackedPrSubView = 2);
                    },
                    style: FluentButtonStyle.standard,
                    height: 32,
                    child: const Text('View log'),
                  ),
                  const SizedBox(width: 8),
                  FluentButton(
                    onPressed: () async {
                      setState(() => _showSyncBanner = false);
                      await _handleSyncNow();
                    },
                    style: FluentButtonStyle.accent,
                    height: 32,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],

          // Header with Title, Subtitle and Subview Switcher
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFB3B3B3),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Subview Switcher: Stacked PRs vs Working Changes vs Sync & recovery
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2B2B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _subViewButton(
                      label: 'Stacked PRs',
                      isSelected: _stackedPrSubView == 0,
                      onTap: () => setState(() => _stackedPrSubView = 0),
                    ),
                    _subViewButton(
                      label: 'Working changes',
                      isSelected: _stackedPrSubView == 1,
                      onTap: () => setState(() => _stackedPrSubView = 1),
                    ),
                    _subViewButton(
                      label: 'Sync & recovery',
                      isSelected: _stackedPrSubView == 2,
                      onTap: () => setState(() => _stackedPrSubView = 2),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main View Content
          Expanded(
            child: switch (_stackedPrSubView) {
              0 => _buildFigmaStackedPrView(context, workspace),
              1 => _buildFigmaWorkingChangesView(context, workspace, diffs, stagedHunks),
              2 => _buildFigmaSyncRecoveryView(context, workspace),
              _ => _buildFigmaStackedPrView(context, workspace),
            },
          ),
        ],
      ),
    );
  }

  Widget _subViewButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3A3A) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: FluentTypography.fontFamily,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFFB3B3B3),
          ),
        ),
      ),
    );
  }

  /// Helper to convert CommitStatus to label and color
  String _getCommitStatusLabel(CommitStatus status) {
    return switch (status) {
      CommitStatus.draft => 'Draft',
      CommitStatus.inReview => 'In review',
      CommitStatus.readyToPush => 'Ready',
      CommitStatus.pushed => 'Pushed',
      CommitStatus.merged => 'Merged',
      CommitStatus.conflicted => 'Conflict',
    };
  }

  Color _getCommitStatusColor(CommitStatus status) {
    return switch (status) {
      CommitStatus.draft => const Color(0xFFB3B3B3),
      CommitStatus.inReview => const Color(0xFFFCE100),
      CommitStatus.readyToPush => const Color(0xFF6CCB5F),
      CommitStatus.pushed => const Color(0xFF60CDFF),
      CommitStatus.merged => const Color(0xFFA855F7),
      CommitStatus.conflicted => const Color(0xFFFF5252),
    };
  }

  /// Exact Windows 11 Stacked PRs View (Figma 90:633).
  Widget _buildFigmaStackedPrView(BuildContext context, WorkspaceState workspace) {
    final commits = workspace.stackGraph.commits;

    if (commits.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF353538),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF4A4A4A)),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  size: 28,
                  color: Color(0xFF60CDFF),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No stacked commits yet. Changes will appear here as you work.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make code edits or let your active IDE agent generate changes. Otto will automatically slice diffs into atomic commits (≤80 LOC) and build your stack.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB3B3B3),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FluentButton(
                onPressed: () => ref.read(workspaceProvider.notifier).refreshWorkspace(),
                style: FluentButtonStyle.accent,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Check Workspace Changes'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final branches = commits.asMap().entries.map((entry) {
      final i = entry.key;
      final c = entry.value;
      final prLabel = c.prNumber != null
          ? 'PR #${c.prNumber}'
          : (c.isPushed
              ? 'PR #${c.id.length > 4 ? c.id.substring(0, 4) : c.id}'
              : 'Local #${c.id.length > 6 ? c.id.substring(0, 6) : c.id}');
      return {
        'name': c.branchName.isNotEmpty ? c.branchName : c.conventionalTitle,
        'pr': prLabel,
        'status': _getCommitStatusLabel(c.status),
        'indent': c.parentCommitId != null ? 24.0 : 0.0,
        'color': _getCommitStatusColor(c.status),
        'base': c.parentCommitId ?? 'main',
        'reviewers': c.author.isNotEmpty ? c.author : 'Self',
        'checks': c.exceedsLocThreshold ? 'Warning: >80 LOC' : 'Passing',
        'pos': '${i + 1} of ${commits.length}',
        'commit': c,
      };
    }).toList();

    final activeBranch = branches[_selectedBranchIndex.clamp(0, branches.length - 1)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        final branchListWidget = ListView.builder(
          shrinkWrap: isNarrow,
          physics: isNarrow ? const NeverScrollableScrollPhysics() : null,
          itemCount: branches.length,
          itemBuilder: (context, i) {
            final b = branches[i];
            final isSelected = _selectedBranchIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedBranchIndex = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF353538) : const Color(0xFF2F2F2F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF60CDFF) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if ((b['indent'] as double) > 0)
                      SizedBox(width: b['indent'] as double),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['name'] as String,
                            style: const TextStyle(
                              fontFamily: FluentTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b['pr']} · ${b['status']}',
                            style: const TextStyle(
                              fontFamily: FluentTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFB3B3B3),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      b['status'] as String,
                      style: TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: b['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        final prDetailsWidget = Container(
          width: isNarrow ? double.infinity : 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pull request details',
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              _buildPrDetailRow('Base', activeBranch['base'] as String),
              const SizedBox(height: 10),
              _buildPrDetailRow('Reviewers', activeBranch['reviewers'] as String),
              const SizedBox(height: 10),
              _buildPrDetailRow('Checks', activeBranch['checks'] as String),
              const SizedBox(height: 10),
              _buildPrDetailRow('Stack position', activeBranch['pos'] as String),
              const SizedBox(height: 18),
              FluentButton(
                onPressed: () => _openPullRequest(activeBranch),
                style: FluentButtonStyle.accent,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text('Open PR'),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return ListView(
            children: [
              branchListWidget,
              const SizedBox(height: 8),
              prDetailsWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: branchListWidget,
            ),
            const SizedBox(width: 16),
            prDetailsWidget,
          ],
        );
      },
    );
  }

  Widget _buildPrDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: FluentTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFFB3B3B3),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: FluentTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Exact Windows 11 Sync and Recovery View (Figma 90:969).
  Widget _buildFigmaSyncRecoveryView(BuildContext context, WorkspaceState workspace) {
    final pendingCommits = workspace.stackGraph.commits
        .where((c) => c.status != CommitStatus.merged && c.status != CommitStatus.pushed)
        .toList();

    if (pendingCommits.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF383838)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6CCB5F).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_done_outlined,
                  color: Color(0xFF6CCB5F),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Everything in sync',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'All commits in your stack are synchronized with remote origin. No sync conflicts or recovery actions needed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB3B3B3),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FluentButton(
                onPressed: () => ref.read(workspaceProvider.notifier).refreshWorkspace(),
                style: FluentButtonStyle.standard,
                height: 32,
                child: const Text('Check Remote Origin'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;

              final commitsListWidget = ListView(
                shrinkWrap: isNarrow,
                physics: isNarrow ? const NeverScrollableScrollPhysics() : null,
                children: [
                  for (final c in pendingCommits)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F2F2F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.id.length > 7 ? c.id.substring(0, 7) : c.id,
                                  style: const TextStyle(
                                    fontFamily: FluentTypography.monoFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF60CDFF),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.summary,
                                  style: const TextStyle(
                                    fontFamily: FluentTypography.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getCommitStatusLabel(c.status),
                            style: const TextStyle(
                              fontFamily: FluentTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFCE100),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );

              final syncLogWidget = Container(
                width: isNarrow ? double.infinity : 340,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2B2B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sync status',
                      style: TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Active branch: ${workspace.currentBranch}',
                      style: const TextStyle(
                        fontFamily: FluentTypography.monoFamily,
                        fontSize: 11,
                        color: Color(0xFFB3B3B3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pending commits: ${pendingCommits.length}',
                      style: const TextStyle(
                        fontFamily: FluentTypography.monoFamily,
                        fontSize: 11,
                        color: Color(0xFF60CDFF),
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return ListView(
                  children: [
                    commitsListWidget,
                    const SizedBox(height: 8),
                    syncLogWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: commitsListWidget),
                  const SizedBox(width: 12),
                  syncLogWidget,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Exact Windows 11 Working Changes View (Figma 90:707).
    Widget _buildFigmaWorkingChangesView(
    BuildContext context,
    WorkspaceState workspace,
    List<FileDiff> diffs,
    List<DiffHunk> stagedHunks,
  ) {
    if (diffs.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF383838)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF60CDFF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF60CDFF),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Working tree clean',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No uncommitted file diffs or working changes detected in this repository. Edit files in your IDE or worktree to trigger real-time AST commit slicing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB3B3B3),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FluentButton(
                onPressed: () => ref.read(workspaceProvider.notifier).refreshWorkspace(),
                style: FluentButtonStyle.standard,
                height: 32,
                child: const Text('Refresh Working Tree'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedFile = diffs[_selectedWorkingCommitIndex.clamp(0, diffs.length - 1)];
    final diffState = ref.watch(diffViewerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        final filesWidth = isNarrow ? 200.0 : 280.0;

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Changed Files List
                  Container(
                    width: filesWidth,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2B2B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Changed Files (${diffs.length})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFB3B3B3)),
                            ),
                            TextButton(
                              onPressed: () {
                                final allHunks = diffs.expand((f) => f.hunks).toList();
                                final isAllStaged = diffState.selectedHunkIds.length >= allHunks.length;
                                if (isAllStaged) {
                                  ref.read(diffViewerProvider.notifier).clearSelection();
                                } else {
                                  ref.read(diffViewerProvider.notifier).selectAllHunks(allHunks);
                                }
                              },
                              child: Text(
                                diffState.selectedHunkIds.isNotEmpty ? 'Unstage All' : 'Stage All',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF60CDFF)),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF3A3A3A), height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: diffs.length,
                            itemBuilder: (context, idx) {
                              final fd = diffs[idx];
                              final isFileStaged = fd.hunks.isNotEmpty && fd.hunks.every((h) => diffState.selectedHunkIds.contains(h.id));
                              return _buildWorkingFileItem(
                                fd.filePath,
                                '${fd.hunks.length} hunks · +${fd.additions} -${fd.deletions}',
                                isChecked: isFileStaged,
                                isSelected: _selectedWorkingCommitIndex == idx,
                                onSelect: () => setState(() => _selectedWorkingCommitIndex = idx),
                                onToggle: () {
                                  if (isFileStaged) {
                                    for (final h in fd.hunks) {
                                      if (diffState.selectedHunkIds.contains(h.id)) {
                                        ref.read(diffViewerProvider.notifier).toggleHunkSelection(h);
                                      }
                                    }
                                  } else {
                                    for (final h in fd.hunks) {
                                      if (!diffState.selectedHunkIds.contains(h.id)) {
                                        ref.read(diffViewerProvider.notifier).toggleHunkSelection(h);
                                      }
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Diff Hunks Inspector
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2B2B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  selectedFile.filePath,
                                  style: const TextStyle(
                                    fontFamily: FluentTypography.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${selectedFile.hunks.where((h) => diffState.selectedHunkIds.contains(h.id)).length} of ${selectedFile.hunks.length} hunks staged',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF60CDFF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: selectedFile.hunks.length,
                              itemBuilder: (context, hIdx) {
                                final h = selectedFile.hunks[hIdx];
                                final isHunkStaged = diffState.selectedHunkIds.contains(h.id);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF242424),
                                    borderRadius: BorderRadius.circular(6),
                                    border: isHunkStaged ? Border.all(color: const Color(0xFF60CDFF).withOpacity(0.5)) : null,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: isHunkStaged,
                                            activeColor: const Color(0xFF60CDFF),
                                            onChanged: (_) => ref.read(diffViewerProvider.notifier).toggleHunkSelection(h),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '@@ Hunk #${hIdx + 1} (${h.header.isNotEmpty ? h.header : h.filePath})',
                                              style: const TextStyle(
                                                fontFamily: FluentTypography.monoFamily,
                                                fontSize: 11,
                                                color: Color(0xFF60CDFF),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => ref.read(diffViewerProvider.notifier).toggleHunkSelection(h),
                                            child: Text(
                                              isHunkStaged ? 'Unstage' : 'Stage Hunk',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isHunkStaged ? const Color(0xFF6CCB5F) : const Color(0xFF60CDFF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      for (final line in h.lines)
                                        _buildDiffLineText(
                                          line.content,
                                          isAddition: line.type == DiffLineType.addition,
                                          isDeletion: line.type == DiffLineType.deletion,
                                          isNormal: line.type == DiffLineType.context,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildFluentQuickCommitStrip(stagedHunks: stagedHunks, isDark: isDark),
          ],
        );
      },
    );
  }

  Widget _buildWorkingFileItem(
    String filename,
    String hunks, {
    required bool isChecked,
    bool isSelected = false,
    VoidCallback? onSelect,
    VoidCallback? onToggle,
  }) {
    return Container(
      color: isSelected ? const Color(0xFF383838) : Colors.transparent,
      child: InkWell(
        onTap: onSelect ?? onToggle,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFF60CDFF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isChecked ? const Color(0xFF60CDFF) : const Color(0xFF9A9A9A),
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, size: 12, color: Colors.black)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      hunks,
                      style: const TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFB3B3B3),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiffLineText(
    String text, {
    bool isAddition = false,
    bool isDeletion = false,
    bool isNormal = false,
  }) {
    Color bg = Colors.transparent;
    if (isAddition) bg = const Color(0xFF1E3A29);
    if (isDeletion) bg = const Color(0xFF3D2226);

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: FluentTypography.monoFamily,
          fontSize: 11.5,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Exact Windows 11 Diff Viewer View (Figma 90:896).
    Widget _buildDiffViewerOnlyView({
    required BuildContext context,
    required List<FileDiff> diffs,
    required List<DiffHunk> stagedHunks,
    required bool isDark,
  }) {
    if (diffs.isEmpty) {
      return Container(
        color: const Color(0xFF202020),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF383838)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF60CDFF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.difference_outlined,
                    color: Color(0xFF60CDFF),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No file diffs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No uncommitted changes available to display. Edit files in your active workspace to inspect side-by-side AST hunks here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB3B3B3),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FluentButton(
                      onPressed: () => ref.read(workspaceProvider.notifier).refreshWorkspace(),
                      style: FluentButtonStyle.standard,
                      height: 32,
                      child: const Text('Check for Changes'),
                    ),
                    FluentButton(
                      onPressed: _handleOpenRepository,
                      style: FluentButtonStyle.accent,
                      height: 32,
                      child: const Text('Open Project Folder...'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeFile = diffs[_selectedWorkingCommitIndex.clamp(0, diffs.length - 1)];
    final diffState = ref.watch(diffViewerProvider);

    return Container(
      color: const Color(0xFF202020),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diff Viewer',
                    style: TextStyle(
                      fontFamily: FluentTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activeFile.filePath} · +${activeFile.additions} -${activeFile.deletions} (${diffs.length} changed files)',
                    style: const TextStyle(
                      fontFamily: FluentTypography.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB3B3B3),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final allHunks = diffs.expand((f) => f.hunks).toList();
                      final isAllStaged = diffState.selectedHunkIds.length >= allHunks.length;
                      if (isAllStaged) {
                        ref.read(diffViewerProvider.notifier).clearSelection();
                      } else {
                        ref.read(diffViewerProvider.notifier).selectAllHunks(allHunks);
                      }
                    },
                    icon: Icon(
                      diffState.selectedHunkIds.isNotEmpty ? Icons.clear_all_rounded : Icons.select_all_rounded,
                      size: 14,
                      color: const Color(0xFF60CDFF),
                    ),
                    label: Text(
                      diffState.selectedHunkIds.isNotEmpty ? 'Unstage All' : 'Stage All Hunks',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF60CDFF)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // File Selector Tabs
          if (diffs.length > 1) ...[
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: diffs.length,
                itemBuilder: (context, fIdx) {
                  final isSelected = _selectedWorkingCommitIndex == fIdx;
                  final f = diffs[fIdx];
                  final parts = f.filePath.replaceAll(r'\', '/').split('/');
                  final shortName = parts.isNotEmpty ? parts.last : f.filePath;
                  final stagedCount = f.hunks.where((h) => diffState.selectedHunkIds.contains(h.id)).length;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWorkingCommitIndex = fIdx),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF383838) : const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF60CDFF) : const Color(0xFF3A3A3A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shortName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                          if (stagedCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF60CDFF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$stagedCount',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF60CDFF)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: ListView.builder(
                itemCount: activeFile.hunks.length,
                itemBuilder: (context, hIdx) {
                  final hunk = activeFile.hunks[hIdx];
                  final isHunkStaged = diffState.selectedHunkIds.contains(hunk.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(6),
                      border: isHunkStaged ? Border.all(color: const Color(0xFF60CDFF).withOpacity(0.5)) : null,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isHunkStaged,
                              activeColor: const Color(0xFF60CDFF),
                              onChanged: (_) => ref.read(diffViewerProvider.notifier).toggleHunkSelection(hunk),
                            ),
                            Expanded(
                              child: Text(
                                '@@ Hunk #${hIdx + 1} (${hunk.header.isNotEmpty ? hunk.header : hunk.filePath})',
                                style: const TextStyle(
                                  fontFamily: FluentTypography.monoFamily,
                                  fontSize: 11,
                                  color: Color(0xFF60CDFF),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref.read(diffViewerProvider.notifier).toggleHunkSelection(hunk),
                              child: Text(
                                isHunkStaged ? 'Unstage' : 'Stage Hunk',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isHunkStaged ? const Color(0xFF6CCB5F) : const Color(0xFF60CDFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        for (final line in hunk.lines)
                          _buildDiffLineText(
                            line.content,
                            isAddition: line.type == DiffLineType.addition,
                            isDeletion: line.type == DiffLineType.deletion,
                            isNormal: line.type == DiffLineType.context,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),
          _buildFluentQuickCommitStrip(stagedHunks: stagedHunks, isDark: isDark),
        ],
      ),
    );
  }

  /// Exact Windows 11 Rebase Playground View (Figma 90:799).
    Widget _buildRebasePlaygroundView({
    required BuildContext context,
    required WorkspaceState workspace,
    required RebaseCanvasState rebaseState,
    required bool isDark,
  }) {
    final commits = workspace.stackGraph.commits;

    if (commits.isEmpty) {
      return Container(
        color: const Color(0xFF202020),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF383838)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF60CDFF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Color(0xFF60CDFF),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No commits in stack',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Stage and commit changes to reorder, squash, or linearize your stacked Pull Requests on this canvas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB3B3B3),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF202020),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rebase canvas',
            style: TextStyle(
              fontFamily: FluentTypography.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${commits.length} commits in stack · Drag to reorder · choose an action per commit',
            style: const TextStyle(
              fontFamily: FluentTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFFB3B3B3),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: ListView(
                children: [
                  for (final c in commits) ...[
                    _buildRebaseRow(
                      sha: c.id.length > 7 ? c.id.substring(0, 7) : c.id,
                      title: c.summary,
                      dep: c.branchName.isNotEmpty ? 'Branch: ${c.branchName}' : null,
                      isSelected: _selectedRebaseRow == c.id,
                      onTap: () => setState(() => _selectedRebaseRow = c.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FluentButton(
                onPressed: () async {
                  final ok = await ref.read(rebaseCanvasProvider.notifier).executeRebase();
                  if (ok) {
                    await ref.read(workspaceProvider.notifier).refreshWorkspace();
                    _showFluentInfoBar(message: 'Stack rebase validated and executed successfully.');
                  } else {
                    final err = ref.read(rebaseCanvasProvider).errorMessage ?? 'Rebase failed';
                    _showFluentInfoBar(message: 'Rebase error: $err');
                  }
                },
                style: FluentButtonStyle.accent,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text('Apply rebase'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRebaseRow({
    required String sha,
    required String title,
    String? dep,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final action = _rebaseActions[sha] ?? 'pick';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2A2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF60CDFF) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Custom Grip Handle (Figma 90:835)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 4; i++) ...[
                  Container(
                    width: 3,
                    height: 2,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    color: const Color(0xFF8A8A8A),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 12),

            // Commit SHA & Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sha  $title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: FluentTypography.monoFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (dep != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      dep,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: FluentTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFCE100),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ComboBox action
            Container(
              height: 32,
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF484848)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: action,
                  dropdownColor: const Color(0xFF2B2B2B),
                  style: const TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  items: ['pick', 'squash', 'reword', 'drop']
                      .map((act) => DropdownMenuItem(value: act, child: Text(act)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _rebaseActions[sha] = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exact Windows 11 AI Agents View (Figma 90:1036 and 90:1141).
  Widget _buildAgentSwimlanesView({
    required BuildContext context,
    required WorkspaceState workspace,
    required bool isDark,
  }) {
    return Container(
      color: const Color(0xFF202020),
      padding: const EdgeInsets.all(24),
      child: _selectedAgentId == null
          ? _buildFigmaAgentPicker(context, workspace)
          : _buildFigmaConnectedAgentDetail(context, _selectedAgentId!),
    );
  }

  /// Figma AI Agent Picker (90:1036).
  Widget _buildFigmaAgentPicker(BuildContext context, WorkspaceState workspace) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Agents',
          style: TextStyle(
            fontFamily: FluentTypography.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Connect your AI agents to Otto',
          style: TextStyle(
            fontFamily: FluentTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFFB3B3B3),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 650
                  ? 1
                  : (constraints.maxWidth < 950 ? 2 : (constraints.maxWidth < 1250 ? 3 : 4));
              final aspectRatio = constraints.maxWidth < 650 ? 2.5 : 1.45;

              final catalog = [
                (id: 'antigravity', name: 'Google Antigravity', desc: 'Agent-first IDE & autonomous commit daemon', letter: 'A', logoBg: const Color(0xFF4285F4)),
                (id: 'claude-code', name: 'Claude Code', desc: 'Terminal coding agent', letter: 'C', logoBg: const Color(0xFFD97757)),
                (id: 'cursor', name: 'Cursor', desc: 'AI code editor', letter: 'C', logoBg: const Color(0xFF5C5C66)),
                (id: 'codex', name: 'Codex', desc: 'Cloud and CLI coding agent', letter: 'C', logoBg: const Color(0xFF10A37F)),
                (id: 'devin', name: 'Devin', desc: 'Autonomous software engineer', letter: 'D', logoBg: const Color(0xFF2F9E8F)),
                (id: 'kiro', name: 'Kiro', desc: 'Spec-driven IDE', letter: 'K', logoBg: const Color(0xFFFF9900)),
                (id: 'copilot', name: 'GitHub Copilot', desc: 'Coding assistant in your IDE', letter: 'G', logoBg: const Color(0xFF8E8E93)),
                (id: 'custom', name: 'Other agent', desc: 'Connect any agent with an API key', letter: 'O', logoBg: const Color(0xFF2E2E36)),
              ];

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio,
                children: [
                  for (final item in catalog) ...[
                    Builder(
                      builder: (context) {
                        final matchedAgent = workspace.activeAgents.where((a) => a.id == item.id || a.name.toLowerCase() == item.name.toLowerCase()).firstOrNull;
                        final isConnected = matchedAgent != null && matchedAgent.isActive;
                        return _buildAgentCard(
                          name: item.name,
                          desc: item.desc,
                          badgeText: isConnected ? 'Connected & Active' : 'Not connected',
                          badgeColor: isConnected ? const Color(0xFF6CCB5F) : const Color(0xFF8A8A8A),
                          letter: item.letter,
                          logoBg: item.logoBg,
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard({
    required String name,
    required String desc,
    required String badgeText,
    required Color badgeColor,
    required String letter,
    required Color logoBg,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAgentId = name);
        showDialog<void>(
          context: context,
          builder: (_) => const SettingsDialog(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: logoBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB3B3B3),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Figma Connected Agent Detail View (90:1141).
  Widget _buildFigmaConnectedAgentDetail(BuildContext context, String agentName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;

        final accountCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account',
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
                            _buildDetailRow('Account', ref.watch(authStateProvider).session?.email ?? 'Local Workspace'),
              const SizedBox(height: 8),
              _buildDetailRow('Plan', ref.watch(authStateProvider).session != null ? 'Pro' : 'Community'),
              const SizedBox(height: 8),
              _buildDetailRow('Last synced', 'Just now'),
              const SizedBox(height: 8),
              _buildDetailRow('Credentials', ref.watch(authStateProvider).session != null ? 'Authenticated (Google)' : 'Disconnected'),
            ],
          ),
        );

        final permissionsCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Permissions',
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _buildPermissionSwitchRow('Read repositories', _permReadRepos, (val) => setState(() => _permReadRepos = val)),
              _buildPermissionSwitchRow('Create branches', _permCreateBranches, (val) => setState(() => _permCreateBranches = val)),
              _buildPermissionSwitchRow('Open pull requests', _permOpenPrs, (val) => setState(() => _permOpenPrs = val)),
              _buildPermissionSwitchRow('Run agent tasks', _permRunAgentTasks, (val) => setState(() => _permRunAgentTasks = val)),
            ],
          ),
        );

        final autopilotCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Auto-Pilot',
                    style: TextStyle(
                      fontFamily: FluentTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  FluentToggleSwitch(
                    value: _agentAutoPilot,
                    onChanged: (val) => setState(() => _agentAutoPilot = val),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Let Otto run $agentName tasks without asking each time.',
                style: const TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB3B3B3),
                ),
              ),
            ],
          ),
        );

        final dangerCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF5A2A2E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disconnect $agentName',
                style: const TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF8A80),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Removes Otto's access and deletes stored credentials.",
                style: TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB3B3B3),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FluentButton(
                  onPressed: () {
                    setState(() => _selectedAgentId = null);
                    _showFluentInfoBar(message: '$agentName disconnected.');
                  },
                  style: FluentButtonStyle.standard,
                  child: const Text('Disconnect'),
                ),
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agentName,
                        style: const TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connected · Detected on this computer',
                        style: TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFB3B3B3),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FluentButton(
                      onPressed: () => setState(() => _selectedAgentId = null),
                      style: FluentButtonStyle.subtle,
                      child: const Text('Back to Agents'),
                    ),
                    const SizedBox(width: 8),
                    FluentButton(
                      onPressed: () {
                        _showFluentInfoBar(message: 'Reauthorization initiated for $agentName');
                      },
                      style: FluentButtonStyle.standard,
                      child: const Text('Reauthorize'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: isCompact
                    ? [
                        accountCard,
                        const SizedBox(height: 12),
                        permissionsCard,
                        const SizedBox(height: 12),
                        autopilotCard,
                        const SizedBox(height: 12),
                        dangerCard,
                      ]
                    : [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: accountCard),
                            const SizedBox(width: 12),
                            Expanded(child: permissionsCard),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: autopilotCard),
                            const SizedBox(width: 12),
                            Expanded(child: dangerCard),
                          ],
                        ),
                      ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: FluentTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFFB3B3B3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FluentTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: FluentTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          FluentToggleSwitch(
            value: value,
            onChanged: onChanged,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;

          return Row(
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
                      isNarrow ? '${stagedHunks.length}' : '${stagedHunks.length} hunks staged',
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

              if (!isNarrow) ...[
                // Scope Input
                Container(
                  width: 90,
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
              ],

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
                      hintText: isNarrow ? 'Summary...' : 'Commit summary (Ctrl+Enter to commit)',
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

              if (!isNarrow) ...[
                // Split Commit Dialog Launcher
                FluentButton(
                  onPressed: hasStaged ? () => _handleSplitCommit(stagedHunks) : null,
                  style: FluentButtonStyle.standard,
                  tooltip: 'Slice staged diffs into dedicated atomic PR commit',
                  child: const Text('Split Commit...'),
                ),
                const SizedBox(width: 6),
              ],

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
                    Text(isNarrow ? 'Commit' : 'Commit Staged'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
