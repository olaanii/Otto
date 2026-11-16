# Otto Universal IDE Extension

Universal IDE extension for **Cursor**, **VS Code**, **Windsurf**, **Kiro**, and **Google Antigravity**.

Otto intercepts AI agent code edits and auto-slices dirty worktrees into concise, reviewable (<80 LOC) atomic commits with Conventional Commit headers and stacked GitHub Pull Requests.

---

## ⚡ Quick Start

### 1. Requirements
Ensure the Otto native Go daemon or local backend server is running:
```bash
# In the repository root
go run cmd/daemon/main.go
# Or Node/Express development server
npm run dev
```

### 2. Keybindings & Shortcuts

| Shortcut (Win / Linux) | Shortcut (macOS) | Action |
|---|---|---|
| `Ctrl+Shift+K` | `Cmd+Shift+K` | **Otto: Open Atomic Slicer HUD** (Floating interactive overlay) |
| Command Palette | Command Palette | `Otto: Slice & Commit Current Changes` |
| Command Palette | Command Palette | `Otto: Sync Stacked PRs with GitHub` |
| Command Palette | Command Palette | `Otto: Toggle Background Auto-Pilot Daemon` |

---

## ⚙️ Extension Settings

| Setting | Default | Description |
|---|---|---|
| `otto.daemonUrl` | `http://localhost:3000` | Base URL of the Otto Go backend daemon |
| `otto.clerkToken` | `""` | Clerk JWT session token for authenticated remote stack sync |
| `otto.autoPilot` | `true` | Auto-slice and stage atomic commits whenever files are saved |
| `otto.maxLocPerCommit` | `80` | Maximum LOC threshold per atomic commit unit |

---

## 🚀 Building & Packaging

```bash
cd ide_extension
npm install
npm run compile
npx vsce package -o otto-ide-extension.vsix
```

Install the resulting `.vsix` into any compatible IDE:
- **VS Code**: `code --install-extension otto-ide-extension.vsix`
- **Cursor**: `cursor --install-extension otto-ide-extension.vsix`
- **Windsurf**: `windsurf --install-extension otto-ide-extension.vsix`
- **Antigravity / Kiro**: Install from VSIX in the Extensions menu.
