import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Theme, Brightness, MaterialPageRoute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/typography.dart';
import '../providers/diff_viewer_provider.dart';
import '../providers/llm_selector_provider.dart';
import '../providers/workspace_provider.dart';
import '../screens/rebase_playground_screen.dart';
import '../screens/settings_dialog.dart';
import '../widgets/agent/agent_swimlane_card.dart';
import '../widgets/agent/prompt_stream_ticker.dart';
import '../widgets/diff/virtual_diff_viewer.dart';
import '../widgets/hud/quick_commit_strip.dart';
import '../widgets/stack/stacked_pr_tree_view.dart';

/// iOS 17/18 Human Interface Guidelines (HIG) Cupertino Native Shell.
/// Incorporates CupertinoNavigationBar with Large Title styling, CupertinoTabBar,
/// inset grouped sections, and Apple bouncing scroll physics.
class IosShellScreen extends ConsumerStatefulWidget {
  const IosShellScreen({super.key});

  @override
  ConsumerState<IosShellScreen> createState() => _IosShellScreenState();
}

class _IosShellScreenState extends ConsumerState<IosShellScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final llmState = ref.watch(llmSelectorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stagedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    final bgColor = isDark ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemGroupedBackground;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Otto: ${workspace.currentBranch}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_2_squarepath, size: 20),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RebasePlaygroundScreen()),
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: workspace.isLoading ? null : () => workspaceNotifier.pushStack(),
              child: workspace.isLoading
                  ? const CupertinoActivityIndicator(radius: 8)
                  : const Icon(CupertinoIcons.arrow_up_circle_fill, size: 24),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.gear_alt, size: 22),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => const SettingsDialog(),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Live AI Prompt Ticker if active
            if (llmState.activeStreamingText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: PromptStreamTicker(
                  text: llmState.activeStreamingText!,
                  isStreaming: llmState.isRefining,
                ),
              ),

            // Tab Content Body
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  // Tab 0: Stacked PR Graph
                  StackedPrTreeView(
                    commits: workspace.stackGraph.commits,
                    selectedCommitId: workspace.selectedCommitId,
                    onCommitSelected: (c) => workspaceNotifier.selectCommit(c.id),
                    onOpenRebaseCanvas: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RebasePlaygroundScreen()),
                      );
                    },
                  ),

                  // Tab 1: Virtual Diff Viewer & Quick Commit
                  Column(
                    children: [
                      Expanded(
                        child: VirtualDiffViewer(fileDiffs: workspace.uncommittedDiffs),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                          border: Border(
                            top: BorderSide(
                              color: isDark ? const Color(0xFF38383A) : CupertinoColors.systemGrey4,
                              width: 0.5,
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
                  ),

                  // Tab 2: AI Agents
                  ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'IDE AI AGENTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...workspace.activeAgents.map(
                        (agent) => AgentSwimlaneCard(
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
                ],
              ),
            ),

            // Cupertino Bottom Tab Bar
            CupertinoTabBar(
              currentIndex: _currentTab,
              onTap: (idx) => setState(() => _currentTab = idx),
              activeColor: CupertinoColors.activeBlue,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.layers),
                  activeIcon: Icon(CupertinoIcons.layers_fill),
                  label: 'Stack',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.square_split_2x1),
                  activeIcon: Icon(CupertinoIcons.square_split_2x1_fill),
                  label: 'Diffs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.sparkles),
                  label: 'Agents',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
