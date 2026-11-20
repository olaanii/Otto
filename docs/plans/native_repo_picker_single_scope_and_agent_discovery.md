# Native Repository Selection, Single-Repo Scoped State, and LLM Agent Project Discovery

## 1. Overview
This architectural plan establishes a unified single-repository scoping model across all Otto desktop views, replaces manual path entry with the native Windows File Explorer directory picker, ensures safe auto-initialization for non-git project directories, and implements automated project discovery from connected LLM agents (Claude Code/Desktop, Google Antigravity, and Codex/Cursor/VS Code) using strictly real data.

---

## 2. Architecture & Components

### 2.1 Native Windows Folder Picker (`CommandBar`)
- **First-party Desktop Integration**: Utilize `package:file_selector` (`getDirectoryPath()`) to invoke the native Windows `IFileDialog` directory browser directly from the CommandBar and empty states.
- **Auto-Initialization Safety**: When a directory is chosen:
  1. Daemon calls `git rev-parse --show-toplevel`.
  2. If the folder is not a Git repository, cleanly executes `git init -b main`.
  3. Returns `isNewRepo: true`, `activeBranch: "main"`, avoiding any HTTP 400 Bad Request responses.

### 2.2 Single Active Repository Scoping (Zero Cross-Repo Leakage)
- **Global Workspace State Scoping**:
  - `WorkspaceState.repositoryPath` and `repositoryName` uniquely identify the single active project.
  - When switching repositories:
    1. `DiffViewerNotifier.clearSelection()` immediately purges all selected hunk IDs and file paths.
    2. Selected branch and commit indices reset to `0`.
    3. Backend daemon refreshes `s.antigravity.WorktreePath` and re-analyzes working tree diffs exclusively for the active worktree directory.
- **View Auditing**:
  - **Diff Viewer**: Displays only real hunks from `git diff` / `git status` of the active directory. Clean state displays verified empty view.
  - **Stacked PRs**: Displays only real commits from `git log` of the active repository.
  - **Eliminate Demo Data**: Zero hardcoded strings, dummy commit lists, or simulated reviewers.

### 2.3 Connected LLM Agent Project Discovery
- **Native Local Agent Scanner**:
  - **Claude**: Inspect `~/.claude/projects/` directory. Folder names encoded as `C--Users-...` are decoded to Windows paths (`C:\Users\...`). Verified against `os.Stat` for directory existence and Git status.
  - **Google Antigravity**: Inspect `~/.gemini/antigravity/worktrees/` and current session bridge metadata.
  - **Codex / VS Code / Cursor**: Parse SQLite `state.vscdb` (`AppData/Roaming/Code/User/globalStorage/state.vscdb` and `AppData/Roaming/Cursor/User/globalStorage/state.vscdb`) for `history.recentlyOpenedPathsList`.
  - **Live Handshake Bridge**: Automatically discover and import any project path passed during interactive IDE handshake.
- **UI Surface**:
  - **Open Repository Dialog / Flyout**: Surface discovered projects grouped by agent with a 1-click "Open in Otto" button.
  - **AI Agent Cards**: Display discovered projects directly on the agent's card with quick-switch actions.

---

## 3. Implementation Steps & Conventional Commits
1. `docs(plans)`: Architecture specification for native repo picker, single scoping, and agent discovery.
2. `feat(daemon)`: Implement `DiscoverAgentProjects` engine scanning Claude, Antigravity, and Codex/VS Code.
3. `test(daemon)`: Unit tests for agent project path decoding and discovery.
4. `feat(daemon)`: Expose `/api/agents/discovered-projects` and auto-import on connection.
5. `feat(ui)`: Wire native `getDirectoryPath()` in CommandBar and open repository flows.
6. `feat(workspace)`: Implement single-repo state scoping, purge stale diff/hunk state on repository switch.
7. `feat(ui)`: Surface discovered agent projects in Open Repository modal and Agent Cards.
8. `fix(ui)`: Purge any remaining mock/demo data across all views.
9. `build`: Rebuild `Otto.exe` and `otto_frontend.exe`, verify with real repos (`mile` and `Otto`).
