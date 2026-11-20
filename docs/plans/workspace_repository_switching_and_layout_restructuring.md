# Architecture Plan: Multi-Repository Switching, Auto-Init, and VS Code-Style Layout Restructuring

## 1. Problem Statement & Root Cause
1. **Repository Opening Failure (HTTP 400 ServerException)**:
   - When a user selects or types a folder path like `C:\Users\olani\Desktop\olani\mile`, the Go daemon executes `git -C <path> rev-parse --show-toplevel`.
   - Because `mile` does not yet have a `.git` folder, the daemon returns `HTTP 400 Bad Request` with `{"ok": false, "error": "Directory is not a valid git repository"}`.
   - On the Flutter side, `Dio` throws a raw `ServerException (code: 400)`, which is surfaced directly to the user as an unhandled error toast.
   - **Resolution**:
     - If the folder exists on disk, support automatic or 1-click initialization (`git init -b main`).
     - Daemon endpoint `/api/workspace/open` gracefully initializes non-git folders when requested and returns `HTTP 200` with `{ "ok": true, "path": topLevel, "activeBranch": "main", "isNewRepo": true }`.
     - If a folder does not exist, return a friendly `{ "ok": false, "error": "Folder not found" }` without HTTP 400 status code exceptions.

2. **Daemon Assumed Single Working Directory (Otto)**:
   - The daemon's internal state, branch detection (`detectGitBranches`), remote detection (`detectGitRemoteOrigin`), and diff analysis (`/api/git/analyze`) were executed against the process working directory instead of the dynamically active `s.antigravity.WorktreePath`.
   - Opening another repository failed to update the active working tree diffs, branches, and commit stack.
   - **Resolution**:
     - Route all git operations through `git -C <activeWorktree> ...`.
     - When opening a new workspace, reload branch, remote, git status, and diffs for that specific repository.
     - Provide `/api/git/analyze` with the real unified diff generated from `git -C <worktree> diff HEAD` and untracked files.

3. **Layout Overwhelm with Multiple Agents & Repositories**:
   - Currently, agent swimlanes, stacks, and diffs are mixed into heavy overlapping views that overwhelm users when multiple agents are active.
   - **Resolution (VS Code Mental Model)**:
     - **Top Header**: Active Repository Switcher with recent workspaces flyout, branch indicator, sync status, and GitHub account.
     - **Left Activity Rail & Sidebar**:
       - *Changes & Slicer* (Source Control view: Working Files, Staging checkboxes, Quick Commit Strip).
       - *PR Stacks & DAG* (Linear stacked PRs, branch relationships, rebase canvas).
       - *Agent Activity* (Compact swimlane showing active agent background actions, non-blocking).
       - *Settings* (GitHub PAT, AI models, Guardrail policies).
     - **Center Stage**: Focused Unified/Split Diff Viewer with hunk checkboxes and "Stage Hunk" actions.
     - **Bottom Status Bar**: Active repo name, branch, ahead/behind sync status, active AI model indicator, and daemon connection status.

## 2. Implementation Slices (<= 80 LOC each)
1. `docs(plans)`: Dedicated planning document commit.
2. `feat(daemon)`: Auto-initialization and dynamic worktree git command execution in Go daemon.
3. `test(daemon)`: Unit tests for opening existing repos, non-git project folders (auto-init), and dynamic worktree diffing.
4. `feat(workspace)`: Flutter workspace provider repository switching, error handling, and folder picker/init flow.
5. `feat(layout)`: Windows 11 Fluent layout restructuring adopting clean VS Code activity rail, status bar, and non-overwhelming agent indicator.
6. `test(flutter)`: Widget tests verifying repository switching and restructured layout.
7. Verification on real target: `C:\Users\olani\Desktop\olani\mile`.
