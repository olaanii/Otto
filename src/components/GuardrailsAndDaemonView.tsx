import React, { useState } from 'react';
import {
  GitHubConnectionConfig,
  GuardrailPolicy,
} from '../types/git';
import {
  generateIdeExtensionBundle,
  generateLocalDaemonScript,
} from '../utils/atomicEngine';
import { Check, Copy, Download, ShieldCheck, Terminal } from 'lucide-react';

interface GuardrailsAndDaemonViewProps {
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  onUpdatePolicy: (updated: GuardrailPolicy) => void;
  onUpdateGitHubConfig: (updated: GitHubConnectionConfig) => void;
}

export const GuardrailsAndDaemonView: React.FC<GuardrailsAndDaemonViewProps> = ({
  policy,
  githubConfig,
  onUpdatePolicy,
  onUpdateGitHubConfig,
}) => {
  const [installTab, setInstallTab] = useState<'ide_ext' | 'mcp_cli' | 'node_daemon'>('ide_ext');
  const [copiedCode, setCopiedCode] = useState(false);
  const [repoOwner, setRepoOwner] = useState(githubConfig.owner);
  const [repoName, setRepoName] = useState(githubConfig.repo);
  const [defaultBranch, setDefaultBranch] = useState(githubConfig.defaultBranch);
  const [savedRepoToast, setSavedRepoToast] = useState(false);

  const daemonScript = generateLocalDaemonScript(policy, githubConfig);
  const extensionBundle = generateIdeExtensionBundle(policy, githubConfig);

  const activeCodeContent =
    installTab === 'ide_ext'
      ? `${extensionBundle.extensionJs}\n\n// --- package.json (VS Code / Antigravity / Cursor / Windsurf Extension Manifest) ---\n${extensionBundle.extensionManifestJson}`
      : installTab === 'mcp_cli'
      ? `// Add to ~/.claude/claude_desktop_config.json, .cursor/mcp.json, or Codex CLI config:\n${extensionBundle.mcpConfigJson}`
      : daemonScript;

  const handleCopyActiveCode = async () => {
    try {
      await navigator.clipboard.writeText(activeCodeContent);
      setCopiedCode(true);
      setTimeout(() => setCopiedCode(false), 2500);
    } catch {
      setCopiedCode(true);
      setTimeout(() => setCopiedCode(false), 2500);
    }
  };

  const handleDownloadActiveFile = () => {
    const filename =
      installTab === 'ide_ext'
        ? 'atomikgit-extension.js'
        : installTab === 'mcp_cli'
        ? 'atomikgit-mcp.json'
        : 'atomik-agent.mjs';
    const blob = new Blob([activeCodeContent], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const handleSaveRepoSettings = (e: React.FormEvent) => {
    e.preventDefault();
    if (!repoOwner.trim() || !repoName.trim()) return;
    onUpdateGitHubConfig({
      ...githubConfig,
      owner: repoOwner.trim(),
      repo: repoName.trim(),
      defaultBranch: defaultBranch.trim() || 'main',
      lastSyncedAt: new Date().toISOString(),
    });
    setSavedRepoToast(true);
    setTimeout(() => setSavedRepoToast(false), 2500);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
      {/* Left 5 Cols: Senior Engineering Commit & PR Guardrails */}
      <section
        aria-label="Senior Engineering Guardrail Policy"
        className="lg:col-span-5 border border-zinc-200/90 bg-white rounded-2xl p-6 space-y-6 shadow-2xs"
      >
        <div className="border-b border-zinc-200/80 pb-4">
          <h2 className="text-base font-bold text-zinc-900 flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-zinc-800" />
            <span>Senior Engineering Atomic Commit Guardrails</span>
          </h2>
          <p className="text-xs text-zinc-500 mt-0.5">
            Changes to these thresholds immediately re-slice your uncommitted IDE changes and update the extension bundle
          </p>
        </div>

        <div className="space-y-5">
          <div>
            <div className="flex items-center justify-between text-xs mb-1.5">
              <label htmlFor="max-loc-input" className="font-medium text-zinc-800">
                Max Lines of Code (LOC) per Atomic Commit
              </label>
              <span className="font-mono tabular-nums text-zinc-900 font-bold bg-amber-200/80 px-1.5 py-0.5 rounded">
                {policy.maxLocPerCommit} LOC
              </span>
            </div>
            <input
              id="max-loc-input"
              type="range"
              min={50}
              max={250}
              step={10}
              value={policy.maxLocPerCommit}
              onChange={(e) =>
                onUpdatePolicy({
                  ...policy,
                  maxLocPerCommit: Number(e.target.value),
                })
              }
              className="w-full accent-zinc-900 cursor-pointer"
            />
            <div className="flex justify-between text-xs text-zinc-500 font-mono tabular-nums mt-1">
              <span>50 LOC (Granular)</span>
              <span>120 LOC (Senior Standard)</span>
              <span>250 LOC (Max Cap)</span>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label
                htmlFor="max-files-input"
                className="block text-xs font-medium text-zinc-800 mb-1.5"
              >
                Max Files per Atomic Commit
              </label>
              <input
                id="max-files-input"
                type="number"
                min={1}
                max={10}
                value={policy.maxFilesPerCommit}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    maxFilesPerCommit: Math.max(1, Number(e.target.value) || 1),
                  })
                }
                className="w-full bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-2 text-sm font-mono tabular-nums text-zinc-900 focus:outline-none focus:border-zinc-900"
              />
            </div>

            <div>
              <label
                htmlFor="cadence-minutes-input"
                className="block text-xs font-medium text-zinc-800 mb-1.5"
              >
                Auto-Commit Cadence (Minutes)
              </label>
              <input
                id="cadence-minutes-input"
                type="number"
                min={2}
                max={120}
                value={policy.autoCommitCadenceMinutes}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    autoCommitCadenceMinutes: Math.max(2, Number(e.target.value) || 15),
                  })
                }
                className="w-full bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-2 text-sm font-mono tabular-nums text-zinc-900 focus:outline-none focus:border-zinc-900"
              />
            </div>
          </div>

          <div className="space-y-3 pt-2 border-t border-zinc-200/80">
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={policy.isolateBrainstormingDocs}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    isolateBrainstormingDocs: e.target.checked,
                  })
                }
                className="mt-1 rounded border-zinc-300 text-zinc-900"
              />
              <div>
                <div className="text-xs font-semibold text-zinc-900">
                  Isolate IDE Brainstorming, Plans &amp; Roadmap Docs into Separate Branch
                </div>
                <p className="text-xs text-zinc-500">
                  Routes <code>docs/</code>, <code>plans/</code>, and markdown scratchpads to <code>{policy.branchPrefix}docs-plans</code> so they never clutter code review PRs.
                </p>
              </div>
            </label>

            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={policy.enforceConventionalCommits}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    enforceConventionalCommits: e.target.checked,
                  })
                }
                className="mt-1 rounded border-zinc-300 text-zinc-900"
              />
              <div>
                <div className="text-xs font-semibold text-zinc-900">
                  Enforce Conventional Commits 1.0 (type(scope): imperative subject)
                </div>
                <p className="text-xs text-zinc-500">
                  Automatically formats headers as <code>feat(scope)</code>, <code>fix(scope)</code>, <code>refactor(scope)</code>, or <code>test(scope)</code>.
                </p>
              </div>
            </label>

            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={policy.autoPushToGitHub}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    autoPushToGitHub: e.target.checked,
                  })
                }
                className="mt-1 rounded border-zinc-300 text-zinc-900"
              />
              <div>
                <div className="text-xs font-semibold text-zinc-900">
                  Progressive GitHub Push &amp; Stacked PR Creation on Every Settled Boundary
                </div>
                <p className="text-xs text-zinc-500">
                  Ensures your daily GitHub contribution graph reflects your real engineering work while Antigravity or other agents code.
                </p>
              </div>
            </label>
          </div>
        </div>

        {/* Target GitHub Repo Form */}
        <form
          onSubmit={handleSaveRepoSettings}
          className="pt-5 border-t border-zinc-200/80 space-y-4"
        >
          <h3 className="text-sm font-bold text-zinc-900">
            GitHub Repository Target
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label
                htmlFor="github-owner-input"
                className="block text-xs text-zinc-500 mb-1"
              >
                GitHub Owner / Org
              </label>
              <input
                id="github-owner-input"
                type="text"
                value={repoOwner}
                onChange={(e) => setRepoOwner(e.target.value)}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-1.5 text-xs font-mono text-zinc-900"
              />
            </div>
            <div>
              <label
                htmlFor="github-repo-input"
                className="block text-xs text-zinc-500 mb-1"
              >
                Repository Name
              </label>
              <input
                id="github-repo-input"
                type="text"
                value={repoName}
                onChange={(e) => setRepoName(e.target.value)}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-1.5 text-xs font-mono text-zinc-900"
              />
            </div>
            <div>
              <label
                htmlFor="github-branch-input"
                className="block text-xs text-zinc-500 mb-1"
              >
                Base Branch
              </label>
              <input
                id="github-branch-input"
                type="text"
                value={defaultBranch}
                onChange={(e) => setDefaultBranch(e.target.value)}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-1.5 text-xs font-mono text-zinc-900"
              />
            </div>
          </div>
          <div className="flex items-center justify-between gap-3">
            <button
              type="submit"
              className="px-4 py-2 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              Update Target Repository
            </button>
            {savedRepoToast && (
              <span className="text-xs text-emerald-700 font-medium">
                Repository target updated to {repoOwner}/{repoName}
              </span>
            )}
          </div>
        </form>
      </section>

      {/* Right 7 Cols: Universal IDE Extension, MCP Server & CLI Watcher Installer */}
      <section
        aria-label="Universal IDE Extension and CLI Installer"
        className="lg:col-span-7 border border-zinc-200/90 bg-white rounded-2xl p-6 space-y-5 shadow-2xs"
      >
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-zinc-200/80 pb-4">
          <div>
            <h2 className="text-base font-bold text-zinc-900 flex items-center gap-2">
              <Terminal className="w-4 h-4 text-zinc-800" />
              <span>Install in Any IDE, CLI, or Coding Agent</span>
            </h2>
            <p className="text-xs text-zinc-500 mt-0.5">
              Auto-starts when you open a project in Antigravity, Cursor, VS Code, Windsurf, Claude Code, or Codex
            </p>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={handleCopyActiveCode}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-zinc-800 bg-zinc-100 hover:bg-zinc-200 border border-zinc-200 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              {copiedCode ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-700" />
                  <span>Copied</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>Copy Code</span>
                </>
              )}
            </button>
            <button
              type="button"
              onClick={handleDownloadActiveFile}
              className="inline-flex items-center gap-1.5 px-4 py-1.5 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download Bundle</span>
            </button>
          </div>
        </div>

        {/* Mode Selector Tabs */}
        <div
          role="group"
          aria-label="Select IDE Extension, MCP Config, or Standalone Daemon"
          className="flex flex-wrap items-center gap-1.5 p-1 bg-zinc-100 rounded-xl"
        >
          <button
            type="button"
            onClick={() => setInstallTab('ide_ext')}
            className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors cursor-pointer ${
              installTab === 'ide_ext'
                ? 'bg-white text-zinc-900 shadow-2xs'
                : 'text-zinc-600 hover:text-zinc-900'
            }`}
          >
            1. IDE Extension Overlay (Antigravity · Cursor · VS Code · Windsurf)
          </button>
          <button
            type="button"
            onClick={() => setInstallTab('mcp_cli')}
            className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors cursor-pointer ${
              installTab === 'mcp_cli'
                ? 'bg-white text-zinc-900 shadow-2xs'
                : 'text-zinc-600 hover:text-zinc-900'
            }`}
          >
            2. MCP Server Hook (Claude Code · Codex · Aider)
          </button>
          <button
            type="button"
            onClick={() => setInstallTab('node_daemon')}
            className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors cursor-pointer ${
              installTab === 'node_daemon'
                ? 'bg-white text-zinc-900 shadow-2xs'
                : 'text-zinc-600 hover:text-zinc-900'
            }`}
          >
            3. Background Watcher (atomik-agent.mjs)
          </button>
        </div>

        <pre className="p-4 rounded-xl bg-zinc-900 text-xs font-mono text-zinc-100 overflow-x-auto max-h-[420px] leading-relaxed">
          {activeCodeContent}
        </pre>
      </section>
    </div>
  );
};
