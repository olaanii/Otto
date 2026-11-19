# Plan: Comprehensive Demo Data Elimination & User-Controlled Agent Connections

## Objective
Fulfill the `/goal` to eradicate 100% of residual static demo/seed data across all views, tabs, and subviews of the Otto Windows desktop client, and ensure no agent is automatically connected on startup so the developer has complete manual control over agent connections.

## Identified Residual Demo Elements
1. **Windows Working Changes Subview (`_buildFigmaWorkingChangesView`)**:
   - Static file list: `app/stack.ts`, `ui/Sidebar.tsx`, `tests/stack.test.ts`, `config/eslint.json`.
   - Static commit list: `feat(stack): add DAG model`, `refactor(diff): split parser`, `test(stack): cycle checks`, `chore(eslint): update config`.
   - Static inspector diff: `app/stack.ts` with hardcoded diff lines.
   - Solution: Replace with dynamic binding to `diffs` and `stagedHunks`. When empty, render clean empty state ("Working tree clean").

2. **Windows Sync & Recovery Subview (`_buildFigmaSyncRecoveryView`)**:
   - Static pending commits: `a1f3c2d`, `7b2e9f0`, `c04d8a1`.
   - Static error banner: "Sync failed: remote rejected push (non fast-forward)".
   - Static log snippet: "› fetch origin/main ok", "› push feat/stack-pr rejected".
   - Solution: Replace with dynamic binding to `workspace.stackGraph.commits`. When in sync, render clean synced state ("Everything in sync").

3. **Windows Diff Viewer Tab (`_buildDiffViewerOnlyView`)**:
   - Static header: `app/stack.ts · split view`.
   - Static split diff table lines.
   - Solution: Replace with dynamic binding to `diffs`. When empty, render clean empty state ("No file diffs").

4. **Windows Rebase Canvas Tab (`_buildRebasePlaygroundView`)**:
   - Static rebase rows: `a1f3c2d`, `7b2e9f0`, `c04d8a1`, `e5a0b77`, `9d2c4e8`.
   - Solution: Replace with dynamic binding to `rebaseState.commits` / `workspace.stackGraph.commits`. When empty, render clean empty state ("No commits in stack").

5. **Windows Connected Agent Detail View (`_buildFigmaConnectedAgentDetail`)**:
   - Static email: `olani@astu.edu.et`, plan `Team`, credentials `Keychain · ••••7f3a`.
   - Static working commits and inspector.
   - Solution: Dynamic data from active session / profile, and dynamic commit list.

6. **Agent Connection State Control**:
   - All agents must default to `Connected: false` / `isActive: false` / `status: 'idle'`.
   - Developer has full control to connect/disconnect agents manually.

## Verification
- Run `flutter analyze` ensuring 0 warnings/errors.
- Run `flutter test` verifying widget and provider test suites pass.
- Build clean Windows release binary and test runtime execution.
