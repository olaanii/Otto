import * as vscode from 'vscode';
import { OttoDaemonClient } from './daemonClient';
import { OttoStatusBar } from './statusBar';
import { OttoHudPanel } from './hudPanel';
import { DaemonEvent, WorkspaceState } from './types';

let daemonClient: OttoDaemonClient;
let statusBar: OttoStatusBar;
let sseUnsubscribe: (() => void) | null = null;
let pollTimer: NodeJS.Timeout | null = null;

export function activate(context: vscode.ExtensionContext) {
  daemonClient = new OttoDaemonClient();
  statusBar = new OttoStatusBar();

  // Register command: Open HUD
  const openHudCmd = vscode.commands.registerCommand('otto.openHUD', () => {
    OttoHudPanel.createOrShow(context.extensionUri, daemonClient);
  });

  // Register command: Slice & Commit
  const sliceAndCommitCmd = vscode.commands.registerCommand('otto.sliceAndCommit', async () => {
    try {
      statusBar.showSyncing('Slicing & committing...');
      const res = await daemonClient.pushStack({ pushAll: true });
      vscode.window.showInformationMessage(
        `Otto: Pushed ${res.pushedCount} atomic commit(s) (PR #${res.latestPrNumber}) to GitHub!`
      );
      await refreshState();
    } catch (err: any) {
      vscode.window.showErrorMessage(`Otto slice & commit failed: ${err.message}`);
      await refreshState();
    }
  });

  // Register command: Sync Now
  const syncNowCmd = vscode.commands.registerCommand('otto.syncNow', async () => {
    try {
      statusBar.showSyncing('Syncing GitHub stack...');
      await daemonClient.syncNow();
      vscode.window.showInformationMessage('Otto: Stacked PRs successfully synced with GitHub.');
      await refreshState();
    } catch (err: any) {
      vscode.window.showErrorMessage(`Otto sync failed: ${err.message}`);
      await refreshState();
    }
  });

  // Register command: Toggle Daemon
  const toggleDaemonCmd = vscode.commands.registerCommand('otto.toggleDaemon', async () => {
    try {
      const res = await daemonClient.toggleDaemon();
      const statusText = res.daemonActive ? 'ACTIVE (zero-click auto-slicing)' : 'PAUSED';
      vscode.window.showInformationMessage(`Otto Auto-Pilot Daemon is now ${statusText}.`);
      await refreshState();
    } catch (err: any) {
      vscode.window.showErrorMessage(`Otto toggle daemon failed: ${err.message}`);
    }
  });

  context.subscriptions.push(
    openHudCmd,
    sliceAndCommitCmd,
    syncNowCmd,
    toggleDaemonCmd,
    statusBar
  );

  // Auto-Pilot on file save
  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument(async (document) => {
      const config = vscode.workspace.getConfiguration('otto');
      const isAutoPilot = config.get<boolean>('autoPilot', true);
      if (!isAutoPilot) return;

      // Avoid triggering on git internals or output files
      const fsPath = document.uri.fsPath;
      if (fsPath.includes('.git') || fsPath.includes('node_modules') || fsPath.includes('.data')) {
        return;
      }

      try {
        await daemonClient.analyzeDiff({
          filePath: vscode.workspace.asRelativePath(document.uri),
        });
        await refreshState();
      } catch {
        // Silently continue if daemon is busy
      }
    })
  );

  // Configuration changes listener
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('otto')) {
        daemonClient.refreshConfig();
        refreshState();
      }
    })
  );

  // Setup SSE stream subscription
  setupEventSubscription();

  // Initial fetch and regular poll interval (every 10 seconds fallback)
  refreshState();
  pollTimer = setInterval(refreshState, 10000);
}

async function refreshState() {
  try {
    const isHealthy = await daemonClient.isHealthy();
    if (!isHealthy) {
      statusBar.update([], 0, false, false);
      return;
    }

    const state: WorkspaceState = await daemonClient.getState();
    const uncommittedLoc = (state.workingTreeHunks || []).reduce(
      (sum, h) => sum + (h.additions || 0) + (h.deletions || 0),
      0
    );

    const config = vscode.workspace.getConfiguration('otto');
    const clerkToken = config.get<string>('clerkToken', '');
    const userEmail = clerkToken ? 'authenticated-user@clerk' : undefined;

    statusBar.update(
      state.stagedAtomicStack || [],
      uncommittedLoc,
      state.daemonActive ?? true,
      true,
      userEmail
    );

    if (OttoHudPanel.currentPanel) {
      OttoHudPanel.currentPanel.refresh();
    }
  } catch {
    statusBar.update([], 0, false, false);
  }
}

function setupEventSubscription() {
  if (sseUnsubscribe) {
    sseUnsubscribe();
    sseUnsubscribe = null;
  }

  try {
    sseUnsubscribe = daemonClient.subscribeEvents(
      (event: DaemonEvent) => {
        if (event.type === 'state_updated' || event.type === 'slice_staged' || event.type === 'stack_pushed') {
          refreshState();
        }
      },
      () => {
        // Fallback polling will handle intermittent disconnections
      }
    );
  } catch {
    // Fallback polling handles offline mode
  }
}

export function deactivate() {
  if (sseUnsubscribe) {
    sseUnsubscribe();
    sseUnsubscribe = null;
  }
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
  if (statusBar) {
    statusBar.dispose();
  }
}
