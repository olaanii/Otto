# Antigravity Direct Local Integration & Handshake Architecture

## 1. Official Antigravity Architecture Findings
According to the official Google Antigravity documentation (`https://antigravity.google/docs/overview`, `https://antigravity.google/docs/rules-workflows`):
1. **Local-First Model**: Antigravity is designed to operate locally on the developer's workstation. Agents interact with local files, git worktrees, terminals, MCP servers, and background daemons directly.
2. **$0 Hosting & Domain Requirement**: No external domain, public URL, or cloud hosting is required. Antigravity communicates with background daemons (like Otto) over standard loopback HTTP (`http://localhost:3000`).
3. **Rule Discovery System**:
   - Workspace rules: Antigravity automatically discovers rules in `<workspace>/.agents/rules/*.md`.
   - Global rules: Antigravity discovers rules in `~/.gemini/config/rules/*.md` and `~/.gemini/AGENTS.md`.
4. **Turn Notification Flow**: Agents observing `.agents/rules/otto.md` dispatch turn completion events via `POST http://localhost:3000/api/antigravity/events`.

## 2. Root Cause of "Waiting to Connect But Nothing Happened"
1. In `cmd/daemon/agent_launcher.go`, `launchAgentHandshake` was executing:
   `_ = exec.Command("cmd", "/c", cli, targetDir).Run()`
   where `cli` was `"agy"`. Because `agy` is an interactive console application and `.Run()` waits synchronously for process termination without stdin, the goroutine blocked indefinitely.
2. The subsequent line `exec.Command("cmd", "/c", "start", "", authUrl).Run()` was never reached, preventing the browser authorization tab from opening.
3. The Flutter handshake dialog (`windows_agent_connector.dart`) lacked:
   - An explicit "Open in Browser ↗" fallback link.
   - Real-time polling/SSE detection to automatically dismiss the waiting modal once the user clicks "Authorize" in the browser.

## 3. Implementation Plan
1. **Daemon Non-Blocking Handshake (`cmd/daemon/agent_launcher.go`)**:
   - Immediately launch `authUrl` using `.Start()` so the browser opens instantly.
   - Launch IDE or CLI processes in detached windows (`start agy`) without blocking.
   - Provision both local (`<workspace>/.agents/rules/otto.md`) and global (`~/.gemini/config/rules/otto.md`) rules with the full authentic Otto specification.
2. **Flutter Interactive Handshake (`windows_agent_connector.dart`)**:
   - Provide a direct "Open in Browser ↗" action.
   - Auto-poll connection state every 1s while dialog is active so confirmation happens automatically.
