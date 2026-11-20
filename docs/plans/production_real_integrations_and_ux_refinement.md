# Production Real Integrations & VS Code-Grade UX Architecture

## 1. Executive Summary & Goals
This architectural blueprint elevates Otto from prototype state to a robust, VS Code- and GitHub Desktop-grade developer desktop application. It eliminates all mock/stub interactions, adds genuine GitHub account synchronization (via Personal Access Token and GitHub CLI detection), integrates real LLM model providers (Google Gemini, Anthropic Claude, OpenAI, and local Ollama), and provides intuitive repository management (opening local repos and tracking recent workspaces).

---

## 2. Architectural Pillars

### Pillar 1: Repository Management & Workspace Switching (VS Code Model)
- **Problem**: Otto previously assumed execution in the current directory with no UI to switch or open folders.
- **Solution**:
  - Daemon Endpoint `POST /api/workspace/open`: Accepts `{ "path": string }`, validates git root (`git rev-parse --show-toplevel`), parses branches/remotes, loads git status and diff hunks, and updates `.data/atomik-state.json`.
  - Daemon Endpoint `GET /api/workspace/recent`: Maintains MRU list of up to 10 recently opened workspaces.
  - Flutter UI:
    - Top CommandBar repository picker button `[Folder Icon] <RepoName> (v)` that opens a flyout listing open options and recent workspaces.
    - Directory picker integration via native file dialogs.
    - Clean empty state with "Open Git Repository..." when no active workspace is detected.

### Pillar 2: Genuine GitHub Account Integration & PR Stacking
- **Problem**: Remote pushes previously only incremented an in-memory counter (`highestPr++`) without contacting GitHub or executing `git push`.
- **Solution**:
  - Daemon Endpoint `POST /api/github/connect`: Accepts `{ "token": string, "method": "pat" | "gh_cli" }`.
    - If `gh_cli`, executes `gh auth token` to auto-detect existing developer credentials.
    - Validates token against `GET https://api.github.com/user` and verifies `repo` and `read:user` scopes.
    - Securely stores credentials and updates `GitHubConfig`.
  - Daemon Endpoint `POST /api/github/disconnect`: Clears credentials and resets status to disconnected.
  - Real Remote Push in `POST /api/git/push-stack`:
    - For each atomic commit slice in `stagedAtomicStack`:
      1. Creates/checks out tracking branch (`otto/<scope>`).
      2. Executes `git push -u origin <branch>`.
      3. Calls GitHub API `POST /repos/{owner}/{repo}/pulls` with conventional title, body bullets, and parent base branch.
      4. Persists the real PR number, HTML URL, and commit SHA into `pushedStack`.
  - Flutter UI:
    - Settings Dialog tab: "GitHub Account" with PAT input, GitHub CLI detection button, connection status, and token scope verification.
    - "Open PR" button in Branch Details opens the real GitHub URL via `url_launcher`.

### Pillar 3: Real LLM Model Configuration & Coding Agent Bridge
- **Problem**: Hardcoded providers with no API key inputs, non-existent `/llm/commit-message` endpoint, and mock `/api/ai/refine-stack`.
- **Solution**:
  - Daemon Endpoint `GET /api/llm/providers`: Returns supported providers (Gemini, Anthropic Claude, OpenAI, Ollama) and their active configuration state.
  - Daemon Endpoint `POST /api/llm/configure`: Validates and saves API keys and custom base URLs (e.g. `http://localhost:11434` for Ollama).
  - Daemon Endpoint `POST /llm/commit-message`: Generates conventional commit title and rationale bullets from diff hunks using the configured LLM API (with deterministic AST fallback if offline).
  - Daemon Endpoint `POST /api/ai/refine-stack`: Refines diff boundaries using LLM prompts to ensure atomic <= 80 LOC compliance.
  - Flutter UI:
    - Settings Dialog tab: "AI Models & Keys" with inputs for Gemini, Anthropic, OpenAI keys, and Ollama endpoint.
    - AI Agents Catalog: Clicking any agent card opens its configuration modal to enter credentials or launch CLI bridges.

### Pillar 4: UX Polish & Elimination of Dead-Ends
- **Empty State Actions**: Rewire "Refresh Working Tree", "Check for Changes", and "Check Workspace Changes" to call `workspaceNotifier.refreshWorkspace()`, eliminating the erroneous push modal trigger.
- **Working Changes File Selection**: Fix `onTap` in file list to set `_selectedWorkingCommitIndex = idx`, allowing users to inspect diffs across all modified files.
- **Git Commit Endpoint**: Implement `POST /api/git/commit` in Go daemon to commit staged hunks directly to git.
- **Branch Selector**: Make `_BranchPill` an interactive ComboBox displaying local git branches with checkout capability.

---

## 3. Implementation Phasing & Commit Slicing
Per Otto guardrails (<= 80 LOC per commit unit, unit tests coupled with implementation):
1. **Commit 1 (`docs(plans)`)**: This architectural design document.
2. **Commit 2 (`feat(daemon)`)**: Real GitHub PAT validation and CLI token discovery endpoints.
3. **Commit 3 (`feat(daemon)`)**: Real workspace repository opening and recent repositories tracking.
4. **Commit 4 (`feat(daemon)`)**: LLM providers configuration and `/llm/commit-message` generation.
5. **Commit 5 (`feat(daemon)`)**: Real git push and GitHub PR creation in `/api/git/push-stack`.
6. **Commit 6 (`feat(client)`)**: SettingsDialog tabs for GitHub PAT and LLM provider keys.
7. **Commit 7 (`feat(client)`)**: Workspace repository picker in CommandBar and Welcome screen.
8. **Commit 8 (`fix(client)`)**: Wire empty state refresh buttons, file selection index, and real PR URL launcher.
