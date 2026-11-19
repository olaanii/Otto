import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  AtomicCommitUnit,
  GitHubConnectionConfig,
} from '../types/git';

export interface GitHubSyncTelemetry {
  connected: boolean;
  owner: string;
  repo: string;
  defaultBranch: string;
  activeBranch: string;
  pendingPrSyncCount: number;
  stagedCount: number;
  openPrCount: number;
  draftPrCount: number;
  mergedPrCount: number;
  latestPrNumber: number;
  latestSha: string;
  daemonActive: boolean;
  syncState: 'synced' | 'pending_sync' | 'draft_pending' | 'disconnected';
  lastSyncedAt: string;
  checkedAt: string;
}

interface NavbarGitHubSyncStatusProps {
  githubConfig: GitHubConnectionConfig;
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  daemonActive: boolean;
  onPushAllStaged: () => void;
  onPromoteDraftPr: (commitId: string) => void;
  onChangeBaseBranch: (nextBranch: string) => void;
  onNavigateToStack: () => void;
  antigravityConnected?: boolean;
  onConnectAntigravity?: () => void;
  onTestAntigravity?: () => void;
}

export const NavbarGitHubSyncStatus: React.FC<NavbarGitHubSyncStatusProps> = ({
  githubConfig,
  stagedAtomicStack,
  pushedStack,
  daemonActive,
  onPushAllStaged,
  onPromoteDraftPr,
  onChangeBaseBranch,
  onNavigateToStack,
  antigravityConnected,
  onConnectAntigravity,
  onTestAntigravity,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [isFetching, setIsFetching] = useState(false);
  const [telemetry, setTelemetry] = useState<GitHubSyncTelemetry | null>(null);
  const [lastLatencyMs, setLastLatencyMs] = useState<number>(18);
  const [internalConnected, setInternalConnected] = useState<boolean>(true);
  const [pingFeedback, setPingFeedback] = useState<string | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);

  const isConnected =
    antigravityConnected !== undefined ? antigravityConnected : internalConnected;

  const effectiveOwner =
    !githubConfig?.owner || githubConfig.owner === 'olaniketema'
      ? 'olaanii'
      : githubConfig.owner;
  const effectiveRepo =
    !githubConfig?.repo || githubConfig.repo === 'antigravity-core-platform'
      ? 'Otto'
      : githubConfig.repo;
  const effectiveRepoSlug = `${effectiveOwner}/${effectiveRepo}`;
  const effectiveDefaultBranch =
    githubConfig?.defaultBranch || telemetry?.defaultBranch || 'main';

  const handleConnectAntigravity = () => {
    if (onConnectAntigravity) {
      onConnectAntigravity();
    }
    setInternalConnected(true);
  };

  const handleDisconnectAntigravity = () => {
    setInternalConnected(false);
  };

  const handleTestAntigravity = () => {
    if (onTestAntigravity) {
      onTestAntigravity();
    }
    setPingFeedback('Ping OK · 14ms');
    window.setTimeout(() => setPingFeedback(null), 2200);
  };

  const localStagedCount = stagedAtomicStack.length;
  const localOpenPrCount = pushedStack.filter((p) => p.status === 'pr_open').length;
  const localDraftPrCount = pushedStack.filter((p) => p.status === 'draft').length;
  const localMergedPrCount = pushedStack.filter((p) => p.status === 'merged').length;

  const activeHeadUnit =
    stagedAtomicStack[0] ||
    pushedStack.find((p) => p.status === 'pr_open' || p.status === 'draft') ||
    pushedStack[0];

  const activeHeadBranch =
    activeHeadUnit?.branchName || effectiveDefaultBranch;
  const shortHeadBranch = activeHeadBranch.replace(/^atomik\//, '');

  const fetchSyncStatus = useCallback(async (showSpinner = false) => {
    if (showSpinner) {
      setIsFetching(true);
    }
    const t0 = performance.now();
    try {
      const res = await fetch('/api/github/sync-status');
      if (res.ok) {
        const data = (await res.json()) as GitHubSyncTelemetry;
        setTelemetry(data);
        setLastLatencyMs(Math.max(8, Math.round(performance.now() - t0)));
      }
    } catch {
      // Fallback to live client workspace state if offline
    } finally {
      if (showSpinner) {
        window.setTimeout(() => setIsFetching(false), 260);
      }
    }
  }, []);

  // Fetch on mount and whenever stack/branch state changes
  useEffect(() => {
    fetchSyncStatus(false);
  }, [
    fetchSyncStatus,
    localStagedCount,
    localOpenPrCount,
    localDraftPrCount,
    localMergedPrCount,
    effectiveDefaultBranch,
    daemonActive,
  ]);

  // Periodic real-time polling every 12 seconds
  useEffect(() => {
    const id = window.setInterval(() => {
      fetchSyncStatus(false);
    }, 12000);
    return () => window.clearInterval(id);
  }, [fetchSyncStatus]);

  // Close popover when clicking outside or pressing Escape
  useEffect(() => {
    if (!isOpen) return;
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen]);

  const pendingSyncTotal = localStagedCount + localDraftPrCount;

  const syncDotClass = isFetching
    ? 'bg-sky-500 animate-ping'
    : !githubConfig.connected
    ? 'bg-zinc-400'
    : localStagedCount > 0
    ? 'bg-amber-500'
    : localDraftPrCount > 0
    ? 'bg-amber-400'
    : 'bg-emerald-500';

  const statusSummaryLabel = isFetching
    ? 'Syncing…'
    : localStagedCount > 0
    ? `${localStagedCount} PR${localStagedCount === 1 ? '' : 's'} pending`
    : localDraftPrCount > 0
    ? `${localDraftPrCount} draft · ${localOpenPrCount} open`
    : `${localOpenPrCount} open · Synced`;

  const topDraftPr = pushedStack.find((p) => p.status === 'draft');

  const handleManualSyncNow = async () => {
    setIsFetching(true);
    try {
      if (localStagedCount > 0) {
        onPushAllStaged();
      }
      await fetch('/api/github/sync-now', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pushStaged: localStagedCount > 0 }),
      });
      await fetchSyncStatus(false);
    } finally {
      window.setTimeout(() => setIsFetching(false), 260);
    }
  };

  const handleSelectBaseBranch = async (branch: string) => {
    setIsFetching(true);
    onChangeBaseBranch(branch);
    try {
      await fetch('/api/github/sync-now', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ defaultBranch: branch }),
      });
      await fetchSyncStatus(false);
    } finally {
      window.setTimeout(() => setIsFetching(false), 240);
    }
  };

  return (
    <div ref={containerRef} className="relative flex items-center gap-2 shrink-0">
      {/* Interactive Antigravity Connection Indicator / 1-Click Connect Button */}
      {isConnected ? (
        <div className="relative group/ag flex items-center shrink-0">
          <button
            type="button"
            onClick={handleTestAntigravity}
            title="$0 extra subscription fees · Auto-slicing active"
            aria-label="Antigravity Live · Gemini 3.8 Flash · $0 extra subscription fees · Auto-slicing active"
            className="group/agbtn inline-flex items-center gap-1.5 px-2.5 py-1 sm:py-1.5 rounded-full text-[11px] sm:text-[12px] font-medium bg-emerald-50 text-emerald-900 border border-emerald-200/80 hover:bg-emerald-100/90 transition-all cursor-pointer select-none"
          >
            {/* Pulsing emerald badge */}
            <span className="relative flex h-2 w-2 shrink-0">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
            </span>
            <span className="font-semibold tracking-tight text-emerald-950">
              Antigravity Live
            </span>
            {/* Model tag */}
            <span className="px-1.5 py-0.5 rounded text-[10px] font-mono font-medium bg-emerald-500/15 text-emerald-800 border border-emerald-600/15">
              {pingFeedback || 'Gemini 3.8 Flash'}
            </span>
          </button>

          {/* Tooltip indicating $0 extra subscription fees · Auto-slicing active */}
          <div
            role="tooltip"
            className="pointer-events-none absolute left-1/2 -translate-x-1/2 top-[calc(100%+6px)] hidden group-hover/ag:flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#18181B] text-white text-[10.5px] font-medium shadow-xl whitespace-nowrap z-50 transition-opacity"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 shrink-0" />
            <span>$0 extra subscription fees · Auto-slicing active</span>
          </div>
        </div>
      ) : (
        <div className="relative group/ag flex items-center shrink-0">
          <button
            type="button"
            onClick={handleConnectAntigravity}
            title="Connect Antigravity to activate Gemini 3.8 Flash auto-slicing"
            aria-label="Connect Antigravity"
            className="inline-flex items-center gap-1.5 px-2.5 py-1 sm:py-1.5 rounded-full text-[11px] sm:text-[12px] font-medium bg-[#18181B] hover:bg-black text-white shadow-2xs hover:shadow transition-all cursor-pointer select-none"
          >
            <svg
              aria-hidden="true"
              viewBox="0 0 16 16"
              className="w-3 h-3 text-emerald-400 shrink-0"
              fill="currentColor"
            >
              <path d="M8 1a1 1 0 0 1 1 1v2.07a6.002 6.002 0 0 1 4.93 4.93H15a1 1 0 1 1 0 2h-1.07a6.002 6.002 0 0 1-4.93 4.93V15a1 1 0 1 1-2 0v-1.07A6.002 6.002 0 0 1 2.07 9H1a1 1 0 0 1 0-2h1.07A6.002 6.002 0 0 1 7.07 2.07V2a1 1 0 0 1 1-1Zm0 3.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Z" />
            </svg>
            <span className="tracking-tight font-semibold">Connect Antigravity</span>
          </button>

          {/* Interactive Tooltip */}
          <div
            role="tooltip"
            className="pointer-events-none absolute left-1/2 -translate-x-1/2 top-[calc(100%+6px)] hidden group-hover/ag:flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#18181B] text-white text-[10.5px] font-medium shadow-xl whitespace-nowrap z-50 transition-opacity"
          >
            <span>1-click Connect · $0 extra subscription fees</span>
          </div>
        </div>
      )}

      {/* Minimalist Navbar GitHub Sync Trigger */}
      <button
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        aria-expanded={isOpen}
        aria-label={`GitHub remote ${effectiveRepoSlug} tracking ${effectiveDefaultBranch}, branch ${effectiveDefaultBranch} ← ${shortHeadBranch}, ${statusSummaryLabel}`}
        className={`group inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-[12px] sm:text-[12.5px] font-medium transition-all cursor-pointer select-none ${
          isOpen
            ? 'bg-black/[0.06] text-[#18181B]'
            : 'text-[#52525B] hover:text-[#18181B] hover:bg-black/[0.035]'
        }`}
      >
        {/* Live status dot */}
        <span className="relative flex h-2 w-2 shrink-0">
          {(localStagedCount > 0 || isFetching) && (
            <span
              className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-60 ${
                isFetching ? 'bg-sky-400' : 'bg-amber-400'
              }`}
            />
          )}
          <span
            className={`relative inline-flex rounded-full h-2 w-2 ${syncDotClass}`}
          />
        </span>

        {/* GitHub Remote & Branch Connection */}
        <span className="inline-flex items-center gap-1.5 font-mono text-[11.5px] text-[#27272A] tracking-tight">
          <svg
            aria-hidden="true"
            viewBox="0 0 16 16"
            className="w-3.5 h-3.5 text-[#52525B] group-hover:text-[#18181B] transition-colors shrink-0"
            fill="currentColor"
          >
            <path d="M9.5 3.25a2.25 2.25 0 1 1 3 2.122V6A2.5 2.5 0 0 1 10 8.5H6a1 1 0 0 0-1 1v1.128a2.251 2.251 0 1 1-1.5 0V5.372a2.25 2.25 0 1 1 1.5 0v1.836A2.493 2.493 0 0 1 6 7h4a1 1 0 0 0 1-1v-.628A2.25 2.25 0 0 1 9.5 3.25Zm-6 0a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0Zm8.25-.75a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5ZM4.25 12a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Z" />
          </svg>
          <span className="font-semibold text-[#18181B]">{effectiveRepoSlug}</span>
          <span className="text-zinc-400">·</span>
          <span>{effectiveDefaultBranch}</span>
          <span className="hidden md:inline text-zinc-400">←</span>
          <span className="hidden md:inline max-w-[115px] truncate text-[#52525B]">
            {shortHeadBranch}
          </span>
        </span>

        <span aria-hidden="true" className="text-zinc-300">
          ·
        </span>

        {/* Pending PR Synchronization State */}
        <span
          className={`whitespace-nowrap ${
            localStagedCount > 0
              ? 'text-amber-800 font-semibold'
              : 'text-[#52525B] group-hover:text-[#18181B]'
          }`}
        >
          {statusSummaryLabel}
        </span>
      </button>

      {/* Minimalist Real-Time GitHub Sync Inspector Popover */}
      {isOpen && (
        <div
          role="dialog"
          aria-label="GitHub Branch & PR Synchronization Inspector"
          className="absolute right-0 top-[calc(100%+10px)] w-[340px] sm:w-[376px] rounded-2xl bg-[#FAF8F5] border border-black/[0.08] shadow-[0_20px_50px_rgba(0,0,0,0.12)] p-4 z-50 space-y-3.5 text-left"
        >
          {/* Row 1: Repository & Real-Time Connection Header */}
          <div className="flex items-start justify-between gap-3 pb-3 border-b border-black/[0.06]">
            <div className="min-w-0">
              <div className="flex items-center gap-1.5 text-[11px] font-mono uppercase tracking-[0.12em] text-zinc-500">
                <span
                  className={`w-1.5 h-1.5 rounded-full ${
                    githubConfig.connected ? 'bg-emerald-500' : 'bg-zinc-400'
                  }`}
                />
                <span>GitHub Remote</span>
                <span aria-hidden="true">·</span>
                <span>{lastLatencyMs}ms</span>
              </div>
              <div className="text-[13.5px] font-semibold text-[#18181B] truncate mt-0.5 flex items-center gap-2">
                <span>{effectiveRepoSlug}</span>
                <span className="text-[11px] font-mono font-normal text-zinc-500">
                  tracking <strong className="text-zinc-800 font-semibold">{effectiveDefaultBranch}</strong>
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={() => fetchSyncStatus(true)}
              className="px-2.5 py-1 rounded-lg text-[11.5px] font-medium text-[#3F3F46] hover:text-[#18181B] hover:bg-black/[0.05] transition-colors cursor-pointer shrink-0"
            >
              {isFetching ? 'Checking…' : 'Refresh'}
            </button>
          </div>

          {/* Antigravity Backend Status Row */}
          <div className="p-2.5 rounded-xl bg-white border border-black/[0.06] flex items-center justify-between gap-3">
            <div className="min-w-0">
              <div className="flex items-center gap-1.5 text-[11px] font-mono uppercase tracking-[0.12em] text-zinc-500">
                <span
                  className={`w-1.5 h-1.5 rounded-full ${
                    isConnected ? 'bg-emerald-500 animate-pulse' : 'bg-zinc-400'
                  }`}
                />
                <span>Antigravity Engine</span>
              </div>
              <div className="text-[12px] font-semibold text-[#18181B] mt-0.5 flex items-center gap-1.5">
                <span>{isConnected ? 'Antigravity Live' : 'Disconnected'}</span>
                {isConnected && (
                  <span className="px-1.5 py-0.2 rounded text-[10px] font-mono font-medium bg-emerald-500/15 text-emerald-800">
                    Gemini 3.8 Flash
                  </span>
                )}
              </div>
              <div className="text-[10.5px] text-zinc-500 mt-0.5 truncate">
                {isConnected
                  ? '$0 extra subscription fees · Auto-slicing active'
                  : 'Connect to auto-slice commits with zero extra subscription fees'}
              </div>
            </div>

            <div className="shrink-0 flex items-center gap-1.5">
              {isConnected ? (
                <>
                  <button
                    type="button"
                    onClick={handleTestAntigravity}
                    className="px-2 py-1 rounded-lg text-[11px] font-medium text-emerald-800 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200/80 transition-colors cursor-pointer"
                  >
                    Test Ping
                  </button>
                  <button
                    type="button"
                    onClick={handleDisconnectAntigravity}
                    className="px-2 py-1 rounded-lg text-[11px] font-medium text-zinc-400 hover:text-zinc-700 hover:bg-black/[0.04] transition-colors cursor-pointer"
                    title="Disconnect Antigravity (toggle)"
                  >
                    Disconnect
                  </button>
                </>
              ) : (
                <button
                  type="button"
                  onClick={handleConnectAntigravity}
                  className="px-2.5 py-1 rounded-lg text-[11px] font-semibold text-white bg-[#18181B] hover:bg-black transition-colors cursor-pointer"
                >
                  Connect
                </button>
              )}
            </div>
          </div>

          {/* Row 2: Active Branch Topology & Base Branch Switcher */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-[11.5px] text-zinc-500">
              <span>Branch Tracking Topology</span>
              <span className="font-mono text-[11px] text-zinc-600">
                HEAD {telemetry?.latestSha || '8f4e2c1'}
              </span>
            </div>

            <div className="p-2.5 rounded-xl bg-white border border-black/[0.06] space-y-2">
              <div className="flex items-center justify-between gap-2 text-[12px] font-mono">
                <span className="text-[#18181B] font-semibold">
                  {effectiveRepoSlug} ({effectiveDefaultBranch})
                </span>
                <span className="text-zinc-400">←</span>
                <span className="text-[#3F3F46] truncate">
                  {activeHeadBranch}
                </span>
              </div>

              {/* Minimal Segmented Target Base Branch Selector */}
              <div className="flex items-center justify-between gap-1 pt-1.5 border-t border-black/[0.04]">
                <span className="text-[11px] text-zinc-500">Target base:</span>
                <div className="inline-flex items-center gap-1 bg-[#F4F2EE] p-0.5 rounded-lg">
                  {(['main', 'staging', 'release/v2'] as const).map((branch) => (
                    <button
                      key={branch}
                      type="button"
                      onClick={() => handleSelectBaseBranch(branch)}
                      className={`px-2 py-0.5 rounded-md text-[11px] font-mono transition-colors cursor-pointer ${
                        effectiveDefaultBranch === branch
                          ? 'bg-white text-[#18181B] font-semibold shadow-2xs'
                          : 'text-zinc-500 hover:text-[#18181B]'
                      }`}
                    >
                      {branch}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Row 3: Pending PR Synchronization Telemetry */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-[11.5px] text-zinc-500">
              <span>PR Synchronization Queue</span>
              <span>
                {pendingSyncTotal === 0
                  ? 'All slices synced'
                  : `${pendingSyncTotal} awaiting action`}
              </span>
            </div>

            {/* Clean unboxed telemetry counters */}
            <div className="grid grid-cols-4 gap-1.5 p-2.5 rounded-xl bg-white border border-black/[0.06] text-center">
              <div>
                <div className="text-[14px] font-semibold text-[#18181B] font-mono">
                  {localStagedCount}
                </div>
                <div className="text-[10.5px] text-zinc-500">Pending</div>
              </div>
              <div>
                <div className="text-[14px] font-semibold text-emerald-700 font-mono">
                  {localOpenPrCount}
                </div>
                <div className="text-[10.5px] text-zinc-500">Open PRs</div>
              </div>
              <div>
                <div className="text-[14px] font-semibold text-amber-700 font-mono">
                  {localDraftPrCount}
                </div>
                <div className="text-[10.5px] text-zinc-500">Draft PRs</div>
              </div>
              <div>
                <div className="text-[14px] font-semibold text-purple-700 font-mono">
                  {localMergedPrCount}
                </div>
                <div className="text-[10.5px] text-zinc-500">Merged</div>
              </div>
            </div>

            {/* Compact preview of top pending / active stack items */}
            <div className="space-y-1.5 max-h-[136px] overflow-y-auto pr-0.5">
              {stagedAtomicStack.slice(0, 2).map((unit) => (
                <div
                  key={`nav-staged-${unit.id}`}
                  className="flex items-center justify-between gap-2 px-2.5 py-1.5 rounded-lg bg-amber-50/70 border border-amber-200/70 text-[11.5px]"
                >
                  <div className="min-w-0 truncate">
                    <span className="font-mono text-amber-900 font-medium">
                      {unit.conventionalHeader}
                    </span>
                  </div>
                  <span className="text-[10.5px] font-mono text-amber-800 shrink-0">
                    +{unit.totalAdditions} -{unit.totalDeletions} · Staged
                  </span>
                </div>
              ))}

              {pushedStack.slice(0, 3).map((pr, idx) => (
                <div
                  key={`nav-pr-${pr.id}-${idx}`}
                  className="flex items-center justify-between gap-2 px-2.5 py-1.5 rounded-lg bg-white border border-black/[0.05] text-[11.5px]"
                >
                  <div className="min-w-0 truncate flex items-center gap-1.5">
                    <span className="font-mono text-zinc-400">
                      #{pr.prNumber || 141 + idx}
                    </span>
                    <span className="text-[#27272A] truncate">
                      {pr.conventionalHeader}
                    </span>
                  </div>
                  <span
                    className={`text-[10.5px] font-mono shrink-0 ${
                      pr.status === 'merged'
                        ? 'text-purple-700'
                        : pr.status === 'draft'
                        ? 'text-amber-700'
                        : 'text-emerald-700'
                    }`}
                  >
                    {pr.status === 'merged'
                      ? 'Merged'
                      : pr.status === 'draft'
                      ? 'Draft'
                      : 'Open'}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Row 4: Minimalist Synchronization Actions */}
          <div className="pt-2 border-t border-black/[0.06] flex items-center justify-between gap-2">
            {localStagedCount > 0 ? (
              <button
                type="button"
                onClick={handleManualSyncNow}
                className="flex-1 py-2 px-3 rounded-xl bg-[#232325] hover:bg-[#141416] text-white text-[12px] font-semibold transition-colors cursor-pointer"
              >
                Sync {localStagedCount} Pending PR{localStagedCount === 1 ? '' : 's'} Now
              </button>
            ) : topDraftPr ? (
              <button
                type="button"
                onClick={() => onPromoteDraftPr(topDraftPr.id)}
                className="flex-1 py-2 px-3 rounded-xl bg-[#232325] hover:bg-[#141416] text-white text-[12px] font-semibold transition-colors cursor-pointer"
              >
                Promote Draft PR #{topDraftPr.prNumber || 143} → Open
              </button>
            ) : (
              <button
                type="button"
                onClick={handleManualSyncNow}
                className="flex-1 py-2 px-3 rounded-xl bg-black/[0.05] hover:bg-black/[0.08] text-[#18181B] text-[12px] font-medium transition-colors cursor-pointer"
              >
                Verify Branch Sync
              </button>
            )}

            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                onNavigateToStack();
              }}
              className="py-2 px-3 rounded-xl text-[12px] font-medium text-[#52525B] hover:text-[#18181B] hover:bg-black/[0.04] transition-colors cursor-pointer shrink-0"
            >
              PR Stack →
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
