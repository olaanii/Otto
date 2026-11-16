import * as vscode from 'vscode';
import { AtomicCommitUnit } from './types';

export class OttoStatusBar {
  private item: vscode.StatusBarItem;

  constructor() {
    this.item = vscode.window.createStatusBarItem(
      vscode.StatusBarAlignment.Left,
      100 // High priority
    );
    this.item.command = 'otto.openHUD';
    this.item.text = '$(git-commit) Otto: Initializing...';
    this.item.tooltip = 'Otto: Click to open Atomic Git Slicer HUD (Ctrl+Shift+K / Cmd+Shift+K)';
    this.item.show();
  }

  public update(
    stagedUnits: AtomicCommitUnit[],
    uncommittedLoc: number,
    daemonActive: boolean,
    isHealthy: boolean = true,
    userEmail?: string
  ): void {
    if (!isHealthy) {
      this.item.text = '$(warning) Otto: Daemon Offline';
      this.item.tooltip = new vscode.MarkdownString(
        `**Otto Atomic Slicer**\n\n` +
        `⚠️ Cannot connect to Otto Go daemon.\n` +
        `Ensure \`go run cmd/daemon/main.go\` or the Otto server is running on \`http://localhost:3000\`.\n\n` +
        `[Open HUD](command:otto.openHUD)`
      );
      this.item.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
      return;
    }

    this.item.backgroundColor = undefined;

    const sliceCount = stagedUnits.length;
    const daemonIcon = daemonActive ? '⚡' : '⏸';

    if (sliceCount === 0 && uncommittedLoc === 0) {
      this.item.text = `$(check) Otto: Clean ${daemonIcon}`;
      const md = new vscode.MarkdownString();
      md.isTrusted = true;
      md.appendMarkdown(`**Otto: Working Tree Clean**\n\n`);
      md.appendMarkdown(`- Auto-Pilot Daemon: **${daemonActive ? 'Active (Auto-slicing on save)' : 'Paused'}**\n`);
      if (userEmail) {
        md.appendMarkdown(`- Clerk Account: \`${userEmail}\`\n`);
      }
      md.appendMarkdown(`- Shortcut: \`Ctrl+Shift+K\` (Mac: \`Cmd+Shift+K\`)\n\n`);
      md.appendMarkdown(`[Open HUD](command:otto.openHUD) | [Sync Stack](command:otto.syncNow)`);
      this.item.tooltip = md;
      return;
    }

    const locLabel = `${uncommittedLoc} LOC`;
    const sliceLabel = sliceCount === 1 ? '1 Slice' : `${sliceCount} Slices`;
    this.item.text = `$(git-commit) Otto: ${sliceLabel} (${locLabel})`;

    const md = new vscode.MarkdownString();
    md.isTrusted = true;
    md.appendMarkdown(`### 🐙 Otto Atomic Git Slicer\n\n`);
    md.appendMarkdown(`**${sliceCount} atomic commit candidate${sliceCount === 1 ? '' : 's'}** staged (${uncommittedLoc} total LOC).\n\n`);

    if (stagedUnits.length > 0) {
      md.appendMarkdown(`| Type | Subject | LOC |\n|---|---|---|\n`);
      for (const unit of stagedUnits.slice(0, 4)) {
        md.appendMarkdown(`| \`${unit.type}\` | ${unit.title.slice(0, 36)}... | \`${unit.totalLoc}\` |\n`);
      }
      if (stagedUnits.length > 4) {
        md.appendMarkdown(`\n*+${stagedUnits.length - 4} more atomic slices in queue*\n`);
      }
    }

    md.appendMarkdown(`\n---\n`);
    md.appendMarkdown(`- Auto-Pilot Daemon: **${daemonActive ? 'Active' : 'Paused'}**\n`);
    md.appendMarkdown(`- Press **\`Ctrl+Shift+K\`** / **\`Cmd+Shift+K\`** to inspect diffs and push.\n\n`);
    md.appendMarkdown(`[⚡ Commit & Push Stack](command:otto.sliceAndCommit) | [Open HUD](command:otto.openHUD)`);

    this.item.tooltip = md;
  }

  public showSyncing(label: string = 'Pushing atomic stack...'): void {
    this.item.text = `$(sync~spin) Otto: ${label}`;
  }

  public dispose(): void {
    this.item.dispose();
  }
}
