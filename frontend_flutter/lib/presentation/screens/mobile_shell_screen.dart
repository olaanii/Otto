import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../providers/diff_viewer_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/agent/agent_swimlane_card.dart';
import '../widgets/diff/virtual_diff_viewer.dart';
import '../widgets/hud/quick_commit_strip.dart';
import '../widgets/stack/stacked_pr_tree_view.dart';
import 'rebase_playground_screen.dart';
import 'settings_dialog.dart';

import '../platform/ios/ios_shell_screen.dart';

/// Adaptive mobile & tablet companion workspace using bottom navigation tabs.
class MobileShellScreen extends ConsumerStatefulWidget {
  const MobileShellScreen({super.key});

  @override
  ConsumerState<MobileShellScreen> createState() => _MobileShellScreenState();
}

class _MobileShellScreenState extends ConsumerState<MobileShellScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    // Dynamically route to authentic iOS 17/18 Cupertino shell when running on iOS
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return const IosShellScreen();
    }
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final diffState = ref.watch(diffViewerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stagedHunks = workspace.uncommittedDiffs
        .expand((f) => f.hunks)
        .where((h) => diffState.selectedHunkIds.contains(h.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.indigo600,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Center(
                child: Text('O', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Otto: ${workspace.currentBranch}', style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, size: 18),
            onPressed: () {
              showDialog(context: context, builder: (_) => const SettingsDialog());
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload, size: 18),
            onPressed: workspace.isLoading ? null : () => workspaceNotifier.pushStack(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          // Tab 0: Stacked PRs
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

          // Tab 1: Virtual Diff Viewer
          Column(
            children: [
              Expanded(
                child: VirtualDiffViewer(fileDiffs: workspace.uncommittedDiffs),
              ),
              if (stagedHunks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
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

          // Tab 2: Agents
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: workspace.activeAgents.map((agent) {
              return AgentSwimlaneCard(agent: agent);
            }).toList(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (idx) => setState(() => _currentTab = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: 'Stack',
          ),
          NavigationDestination(
            icon: Icon(Icons.difference_outlined),
            selectedIcon: Icon(Icons.difference),
            label: 'Diffs',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Agents',
          ),
        ],
      ),
    );
  }
}
