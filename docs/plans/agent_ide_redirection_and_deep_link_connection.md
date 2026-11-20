# Agent & IDE Redirection and Deep-Link Connection Protocol

This specification establishes the standardized protocol for redirecting users to specific AI coding agents and IDEs (Google Antigravity, Cursor, VS Code, Windsurf, Claude Code) to establish direct bi-directional connections.

---

## 1. Problem Statement
Users expect external AI developer tools to behave like modern IDE companions (e.g. Docker Desktop, GitHub Desktop, Prisma Studio):
- Clicking "Connect" on an agent card should directly redirect the user to that agent/IDE.
- The connection must configure the workspace bridge automatically (rules, MCP tools, event webhooks) so the agent communicates seamlessly with Otto at `$0` extra token cost.

---

## 2. Agent Protocol Scheme & Redirection Matrix

| Agent / IDE | Official Deep-Link Protocol | CLI Executable Fallback | Workspace Bridge Injected |
|---|---|---|---|
| **Google Antigravity** | `antigravity://open?workspace=<path>` | `agy <path>`, `antigravity <path>` | `.agents/rules/otto.md` |
| **Cursor IDE** | `cursor://file/<path>`, `cursor://open?path=<path>` | `cursor <path>` | `.cursorrules`, `.cursor/rules/otto.md` |
| **VS Code (Copilot)** | `vscode://file/<path>`, `vscode://vscode.git/clone` | `code <path>` | `.vscode/settings.json` |
| **Windsurf** | `windsurf://file/<path>` | `windsurf <path>` | `.windsurfrules` |
| **Claude Code** | Terminal execution via loopback | `claude` | `CLAUDE.md` |

---

## 3. Backend Daemon Redirection Service (`POST /api/agents/connect`)

### Request
```json
{
  "agentId": "antigravity",
  "workspacePath": "C:/Users/olani/Desktop/olani/mile",
  "action": "redirect"
}
```

### Protocol Execution Flow
1. **Rule Provisioning**: Otto checks the target repository for agent-specific rules (e.g., `.agents/rules/otto.md` for Antigravity) and writes or validates the event webhook endpoint (`http://localhost:3000/api/antigravity/events`).
2. **URI Protocol Launch**: The daemon executes the OS-level protocol launcher:
   - Windows: `cmd.exe /c start <protocol-uri>`
   - macOS: `open <protocol-uri>`
   - Linux: `xdg-open <protocol-uri>`
3. **CLI Fallback**: If protocol launch exits with non-zero or executable not found, fallback to CLI command (`agy`, `cursor`, `code`).
4. **State Transition**: Daemon sets `IdeProfiles[agentId].Connected = true` and `Status = "watching_realtime"`, then broadcasts an SSE update.

---

## 4. Frontend UX Flow (Figma 90:1036 AI Agents View)
- In the **AI Agents** tab (`WindowsShellScreen`), each agent card offers:
  - Immediate connection status indicator (`Connected & Active` vs `Not connected`).
  - 1-Click **"Connect & Redirect"** button that calls `POST /api/agents/connect` and launches the target agent.
  - Detail flyout with permissions, auto-pilot toggles, and workspace rule verification.
