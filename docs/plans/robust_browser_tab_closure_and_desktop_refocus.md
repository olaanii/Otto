# Plan: Robust Browser Tab Closure & Native Desktop Window Refocus

## Problem Statement
Standard browser security models restrict `window.close()` from terminating tabs that were not spawned directly by `window.open()`. If Otto opens the browser via an OS launch command, `window.close()` is denied by modern Chromium/WebKit browsers, stranding the user on the authorization tab.

## Solution Architecture
Implement a multi-tier fallback mechanism combining client-side techniques, deep-link routing, and daemon-level OS window activation:

### 1. Browser-Side Triple-Fallback Handshake (`agent_auth_page.go`)
- **Tier 1 (Scripted Self-Close)**: Execute `window.open('', '_self'); window.close();` immediately upon authorization approval.
- **Tier 2 (Deep Link Refocus)**: Dispatch an invisible iframe to `otto://connected` / `antigravity://open` to request the OS focus the native client.
- **Tier 3 (Interactive Visual State)**: If the tab cannot be closed by script, transform the UI to an unambiguous, animated green confirmation state:
  - Display *"✓ Authorization Confirmed!"*.
  - Show a 3-second animated countdown with a prominent button: **[Return to Otto Desktop]**.
  - Provide a clear fallback note: *"You can safely close this browser tab."*

### 2. Daemon-Side Native OS Window Focus (`agent_handshake.go`)
- When `POST /api/agents/confirm` successfully verifies the handshake token:
  - On Windows: Run non-blocking PowerShell `(New-Object -ComObject WScript.Shell).AppActivate('Otto')` to bring Otto's window to the foreground.
  - On macOS: Run `osascript -e 'tell application "Otto" to activate'`.
  - On Linux: Run `wmctrl -x -a otto` if available.

### 3. Flutter Client Window Management (`windows_agent_connector.dart`)
- Upon receiving `agent_connected` SSE or completing handshake refresh:
  - Call `windowManager.show()` and `windowManager.focus()`.
  - Automatically close the pending handshake modal.
  - Render a green Fluent InfoBar indicating successful connection.

## Slicing Plan (<= 80 LOC per commit)
1. `docs(plans)`: This architectural plan.
2. `feat(daemon)`: Implement OS window refocus in `agent_handshake.go`.
3. `feat(daemon)`: Upgrade `agent_auth_page.go` with triple-fallback self-close, countdown, and deep-link redirect.
4. `feat(ui)`: Integrate `windowManager.focus()` in `windows_agent_connector.dart`.
