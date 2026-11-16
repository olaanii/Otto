import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../domain/models/diff_hunk.dart';
import '../providers/diff_viewer_provider.dart';
import '../providers/hotkey_hud_provider.dart';
import '../providers/llm_selector_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/agent/agent_swimlane_card.dart';
import '../widgets/agent/prompt_stream_ticker.dart';
import '../widgets/diff/virtual_diff_viewer.dart';
import '../widgets/hud/floating_hud_card.dart';
import '../widgets/hud/quick_commit_strip.dart';
import '../widgets/navbar/github_sync_navbar.dart';
import '../widgets/stack/stacked_pr_tree_view.dart';
import 'rebase_playground_screen.dart';
import 'settings_dialog.dart';

/// 3-pane master-detail desktop workspace providing real-time stacked PR visualization,
/// 120 FPS diff rendering, agent swimlanes, and atomic commit slicing.
class DesktopShellScreen extends ConsumerWidget {
  const DesktopShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final hudState = ref.watch(hotkeyHudProvider);
    final llmState = ref.watch(llmSelectorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect currently staged hunks across all files
    final stagedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Top Navbar
              GithubSyncNavbar(
                onOpenRebase: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RebasePlaygroundScreen(),
                    ),
                  );
                },
                onOpenSettings: () {
                  showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  );
                },
                onToggleHud: () {
                  ref.read(hotkeyHudProvider.notifier).toggleHud();
                },
              ),

              // 2. Main 3-Pane Body
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pane 1: Stacked PR Tree & Agent Swimlanes (Left, ~340px)
                    Container(
                      width: 340,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                        border: Border(
                          right: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Agent Swimlanes Section
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.smart_toy_outlined, size: 15, color: AppColors.indigo500),
                                const SizedBox(width: 8),
                                const Text(
                                  'Active IDE AI Agents',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ],
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

                          const Divider(height: 1),

                          // AI Refine Stack Action Button
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: FilledButton.tonalIcon(
                              onPressed: llmState.isRefining
                                  ? null
                                  : () => ref
                                      .read(llmSelectorProvider.notifier)
                                      .refineUncommittedDiffs(),
                              icon: llmState.isRefining
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_awesome, size: 15),
                              label: Text(
                                llmState.isRefining
                                    ? 'AI Analyzing Stack...'
                                    : 'AI Slice & Refine Stack',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(36),
                              ),
                            ),
                          ),

                          // Stack Tree
                          Expanded(
                            child: StackedPrTreeView(
                              commits: workspace.stackGraph.commits,
                              selectedCommitId: workspace.selectedCommitId,
                              onCommitSelected: (c) {
                                workspaceNotifier.selectCommit(c.id);
                              },
                              onOpenRebaseCanvas: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RebasePlaygroundScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pane 2: Virtual Diff Viewer (Center, Flex)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Live Prompt Ticker if AI is active
                          if (llmState.activeStreamingText != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: PromptStreamTicker(
                                text: llmState.activeStreamingText!,
                                isStreaming: llmState.isRefining,
                              ),
                            ),

                          // Virtual Diff Viewer
                          Expanded(
                            child: VirtualDiffViewer(
                              fileDiffs: workspace.uncommittedDiffs,
                            ),
                          ),

                          // Pane 3 Bottom Strip: Quick Commit Strip
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              border: Border(
                                top: BorderSide(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating HUD Overlay (Positioned top-right when activated)
          if (hudState.isHudVisible)
            const Positioned(
              top: 60,
              right: 20,
              width: 520,
              height: 420,
              child: FloatingHudCard(),
            ),
        ],
      ),
    );
  }
}
