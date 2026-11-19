import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/domain/models/atomic_commit_unit.dart';
import 'package:otto_frontend/domain/models/clerk_user_session.dart';
import 'package:otto_frontend/domain/models/diff_hunk.dart';
import 'package:otto_frontend/domain/models/guardrail_policy.dart';
import 'package:otto_frontend/domain/models/ide_agent_profile.dart';
import 'package:otto_frontend/domain/models/llm_provider_config.dart';
import 'package:otto_frontend/domain/models/stack_dependency_graph.dart';
import 'package:otto_frontend/presentation/platform/windows/windows_command_bar.dart';
import 'package:otto_frontend/presentation/platform/windows/windows_content_dialog.dart';
import 'package:otto_frontend/presentation/platform/windows/windows_fluent_theme.dart';
import 'package:otto_frontend/presentation/platform/windows/windows_navigation_view.dart';
import 'package:otto_frontend/presentation/platform/windows/windows_shell_screen.dart';
import 'package:otto_frontend/presentation/platform/windows/windows_title_bar.dart';
import 'package:otto_frontend/presentation/providers/auth_state_provider.dart';
import 'package:otto_frontend/presentation/providers/diff_viewer_provider.dart';
import 'package:otto_frontend/presentation/providers/hotkey_hud_provider.dart';
import 'package:otto_frontend/presentation/providers/llm_selector_provider.dart';
import 'package:otto_frontend/presentation/providers/rebase_canvas_provider.dart';
import 'package:otto_frontend/presentation/providers/workspace_provider.dart';

// --- Test Fakes & Helpers ---

class FakeWorkspaceNotifier extends StateNotifier<WorkspaceState>
    implements WorkspaceNotifier {
  FakeWorkspaceNotifier([WorkspaceState? state])
      : super(
          state ??
              WorkspaceState(
                activeAgents: [
                  IdeAgentProfile(
                    id: 'claude-code',
                    name: 'Claude Code',
                    description: 'Terminal coding agent',
                    colorHex: '#D97757',
                    iconKey: 'claude',
                    isActive: true,
                    lastActiveAt: DateTime.now(),
                  ),
                  IdeAgentProfile(
                    id: 'cursor',
                    name: 'Cursor',
                    description: 'AI code editor',
                    colorHex: '#5C5C66',
                    iconKey: 'cursor',
                    isActive: true,
                    lastActiveAt: DateTime.now(),
                  ),
                ],
                stackGraph: StackDependencyGraph(
                  commits: [
                    AtomicCommitUnit(
                      id: 'c1',
                      type: 'feat',
                      scope: 'stack',
                      summary: 'feat/stack-model',
                      branchName: 'feat/stack-model',
                      prNumber: 241,
                      status: CommitStatus.readyToPush,
                      isPushed: true,
                      additions: 30,
                      deletions: 5,
                    ),
                    AtomicCommitUnit(
                      id: 'c2',
                      type: 'feat',
                      scope: 'diff',
                      summary: 'feat/diff-parser',
                      branchName: 'feat/diff-parser',
                      prNumber: 242,
                      status: CommitStatus.draft,
                      parentCommitId: 'c1',
                      additions: 45,
                      deletions: 10,
                    ),
                    AtomicCommitUnit(
                      id: 'c3',
                      type: 'feat',
                      scope: 'dag',
                      summary: 'feat/dag-view',
                      branchName: 'feat/dag-view',
                      prNumber: 243,
                      status: CommitStatus.inReview,
                      parentCommitId: 'c2',
                      additions: 20,
                      deletions: 2,
                    ),
                    AtomicCommitUnit(
                      id: 'c4',
                      type: 'fix',
                      scope: 'rebase',
                      summary: 'fix/rebase-conflict',
                      branchName: 'fix/rebase-conflict',
                      prNumber: 244,
                      status: CommitStatus.readyToPush,
                      parentCommitId: 'c3',
                      additions: 15,
                      deletions: 3,
                    ),
                  ],
                ),
              ),
        );

  @override
  Future<void> refreshWorkspace() async {}

  @override
  void selectCommit(String? commitId) {
    state = state.copyWith(selectedCommitId: commitId);
  }

  @override
  void updateGuardrailPolicy(GuardrailPolicy policy) {
    state = state.copyWith(guardrailPolicy: policy);
  }

  @override
  Future<AtomicCommitUnit?> commitSelectedHunks({
    required String summary,
    String? description,
    required String type,
    String? scope,
    required List<DiffHunk> hunks,
  }) async {
    return null;
  }

  @override
  Future<bool> pushStack() async {
    return true;
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier([AuthState? state])
      : super(
          state ??
              AuthState(
                status: AuthStatus.authenticated,
                session: ClerkUserSession(
                  userId: 'user_otto_win11',
                  email: 'win11@otto.dev',
                  fullName: 'Windows Developer',
                  sessionToken: 'session_token_win11',
                  jwt: 'jwt_token_win11',
                  expiresAt: DateTime.now().add(const Duration(days: 14)),
                  isGithubConnected: true,
                  githubUsername: 'otto-windows-dev',
                ),
              ),
        );

  @override
  Future<void> checkActiveSession() async {}

  @override
  Future<bool> signInWithTicket(String ticket) async => true;

  @override
  Future<void> signOut() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

class FakeLlmSelectorNotifier extends StateNotifier<LlmSelectorState>
    implements LlmSelectorNotifier {
  FakeLlmSelectorNotifier([LlmSelectorState? state])
      : super(state ?? LlmSelectorState(providers: LlmProviderConfig.standardProviders));

  @override
  Future<void> loadProviders() async {}

  @override
  void selectProvider(LlmProviderConfig provider) {
    state = state.copyWith(selectedProvider: provider);
  }

  @override
  Future<List<AtomicCommitUnit>> refineUncommittedDiffs({String? instructions}) async => [];

  @override
  Future<({String description, String? scope, String summary, String type})>
      generateConventionalCommit(List<DiffHunk> hunks) async {
    return (
      type: 'feat',
      scope: 'windows-ui',
      summary: 'implement Windows 11 Fluent desktop suite',
      description: 'Comprehensive widget tests verifying Fluent Mica desktop UI',
    );
  }
}

List<Override> createTestOverrides({
  WorkspaceState? workspaceState,
  AuthState? authState,
  LlmSelectorState? llmState,
}) {
  return [
    workspaceProvider.overrideWith((ref) => FakeWorkspaceNotifier(workspaceState)),
    authStateProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
    llmSelectorProvider.overrideWith((ref) => FakeLlmSelectorNotifier(llmState)),
  ];
}

Widget createTestApp({
  required Widget child,
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? createTestOverrides(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('1. WindowsShellScreen Desktop Screen Size Rendering', () {
    testWidgets('renders cleanly at 1280x800 resolution with zero exceptions', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const WindowsShellScreen()));
      await tester.pumpAndSettle();

      // Verify core top-level Windows 11 components
      expect(find.byType(WindowsShellScreen), findsOneWidget);
      expect(find.byType(WindowsTitleBar), findsOneWidget);
      expect(find.byType(WindowsCommandBar), findsOneWidget);
      expect(find.byType(WindowsNavigationView), findsOneWidget);

      // Verify Titlebar content
      expect(find.text('Otto'), findsWidgets);
      expect(find.textContaining('Windows 11 Fluent Workspace'), findsOneWidget);

      // Verify CommandBar items
      expect(find.text('Sync now'), findsOneWidget);
      expect(find.text('Refine with AI'), findsOneWidget);
      expect(find.text('Auto-Pilot'), findsOneWidget);

      // Verify NavigationView items
      expect(find.text('Stacked PRs'), findsWidgets);
      expect(find.text('Diff Viewer'), findsOneWidget);
      expect(find.text('Rebase Playground'), findsOneWidget);
      expect(find.text('AI Agents'), findsWidgets);

      // Assert zero exceptions / overflows occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1920x1080 Full HD resolution with zero exceptions', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const WindowsShellScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(WindowsShellScreen), findsOneWidget);
      expect(find.byType(WindowsTitleBar), findsOneWidget);
      expect(find.byType(WindowsCommandBar), findsOneWidget);
      expect(find.byType(WindowsNavigationView), findsOneWidget);

      // Verify default Tab 0 Figma Stacked PR branches
      expect(find.text('feat/stack-model'), findsOneWidget);
      expect(find.text('feat/diff-parser'), findsOneWidget);
      expect(find.text('feat/dag-view'), findsOneWidget);
      expect(find.text('fix/rebase-conflict'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('2. WindowsShellScreen Tab and Subview Switching', () {
    testWidgets('switches between Stacked PRs and Working changes subviews in Tab 0', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const WindowsShellScreen()));
      await tester.pumpAndSettle();

      // Initial subview: Stacked PRs (Figma 90:633)
      expect(find.text('feat/stack-model'), findsOneWidget);
      expect(find.textContaining('PR #241'), findsOneWidget);
      expect(find.text('feat/diff-parser'), findsOneWidget);
      expect(find.text('feat/dag-view'), findsOneWidget);
      expect(find.text('fix/rebase-conflict'), findsOneWidget);

      // Switch to Working changes subview (Figma 90:707)
      final workingChangesBtn = find.text('Working changes');
      expect(workingChangesBtn, findsOneWidget);
      await tester.tap(workingChangesBtn);
      await tester.pumpAndSettle();

      // Verify Working changes content rendered (Clean empty state)
      expect(find.text('Working tree clean'), findsOneWidget);

      // Switch back to Stacked PRs subview
      // Find the subview button inside the subview switcher
      final stackedPrsBtn = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == const Color(0xFF2B2B2B),
        ),
        matching: find.text('Stacked PRs'),
      );
      expect(stackedPrsBtn, findsOneWidget);
      await tester.tap(stackedPrsBtn);
      await tester.pumpAndSettle();

      // Verify Stacked PRs branch list is visible again
      expect(find.text('feat/stack-model'), findsOneWidget);
      expect(find.textContaining('PR #241'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches to Diff Viewer (Tab 1)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const WindowsShellScreen()));
      await tester.pumpAndSettle();

      // Tap on Diff Viewer in NavigationView
      final diffViewerNavTile = find.widgetWithText(GestureDetector, 'Diff Viewer');
      expect(diffViewerNavTile, findsOneWidget);
      await tester.tap(diffViewerNavTile);
      await tester.pumpAndSettle();

      // Verify Diff Viewer view rendered (Clean empty state)
      expect(find.text('No file diffs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches to Rebase Playground (Tab 2)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const WindowsShellScreen()));
      await tester.pumpAndSettle();

      // Tap on Rebase Playground in NavigationView
      final rebaseNavTile = find.widgetWithText(GestureDetector, 'Rebase Playground');
      expect(rebaseNavTile, findsOneWidget);
      await tester.tap(rebaseNavTile);
      await tester.pumpAndSettle();

      // Verify Rebase canvas view rendered
      expect(find.text('Rebase canvas'), findsOneWidget);
      expect(find.textContaining('commits in stack'), findsOneWidget);
      expect(find.textContaining('feat/stack-model'), findsWidgets);
      expect(find.textContaining('feat/diff-parser'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches to AI Agents (Tab 3)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const WindowsShellScreen()));
      await tester.pumpAndSettle();

      // Tap on AI Agents in NavigationView
      final agentsNavTile = find.widgetWithText(GestureDetector, 'AI Agents');
      expect(agentsNavTile, findsOneWidget);
      await tester.tap(agentsNavTile);
      await tester.pumpAndSettle();

      // Verify AI Agent picker view rendered (Figma 90:1036)
      expect(find.text('Connect your AI agents to Otto'), findsOneWidget);
      expect(find.text('Claude Code'), findsWidgets);
      expect(find.text('Cursor'), findsWidgets);
      expect(find.text('Codex'), findsWidgets);
      expect(find.text('Terminal coding agent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('3. Windows TitleBar, CommandBar, and NavigationView Component Tests', () {
    testWidgets('WindowsTitleBar renders brand, subtitle, and caption buttons cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            appBar: const WindowsTitleBar(
              title: 'Otto Custom Title',
              subtitle: 'Windows 11 Fluent Workspace • feat/branch-test',
            ),
            body: Container(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Otto Custom Title'), findsOneWidget);
      expect(find.text('Windows 11 Fluent Workspace • feat/branch-test'), findsOneWidget);

      // Verify caption control tooltips
      expect(find.byTooltip('Minimize'), findsOneWidget);
      expect(find.byTooltip('Maximize'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('WindowsCommandBar renders branch pill, buttons, switch, and user profile cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool autoPilotToggled = false;
      bool syncClicked = false;
      bool refineClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: WindowsCommandBar(
              currentBranch: 'feat/fluent-test',
              pendingCommitCount: 5,
              isAutoPilot: false,
              userSession: ClerkUserSession(
                userId: 'user_test',
                email: 'test@otto.dev',
                fullName: 'Alice Dev',
                sessionToken: 'token_123',
                jwt: 'jwt_123',
                expiresAt: DateTime.now().add(const Duration(days: 7)),
              ),
              onAutoPilotChanged: (val) => autoPilotToggled = val,
              onSyncNow: () => syncClicked = true,
              onRefineWithAi: () => refineClicked = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check branch pill
      expect(find.text('feat/fluent-test'), findsOneWidget);

      // Check Sync now with badge count
      expect(find.text('Sync now'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Check Refine with AI button
      expect(find.text('Refine with AI'), findsOneWidget);

      // Check Auto-Pilot switch and toggle interaction
      expect(find.text('Auto-Pilot'), findsOneWidget);
      final switchFinder = find.byType(FluentToggleSwitch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(autoPilotToggled, isTrue);

      // Check Sync now tap
      await tester.tap(find.text('Sync now'));
      await tester.pumpAndSettle();
      expect(syncClicked, isTrue);

      // Check Refine with AI tap
      await tester.tap(find.text('Refine with AI'));
      await tester.pumpAndSettle();
      expect(refineClicked, isTrue);

      // Check User pill
      expect(find.text('Alice Dev'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('WindowsNavigationView renders expanded and collapsed states without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int selectedIndex = 0;

      final navItems = [
        const FluentNavigationItem(
          label: 'Stacked PRs',
          icon: Icons.account_tree_outlined,
          badgeCount: 4,
        ),
        const FluentNavigationItem(
          label: 'Diff Viewer',
          icon: Icons.difference_outlined,
          badgeCount: 9,
        ),
        const FluentNavigationItem(
          label: 'Rebase Playground',
          icon: Icons.tune_rounded,
        ),
        const FluentNavigationItem(
          label: 'AI Agents',
          icon: Icons.smart_toy_outlined,
          badgeCount: 2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Row(
              children: [
                WindowsNavigationView(
                  selectedIndex: selectedIndex,
                  onIndexChanged: (idx) => selectedIndex = idx,
                  items: navItems,
                  activeAgents: [
                    IdeAgentProfile(
                      id: 'antigravity',
                      name: 'Google Antigravity',
                      description: 'Autonomous Coding & Slicing Agent',
                      colorHex: '#4285F4',
                      iconKey: 'bot',
                      isActive: true,
                      lastActiveAt: DateTime.now(),
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expanded pane checks
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Active IDE Agents'), findsOneWidget);
      expect(find.text('Settings & Policy'), findsOneWidget);
      expect(find.text('Stacked PRs'), findsOneWidget);

      // Collapse navigation pane via menu button
      final menuButton = find.byTooltip('Collapse Navigation Pane');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // After collapse, text labels are hidden
      expect(find.text('Workspace'), findsNothing);
      expect(find.text('Active IDE Agents'), findsNothing);

      // Re-expand navigation pane
      final expandButton = find.byTooltip('Expand Navigation Pane');
      expect(expandButton, findsOneWidget);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Labels re-appear
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Active IDE Agents'), findsOneWidget);

      // Verify zero RenderFlex overflows throughout collapse/expand
      expect(tester.takeException(), isNull);
    });
  });

  group('4. Windows11KeyboardShortcutsDialog Tests', () {
    testWidgets('renders all keyboard shortcut sections, labels, and keycaps', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Windows11KeyboardShortcutsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Keyboard shortcuts'), findsOneWidget);
      expect(find.text('Otto · Ctrl-based shortcuts on Windows'), findsOneWidget);

      // Section titles
      expect(find.text('WORKSPACE'), findsOneWidget);
      expect(find.text('GLOBAL'), findsOneWidget);
      expect(find.text('COMMIT'), findsOneWidget);
      expect(find.text('REBASE CANVAS'), findsOneWidget);

      // Workspace shortcuts
      expect(find.text('Open HUD'), findsOneWidget);
      expect(find.text('Stacked PRs'), findsOneWidget);
      expect(find.text('Diff Viewer'), findsOneWidget);
      expect(find.text('Rebase Canvas'), findsOneWidget);
      expect(find.text('AI Agents'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Global shortcuts
      expect(find.text('Sync now'), findsOneWidget);
      expect(find.text('Toggle Auto-Pilot'), findsOneWidget);

      // Commit shortcuts
      expect(find.text('Generate message'), findsOneWidget);
      expect(find.text('Stage hunk'), findsOneWidget);
      expect(find.text('Unstage hunk'), findsOneWidget);
      expect(find.text('Commit'), findsOneWidget);

      // Rebase canvas shortcuts
      expect(find.text('Move commit up'), findsOneWidget);
      expect(find.text('Move commit down'), findsOneWidget);
      expect(find.text('Apply rebase'), findsOneWidget);

      // Keycaps
      expect(find.text('Ctrl'), findsWidgets);
      expect(find.text('Shift'), findsWidgets);
      expect(find.text('K'), findsWidgets);
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(find.text('Alt'), findsWidgets);
      expect(find.text('Enter'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('dismisses cleanly when close button is tapped via show() method', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => Windows11KeyboardShortcutsDialog.show(context),
                  child: const Text('Open Shortcuts Dialog'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Shortcuts Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Windows11KeyboardShortcutsDialog), findsOneWidget);

      // Tap close button (Icons.close)
      final closeButton = find.widgetWithIcon(IconButton, Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(Windows11KeyboardShortcutsDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
