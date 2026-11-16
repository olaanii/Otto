import * as vscode from 'vscode';
import { AtomicCommitUnit, DiffHunk, WorkspaceState } from './types';
import { OttoDaemonClient } from './daemonClient';

export class OttoHudPanel {
  public static currentPanel: OttoHudPanel | undefined;
  private readonly panel: vscode.WebviewPanel;
  private readonly extensionUri: vscode.Uri;
  private readonly daemonClient: OttoDaemonClient;
  private disposables: vscode.Disposable[] = [];

  public static createOrShow(extensionUri: vscode.Uri, daemonClient: OttoDaemonClient): OttoHudPanel {
    const column = vscode.window.activeTextEditor
      ? vscode.window.activeTextEditor.viewColumn
      : undefined;

    if (OttoHudPanel.currentPanel) {
      OttoHudPanel.currentPanel.panel.reveal(column || vscode.ViewColumn.Beside);
      OttoHudPanel.currentPanel.refresh();
      return OttoHudPanel.currentPanel;
    }

    const panel = vscode.window.createWebviewPanel(
      'ottoHud',
      'Otto Atomic Slicer HUD',
      column || vscode.ViewColumn.Beside,
      {
        enableScripts: true,
        retainContextWhenHidden: true,
        localResourceRoots: [extensionUri],
      }
    );

    OttoHudPanel.currentPanel = new OttoHudPanel(panel, extensionUri, daemonClient);
    return OttoHudPanel.currentPanel;
  }

  private constructor(
    panel: vscode.WebviewPanel,
    extensionUri: vscode.Uri,
    daemonClient: OttoDaemonClient
  ) {
    this.panel = panel;
    this.extensionUri = extensionUri;
    this.daemonClient = daemonClient;

    this.updateWebviewContent();

    this.panel.onDidDispose(() => this.dispose(), null, this.disposables);

    this.panel.webview.onDidReceiveMessage(
      async (message) => {
        switch (message.command) {
          case 'refresh':
            await this.refresh();
            break;

          case 'commitAndPush':
            await this.handleCommitAndPush(message.commitId);
            break;

          case 'refineAi':
            await this.handleRefineAi();
            break;

          case 'syncNow':
            await this.handleSyncNow();
            break;

          case 'toggleDaemon':
            await this.handleToggleDaemon();
            break;

          case 'openSettings':
            vscode.commands.executeCommand('workbench.action.openSettings', 'otto');
            break;

          case 'copyToken':
            if (message.token) {
              await vscode.env.clipboard.writeText(message.token);
              vscode.window.showInformationMessage('Otto: Clerk token copied to clipboard.');
            }
            break;
        }
      },
      null,
      this.disposables
    );

    // Initial data load
    this.refresh();
  }

  public async refresh(): Promise<void> {
    try {
      const state = await this.daemonClient.getState();
      const config = vscode.workspace.getConfiguration('otto');
      const clerkToken = config.get<string>('clerkToken', '');
      const daemonUrl = config.get<string>('daemonUrl', 'http://localhost:3000');

      this.panel.webview.postMessage({
        command: 'setState',
        state,
        daemonUrl,
        clerkToken,
        isHealthy: true,
      });
    } catch (err: any) {
      this.panel.webview.postMessage({
        command: 'setError',
        message: err.message || 'Cannot reach Otto Go daemon',
        isHealthy: false,
      });
    }
  }

  private async handleCommitAndPush(commitId?: string): Promise<void> {
    try {
      vscode.window.showInformationMessage('Otto: Committing & pushing atomic stack to GitHub...');
      const res = await this.daemonClient.pushStack({
        commitIds: commitId ? [commitId] : undefined,
        pushAll: !commitId,
      });
      vscode.window.showInformationMessage(
        `Otto: Successfully pushed ${res.pushedCount} atomic PR${res.pushedCount === 1 ? '' : 's'} (PR #${res.latestPrNumber})!`
      );
      await this.refresh();
      vscode.commands.executeCommand('otto.syncNow');
    } catch (err: any) {
      vscode.window.showErrorMessage(`Otto push failed: ${err.message}`);
    }
  }

  private async handleRefineAi(): Promise<void> {
    try {
      vscode.window.showInformationMessage('Otto: Refining Conventional Commit headers with Gemini...');
      const state = await this.daemonClient.getState();
      await this.daemonClient.refineStack(state.workingTreeHunks, state.policy);
      vscode.window.showInformationMessage('Otto: Commit headers refined to Conventional Commits standards.');
      await this.refresh();
    } catch (err: any) {
      vscode.window.showErrorMessage(`Otto AI refinement failed: ${err.message}`);
    }
  }

  private async handleSyncNow(): Promise<void> {
    try {
      await this.daemonClient.syncNow();
      vscode.window.showInformationMessage('Otto: GitHub stack synchronization complete.');
      await this.refresh();
    } catch (err: any) {
      vscode.window.showErrorMessage(`Otto sync failed: ${err.message}`);
    }
  }

  private async handleToggleDaemon(): Promise<void> {
    try {
      const res = await this.daemonClient.toggleDaemon();
      vscode.window.showInformationMessage(
        `Otto Auto-Pilot Daemon is now ${res.daemonActive ? 'ACTIVE (zero-click slicing)' : 'PAUSED'}.`
      );
      await this.refresh();
    } catch (err: any) {
      vscode.window.showErrorMessage(`Otto toggle failed: ${err.message}`);
    }
  }

  public dispose(): void {
    OttoHudPanel.currentPanel = undefined;
    this.panel.dispose();
    while (this.disposables.length) {
      const x = this.disposables.pop();
      if (x) {
        x.dispose();
      }
    }
  }

  private updateWebviewContent(): void {
    this.panel.webview.html = this.getHtmlForWebview();
  }

  private getHtmlForWebview(): string {
    return /* html */ `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Otto Atomic Slicer HUD</title>
  <style>
    :root {
      --bg: var(--vscode-editor-background, #121214);
      --card-bg: var(--vscode-sideBar-background, #18181b);
      --card-border: var(--vscode-widget-border, rgba(255, 255, 255, 0.08));
      --text: var(--vscode-editor-foreground, #f4f4f5);
      --text-muted: var(--vscode-descriptionForeground, #a1a1aa);
      --accent: #6366f1;
      --accent-hover: #4f46e5;
      --success: #10b981;
      --warning: #f59e0b;
      --danger: #ef4444;
      --font-mono: var(--vscode-editor-font-family, ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace);
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      padding: 16px;
      font-size: 13px;
      line-height: 1.5;
    }

    /* Top Glassmorphic Navigation */
    .hud-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding-bottom: 14px;
      border-bottom: 1px solid var(--card-border);
      margin-bottom: 16px;
    }

    .brand-section {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .logo-badge {
      width: 28px;
      height: 28px;
      background: linear-gradient(135deg, #6366f1, #a855f7);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 700;
      font-size: 15px;
      box-shadow: 0 2px 8px rgba(99, 102, 241, 0.3);
    }

    .brand-title {
      font-size: 15px;
      font-weight: 600;
      letter-spacing: -0.02em;
    }

    .brand-subtitle {
      font-size: 11px;
      color: var(--text-muted);
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .badge-pill {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 3px 8px;
      border-radius: 9999px;
      font-size: 11px;
      font-weight: 500;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid var(--card-border);
    }

    .badge-pill.active {
      color: var(--success);
      border-color: rgba(16, 185, 129, 0.3);
      background: rgba(16, 185, 129, 0.08);
    }

    .badge-pill.paused {
      color: var(--warning);
      border-color: rgba(245, 158, 11, 0.3);
      background: rgba(245, 158, 11, 0.08);
    }

    /* Buttons */
    button {
      cursor: pointer;
      border: none;
      border-radius: 6px;
      padding: 6px 12px;
      font-size: 12px;
      font-weight: 500;
      transition: all 0.15s ease;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }

    .btn-primary {
      background: var(--accent);
      color: white;
    }

    .btn-primary:hover {
      background: var(--accent-hover);
      box-shadow: 0 2px 8px rgba(99, 102, 241, 0.3);
    }

    .btn-secondary {
      background: rgba(255, 255, 255, 0.08);
      color: var(--text);
      border: 1px solid var(--card-border);
    }

    .btn-secondary:hover {
      background: rgba(255, 255, 255, 0.14);
    }

    .btn-sm {
      padding: 3px 8px;
      font-size: 11px;
    }

    /* Section Cards */
    .section-card {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 10px;
      padding: 14px;
      margin-bottom: 14px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .section-title-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 10px;
    }

    .section-title {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: var(--text-muted);
      font-weight: 600;
    }

    /* Candidate Commit Header Block */
    .commit-header-block {
      background: rgba(0, 0, 0, 0.2);
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 10px 12px;
      margin-bottom: 12px;
    }

    .commit-type-badge {
      display: inline-block;
      font-family: var(--font-mono);
      font-size: 11px;
      font-weight: 600;
      padding: 2px 6px;
      border-radius: 4px;
      margin-right: 6px;
    }

    .type-feat { background: #3b82f6; color: white; }
    .type-fix { background: #ef4444; color: white; }
    .type-refactor { background: #8b5cf6; color: white; }
    .type-test { background: #10b981; color: white; }
    .type-docs { background: #f59e0b; color: white; }
    .type-chore { background: #6b7280; color: white; }

    .commit-input {
      width: 100%;
      background: transparent;
      border: none;
      color: var(--text);
      font-size: 13px;
      font-weight: 600;
      margin-top: 6px;
      padding: 4px 0;
      font-family: inherit;
    }

    .commit-input:focus {
      outline: none;
      border-bottom: 1px solid var(--accent);
    }

    .compliance-meter {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-top: 8px;
      padding-top: 8px;
      border-top: 1px solid var(--card-border);
      font-size: 11px;
      color: var(--text-muted);
    }

    .score-badge {
      color: var(--success);
      font-weight: 600;
    }

    /* Diff Hunks List */
    .hunk-item {
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid var(--card-border);
      border-radius: 6px;
      padding: 8px 10px;
      margin-bottom: 8px;
      transition: background 0.15s ease;
    }

    .hunk-item:hover {
      background: rgba(255, 255, 255, 0.05);
    }

    .hunk-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 6px;
    }

    .hunk-file {
      font-family: var(--font-mono);
      font-size: 11px;
      font-weight: 500;
      color: var(--accent);
    }

    .hunk-stats {
      font-size: 11px;
      font-family: var(--font-mono);
    }

    .stat-add { color: var(--success); }
    .stat-del { color: var(--danger); }

    .hunk-snippet {
      background: rgba(0, 0, 0, 0.35);
      border-radius: 4px;
      padding: 6px 8px;
      font-family: var(--font-mono);
      font-size: 11px;
      overflow-x: auto;
      white-space: pre;
      color: #e4e4e7;
    }

    /* Stack Queue */
    .stack-queue-list {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }

    .stack-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 6px 8px;
      border-radius: 6px;
      background: rgba(255, 255, 255, 0.02);
      font-size: 12px;
    }

    /* Clerk Auth Info */
    .clerk-info {
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 11px;
      color: var(--text-muted);
      padding: 8px;
      border-radius: 6px;
      background: rgba(99, 102, 241, 0.05);
      border: 1px solid rgba(99, 102, 241, 0.15);
      margin-top: 12px;
    }

    .empty-state {
      text-align: center;
      padding: 24px 12px;
      color: var(--text-muted);
    }
  </style>
</head>
<body>
  <div class="hud-header">
    <div class="brand-section">
      <div class="logo-badge">🐙</div>
      <div>
        <div class="brand-title">Otto Atomic Slicer HUD</div>
        <div class="brand-subtitle">Cursor · VS Code · Windsurf · Antigravity · Kiro</div>
      </div>
    </div>
    <div class="header-actions">
      <div id="daemonBadge" class="badge-pill active">⚡ Auto-Pilot Active</div>
      <button class="btn-secondary btn-sm" onclick="sendMessage('refresh')">↻ Refresh</button>
      <button class="btn-secondary btn-sm" onclick="sendMessage('toggleDaemon')">Toggle Daemon</button>
    </div>
  </div>

  <div id="mainContainer">
    <!-- Active Atomic Slice Candidate -->
    <div class="section-card">
      <div class="section-title-row">
        <span class="section-title">Current Atomic Commit Candidate</span>
        <div style="display: flex; gap: 6px;">
          <button class="btn-secondary btn-sm" onclick="sendMessage('refineAi')">✨ Refine with Gemini</button>
        </div>
      </div>

      <div class="commit-header-block">
        <div>
          <span id="commitTypeBadge" class="commit-type-badge type-feat">feat</span>
          <span id="commitScope" style="font-family: var(--font-mono); font-size: 11px; color: var(--text-muted);">auth</span>
        </div>
        <input id="commitTitleInput" class="commit-input" value="feat(auth): add PKCE challenge verifier exchange" />
        <div class="compliance-meter">
          <span>LOC Threshold: <strong id="locCount">52 LOC</strong> (Max: 80 LOC)</span>
          <span class="score-badge">🛡️ Senior Guardrails: 100% Compliant</span>
        </div>
      </div>

      <!-- Action Buttons -->
      <div style="display: flex; gap: 8px; margin-bottom: 12px;">
        <button class="btn-primary" style="flex: 1; justify-content: center; padding: 8px;" onclick="sendMessage('commitAndPush')">
          ⚡ Commit & Push Stack to GitHub
        </button>
        <button class="btn-secondary" onclick="sendMessage('syncNow')">
          Sync Remote Stack
        </button>
      </div>

      <!-- Diff Hunks Accordion -->
      <div class="section-title" style="margin-bottom: 8px;">Included Diff Hunks (<span id="hunkCount">1</span>)</div>
      <div id="hunksContainer">
        <!-- Rendered dynamically -->
      </div>
    </div>

    <!-- Pushed / Stacked PRs -->
    <div class="section-card">
      <div class="section-title-row">
        <span class="section-title">Stacked PRs on GitHub</span>
        <span id="pushedPrCount" class="badge-pill">3 Open PRs</span>
      </div>
      <div id="pushedStackContainer" class="stack-queue-list">
        <!-- Rendered dynamically -->
      </div>
    </div>

    <!-- Clerk Auth & Daemon Connection Telemetry -->
    <div class="clerk-info">
      <div>
        <span>🔒 <strong>Clerk Auth:</strong> Verified Session</span>
        <span id="clerkTokenPreview" style="margin-left: 6px; font-family: var(--font-mono); color: var(--accent);"></span>
      </div>
      <div style="display: flex; gap: 6px;">
        <button class="btn-secondary btn-sm" onclick="sendMessage('openSettings')">⚙️ Settings</button>
      </div>
    </div>
  </div>

  <script>
    const vscode = acquireVsCodeApi();

    function sendMessage(command, payload = {}) {
      vscode.postMessage({ command, ...payload });
    }

    window.addEventListener('message', event => {
      const msg = event.data;
      if (msg.command === 'setState') {
        renderState(msg.state, msg.daemonUrl, msg.clerkToken);
      } else if (msg.command === 'setError') {
        document.getElementById('daemonBadge').className = 'badge-pill paused';
        document.getElementById('daemonBadge').textContent = '⚠️ Daemon Offline';
      }
    });

    function renderState(state, daemonUrl, clerkToken) {
      if (!state) return;

      // Daemon status
      const daemonBadge = document.getElementById('daemonBadge');
      if (state.daemonActive) {
        daemonBadge.className = 'badge-pill active';
        daemonBadge.textContent = '⚡ Auto-Pilot Active';
      } else {
        daemonBadge.className = 'badge-pill paused';
        daemonBadge.textContent = '⏸ Auto-Pilot Paused';
      }

      // Candidate commit unit
      const candidate = (state.stagedAtomicStack && state.stagedAtomicStack[0]) || null;
      if (candidate) {
        document.getElementById('commitTypeBadge').textContent = candidate.type;
        document.getElementById('commitTypeBadge').className = 'commit-type-badge type-' + candidate.type;
        document.getElementById('commitScope').textContent = '(' + candidate.scope + ')';
        document.getElementById('commitTitleInput').value = candidate.conventionalHeader;
        document.getElementById('locCount').textContent = candidate.totalLoc + ' LOC';
        document.getElementById('hunkCount').textContent = (candidate.hunks || []).length;

        // Render hunks with interactive inclusion checkboxes
        const hunksHtml = (candidate.hunks || []).map((h, i) => \`
          <div class="hunk-item" id="hunk-row-\${i}">
            <div class="hunk-header">
              <label style="display: flex; align-items: center; gap: 8px; cursor: pointer;">
                <input type="checkbox" checked id="chk-hunk-\${i}" onchange="toggleHunkSelection(\${i}, \${h.additions + h.deletions})" />
                <span class="hunk-file">\${h.filePath}</span>
              </label>
              <span class="hunk-stats">
                <span class="stat-add">+\${h.additions}</span>
                <span class="stat-del">-\${h.deletions}</span>
              </span>
            </div>
            <div class="hunk-snippet">\${escapeHtml(h.diffSnippet || h.summary)}</div>
          </div>
        \`).join('');
        document.getElementById('hunksContainer').innerHTML = hunksHtml || '<div class="empty-state">No hunks in current slice</div>';
      } else {
        document.getElementById('commitTitleInput').value = 'No uncommitted changes in worktree';
        document.getElementById('locCount').textContent = '0 LOC';
        document.getElementById('hunkCount').textContent = '0';
        document.getElementById('hunksContainer').innerHTML = '<div class="empty-state">Working tree clean. Changes from your coding agent will appear here automatically.</div>';
      }

      // Pushed Stack
      const pushed = state.pushedStack || [];
      document.getElementById('pushedPrCount').textContent = pushed.length + ' PRs';
      const pushedHtml = pushed.slice(0, 5).map(pr => \`
        <div class="stack-row">
          <div>
            <strong style="color: var(--accent);">PR #\${pr.prNumber || 142}</strong>
            <span style="margin-left: 6px;">\${escapeHtml(pr.title)}</span>
          </div>
          <span style="font-family: var(--font-mono); font-size: 11px; color: var(--text-muted);">
            +\${pr.totalAdditions}/-\${pr.totalDeletions} LOC
          </span>
        </div>
      \`).join('');
      document.getElementById('pushedStackContainer').innerHTML = pushedHtml || '<div class="empty-state">No pushed PRs yet</div>';

      // Clerk preview
      const preview = clerkToken ? 'Token: ' + clerkToken.slice(0, 8) + '...' : 'Default Sandbox Profile';
      document.getElementById('clerkTokenPreview').textContent = preview;
    }

    function toggleHunkSelection(index, loc) {
      const chk = document.getElementById('chk-hunk-' + index);
      const row = document.getElementById('hunk-row-' + index);
      if (chk && row) {
        if (!chk.checked) {
          row.style.opacity = '0.4';
        } else {
          row.style.opacity = '1.0';
        }
      }
    }

    function escapeHtml(text) {
      if (!text) return '';
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }
  </script>
</body>
</html>`;
  }
}
