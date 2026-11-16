import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  AntigravityPromptEvent,
  AtomicCommitUnit,
  DailyCadenceDay,
  DiffHunk,
  GitHubConnectionConfig,
  GuardrailPolicy,
  IdeAgentProfile,
  IdeHostId,
} from '../types/git';
import { AGENT_ICON_ASSETS, AgentIcon, OttoLogo } from './AgentIcon';
import { NavbarGitHubSyncStatus } from './NavbarGitHubSyncStatus';
import {
  applyHotkeyPreset,
  formatCompactShortcut,
  HotkeyActionId,
  HotkeyBinding,
  HotkeyPresetId,
  serializeKeyboardEvent,
} from '../utils/hotkeyManager';
import {
  extractNavigableHunks,
  formatHunkForClipboard,
  parseUnifiedDiffLines,
  resolveCommitCiCdStatus,
  resolveCommitRealHunks,
  scanStackForMergeConflicts,
  searchStackedCommitsAndHunks,
  StackedSearchMatch,
} from '../utils/atomicEngine';
import { SyntaxHighlightedDiffViewer } from './SyntaxHighlightedDiffViewer';
import { RebasePlaygroundView } from './RebasePlaygroundView';
import {
  AlertTriangle,
  ArrowUp,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Copy,
  GitBranch,
  GitCommit,
  GitMerge,
  GitPullRequest,
  History,
  MoreVertical,
  PanelLeft,
  Plus,
  Scissors,
  Search,
  Share,
  Sparkles,
  X,
} from 'lucide-react';

interface OttoDesktopAppViewProps {
  ideProfiles: IdeAgentProfile[];
  selectedIde: IdeHostId | 'all';
  onSelectIde: (ide: IdeHostId | 'all') => void;
  workingTreeHunks: DiffHunk[];
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  promptStream: AntigravityPromptEvent[];
  dailyCadence: DailyCadenceDay[];
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  daemonActive: boolean;
  isRefiningAi: boolean;
  statusNotice: string | null;
  onDismissNotice: () => void;
  onToggleDaemon: () => void;
  onPushSingleCommit: (commitId: string) => void;
  onPushAllStaged: () => void;
  onSplitCommit: (commitId: string, hunkIdToExtract: string) => void;
  onMergeTopPr: (commitId: string) => void;
  onPromoteDraftPr: (commitId: string) => void;
  onChangeBaseBranch: (nextBranch: string) => void;
  onSimulateLiveAgentTick: (targetIde: IdeHostId) => void;
  onInjectNotesCapture: (payload: {
    promptText: string;
    rawFilesInput: string;
    sourceAgent: IdeHostId;
    autoPushImmediately: boolean;
  }) => void;
  onRefineWithAi: () => void;
  onUpdatePolicy: (policy: GuardrailPolicy) => void;
  onResetDemo: () => void;
  hotkeyBindings: HotkeyBinding[];
  onUpdateHotkeyBindings: (next: HotkeyBinding[]) => void;
  lastTriggeredShortcut: {
    actionLabel: string;
    combo: string;
    timestamp: string;
  } | null;
  onTriggerHotkeyAction: (actionId: HotkeyActionId) => void;
  onNavigateToLanding: () => void;
  onReorderStagedStack?: (
    nextStack: AtomicCommitUnit[],
    summaryMessage?: string
  ) => void;
}

const ALL_IDE_IDS: IdeHostId[] = [
  'claude-code',
  'antigravity',
  'cursor',
  'kiro',
  'codex-cli',
  'vscode',
  'windsurf',
  'gemini-cli',
];

const KEYMAP_PRESET_BUTTONS: { id: HotkeyPresetId; label: string }[] = [
  { id: 'default_alt_shift', label: '⌥⇧ Mac' },
  { id: 'ctrl_shift', label: '⌃⇧ Win/Linux' },
  { id: 'alt_single', label: '⌥ Fast' },
];

export const OttoDesktopAppView: React.FC<OttoDesktopAppViewProps> = ({
  ideProfiles,
  selectedIde,
  onSelectIde,
  workingTreeHunks,
  stagedAtomicStack,
  pushedStack,
  policy,
  githubConfig,
  daemonActive,
  isRefiningAi,
  statusNotice,
  onDismissNotice,
  onToggleDaemon,
  onPushSingleCommit,
  onPushAllStaged,
  onSplitCommit,
  onMergeTopPr,
  onPromoteDraftPr,
  onChangeBaseBranch,
  onSimulateLiveAgentTick,
  onInjectNotesCapture,
  onRefineWithAi,
  onUpdatePolicy,
  onResetDemo,
  hotkeyBindings,
  onUpdateHotkeyBindings,
  lastTriggeredShortcut,
  onTriggerHotkeyAction,
  onNavigateToLanding,
  onReorderStagedStack,
}) => {
  const [activeAgent, setActiveAgent] = useState<IdeHostId>('claude-code');
  const [showAgentMenu, setShowAgentMenu] = useState(false);
  const [canvasMode, setCanvasMode] = useState<'sliced' | 'rebase' | 'original'>(
    'sliced'
  );
  const [diffLayout, setDiffLayout] = useState<'unified' | 'split'>('unified');
  const [selectedFileFilter, setSelectedFileFilter] = useState<string>('all');
  const [activeHunkCursor, setActiveHunkCursor] = useState<number>(0);
  const [showAllCommitHunks, setShowAllCommitHunks] = useState<boolean>(false);
  const [selectedUnitId, setSelectedUnitId] = useState<string | null>(
    stagedAtomicStack[0]?.id || pushedStack[0]?.id || null
  );
  const [showTimeMachine, setShowTimeMachine] = useState(true);
  const [showLeftSidebar, setShowLeftSidebar] = useState(true);
  const [showVariantsDrawer, setShowVariantsDrawer] = useState(false);
  const [promptInput, setPromptInput] = useState('');
  const [recordingActionId, setRecordingActionId] = useState<HotkeyActionId | null>(
    null
  );
  const [showAllCompleted, setShowAllCompleted] = useState(false);
  const [globalSearchQuery, setGlobalSearchQuery] = useState('');
  const [isSearchDropdownOpen, setIsSearchDropdownOpen] = useState(false);
  const [copiedToolbarHunk, setCopiedToolbarHunk] = useState(false);
  const [lastCopiedClipboardText, setLastCopiedClipboardText] = useState('');
  const globalSearchInputRef = useRef<HTMLInputElement | null>(null);

  const prevHeadIdsRef = useRef<{ stagedHead?: string; pushedHead?: string }>({
    stagedHead: stagedAtomicStack[0]?.id,
    pushedHead: pushedStack[0]?.id,
  });

  // Global Cmd+K / Ctrl+K shortcut to focus the top search bar
  useEffect(() => {
    const onWindowKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        globalSearchInputRef.current?.focus();
        setIsSearchDropdownOpen(true);
      }
    };
    window.addEventListener('keydown', onWindowKeyDown);
    return () => window.removeEventListener('keydown', onWindowKeyDown);
  }, []);

  // Automatically select newly sliced or auto-pushed real-time commits so the Git Diff panel updates immediately
  useEffect(() => {
    const currentStagedHead = stagedAtomicStack[0]?.id;
    const currentPushedHead = pushedStack[0]?.id;

    if (
      currentStagedHead &&
      currentStagedHead !== prevHeadIdsRef.current.stagedHead
    ) {
      if (canvasMode !== 'rebase') {
        setSelectedUnitId(currentStagedHead);
        setSelectedFileFilter('all');
        setActiveHunkCursor(0);
        setCanvasMode('sliced');
      }
    } else if (
      currentPushedHead &&
      currentPushedHead !== prevHeadIdsRef.current.pushedHead
    ) {
      if (canvasMode !== 'rebase') {
        setSelectedUnitId(currentPushedHead);
        setSelectedFileFilter('all');
        setActiveHunkCursor(0);
        setCanvasMode('sliced');
      }
    }

    prevHeadIdsRef.current = {
      stagedHead: currentStagedHead,
      pushedHead: currentPushedHead,
    };
  }, [stagedAtomicStack, pushedStack, canvasMode]);

  // Combined list of all units (staged working on + pushed completed)
  const allUnits = useMemo(
    () => [...stagedAtomicStack, ...pushedStack],
    [stagedAtomicStack, pushedStack]
  );

  const activeUnit = useMemo(() => {
    if (allUnits.length === 0) return null;
    return allUnits.find((u) => u.id === selectedUnitId) || allUnits[0];
  }, [allUnits, selectedUnitId]);

  const activeHunks = useMemo(
    () => (activeUnit ? resolveCommitRealHunks(activeUnit) : []),
    [activeUnit]
  );

  const activeCiCdReport = useMemo(
    () =>
      activeUnit ? resolveCommitCiCdStatus(activeUnit, githubConfig) : null,
    [activeUnit, githubConfig]
  );

  const activeConflictReport = useMemo(
    () => scanStackForMergeConflicts(activeUnit, allUnits),
    [activeUnit, allUnits]
  );

  const navigableHunks = useMemo(
    () => extractNavigableHunks(activeHunks),
    [activeHunks]
  );

  const safeHunkCursor =
    navigableHunks.length > 0
      ? ((activeHunkCursor % navigableHunks.length) + navigableHunks.length) %
        navigableHunks.length
      : 0;

  const currentNavigableHunk = navigableHunks[safeHunkCursor] || null;

  const displayedNavigableHunks = useMemo(() => {
    if (selectedFileFilter !== 'all') {
      const byFile = navigableHunks.filter(
        (h) => h.filePath === selectedFileFilter
      );
      if (byFile.length > 0) return byFile;
    }
    if (showAllCommitHunks) {
      return navigableHunks;
    }
    return currentNavigableHunk ? [currentNavigableHunk] : navigableHunks;
  }, [
    navigableHunks,
    selectedFileFilter,
    showAllCommitHunks,
    currentNavigableHunk,
  ]);

  const handlePrevHunk = () => {
    if (navigableHunks.length === 0) return;
    const nextIdx =
      (safeHunkCursor - 1 + navigableHunks.length) % navigableHunks.length;
    setActiveHunkCursor(nextIdx);
    setSelectedFileFilter('all');
    setShowAllCommitHunks(false);
  };

  const handleNextHunk = () => {
    if (navigableHunks.length === 0) return;
    const nextIdx = (safeHunkCursor + 1) % navigableHunks.length;
    setActiveHunkCursor(nextIdx);
    setSelectedFileFilter('all');
    setShowAllCommitHunks(false);
  };

  const handleCopyActiveHunk = async () => {
    const targetHunk = currentNavigableHunk || navigableHunks[0];
    if (!targetHunk) return;
    const formatted = formatHunkForClipboard(
      targetHunk,
      activeUnit?.conventionalHeader
    );
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(formatted);
      }
    } catch {
      // Fallback when clipboard permissions are restricted in headless browser
    }
    setLastCopiedClipboardText(formatted);
    setCopiedToolbarHunk(true);
    window.setTimeout(() => {
      setCopiedToolbarHunk(false);
    }, 1800);
  };

  const searchMatches = useMemo(
    () => searchStackedCommitsAndHunks(allUnits, globalSearchQuery),
    [allUnits, globalSearchQuery]
  );

  const matchedCommitIdSet = useMemo(
    () => new Set(searchMatches.map((m) => m.commitId)),
    [searchMatches]
  );

  const filteredStagedStack = useMemo(() => {
    if (!globalSearchQuery.trim()) return stagedAtomicStack;
    return stagedAtomicStack.filter((u) => matchedCommitIdSet.has(u.id));
  }, [stagedAtomicStack, globalSearchQuery, matchedCommitIdSet]);

  const filteredPushedStack = useMemo(() => {
    if (!globalSearchQuery.trim()) return pushedStack;
    return pushedStack.filter((u) => matchedCommitIdSet.has(u.id));
  }, [pushedStack, globalSearchQuery, matchedCommitIdSet]);

  const handleSelectSearchMatch = (match: StackedSearchMatch) => {
    setSelectedUnitId(match.commitId);
    setSelectedFileFilter('all');
    setShowAllCommitHunks(false);
    setActiveHunkCursor(Math.max(0, match.hunkIndex - 1));
    setCanvasMode('sliced');
    setIsSearchDropdownOpen(false);
  };

  const activeAgentMeta =
    AGENT_ICON_ASSETS[activeAgent] || AGENT_ICON_ASSETS['claude-code'];

  const handlePromptBarSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!promptInput.trim()) {
      onSimulateLiveAgentTick(activeAgent);
      return;
    }
    onInjectNotesCapture({
      promptText: promptInput.trim(),
      rawFilesInput: promptInput.trim(),
      sourceAgent: activeAgent,
      autoPushImmediately: false,
    });
    setPromptInput('');
  };

  const handleKeyDownForRecording = (
    e: React.KeyboardEvent,
    actionId: HotkeyActionId
  ) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.key === 'Escape') {
      setRecordingActionId(null);
      return;
    }
    const combo = serializeKeyboardEvent(e.nativeEvent);
    if (!combo) return;
    const updated = hotkeyBindings.map((b) =>
      b.actionId === actionId ? { ...b, combo } : b
    );
    onUpdateHotkeyBindings(updated);
    setRecordingActionId(null);
  };

  const visibleCompleted =
    showAllCompleted || Boolean(globalSearchQuery.trim())
      ? filteredPushedStack
      : filteredPushedStack.slice(0, 4);

  const primaryHunk = activeHunks[0] || workingTreeHunks[0];
  const primaryParsedPreview = useMemo(() => {
    if (!primaryHunk) return [];
    return parseUnifiedDiffLines(primaryHunk.diffSnippet)
      .filter((l) => l.type === 'add' || l.type === 'del')
      .slice(0, 3);
  }, [primaryHunk]);

  return (
    <div className="h-screen w-screen overflow-hidden bg-[#F5F3EE] text-[#1D1D1F] flex flex-col select-none font-sans">
      {/* TOP NATIVE MACOS WINDOW BAR (Matches uploaded reference screenshot) */}
      <header className="h-12 shrink-0 bg-[#F5F3EE] border-b border-black/[0.06] flex items-center justify-between px-4">
        {/* Left Window Controls & Sidebar Toggle */}
        <div className="flex items-center gap-3 w-[252px] shrink-0">
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onNavigateToLanding}
              title="Return to Otto Landing Page (/)"
              className="w-3 h-3 rounded-full bg-[#FF5F56] border border-black/10 hover:brightness-95 cursor-pointer"
            />
            <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-black/10" />
            <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-black/10" />
          </div>

          <div className="flex items-center gap-1 ml-2 text-zinc-500">
            <button
              type="button"
              onClick={() => setShowLeftSidebar((prev) => !prev)}
              className="p-1.5 rounded-lg hover:bg-black/[0.05] text-zinc-600 transition-colors cursor-pointer"
              title="Toggle Left Agent Sidebar"
            >
              <PanelLeft className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={onNavigateToLanding}
              className="p-1.5 rounded-lg hover:bg-black/[0.05] text-zinc-500 hover:text-zinc-900 transition-colors cursor-pointer"
              title="Back to Landing Page (/)"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
          </div>

          <div className="flex items-center gap-1.5 pl-1 border-l border-black/[0.07]">
            <OttoLogo sizeClass="w-5 h-5" />
            <span className="text-xs font-semibold tracking-tight text-zinc-800">
              otto
            </span>
          </div>
        </div>

        {/* Center Bar: Global Search Bar + Segmented Mode Toggle + Actions */}
        <div className="flex-1 flex items-center justify-between gap-3 px-4 min-w-0">
          {/* Global Search Bar for Commits & Diff Hunks across Stacked PRs */}
          <div className="relative flex-1 max-w-[360px] min-w-[200px]">
            <div className="flex items-center gap-2 bg-white hover:bg-zinc-50/90 focus-within:bg-white focus-within:ring-2 focus-within:ring-indigo-500/30 border border-black/[0.08] rounded-full px-3 py-1 shadow-2xs transition-all">
              <Search className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
              <input
                ref={globalSearchInputRef}
                type="text"
                role="searchbox"
                data-testid="global-search-input"
                aria-label="Global search commits and hunks"
                value={globalSearchQuery}
                onFocus={() => setIsSearchDropdownOpen(true)}
                onChange={(e) => {
                  setGlobalSearchQuery(e.target.value);
                  setIsSearchDropdownOpen(true);
                }}
                onKeyDown={(e) => {
                  if (e.key === 'Escape') {
                    setIsSearchDropdownOpen(false);
                  } else if (e.key === 'Enter' && searchMatches.length > 0) {
                    e.preventDefault();
                    handleSelectSearchMatch(searchMatches[0]);
                  }
                }}
                placeholder="Search commits, PRs, files, or hunks... (⌘K)"
                className="w-full bg-transparent text-xs text-[#1D1D1F] placeholder:text-zinc-400 focus:outline-none"
              />
              {globalSearchQuery ? (
                <button
                  type="button"
                  aria-label="Clear search"
                  data-testid="clear-global-search-btn"
                  onClick={() => {
                    setGlobalSearchQuery('');
                    setIsSearchDropdownOpen(false);
                  }}
                  className="p-0.5 rounded-full hover:bg-zinc-200/70 text-zinc-400 hover:text-zinc-700 cursor-pointer shrink-0"
                >
                  <X className="w-3 h-3" />
                </button>
              ) : (
                <kbd className="hidden sm:inline-block px-1.5 py-0.5 rounded bg-zinc-100 border border-black/[0.07] font-mono text-[9.5px] text-zinc-400 shrink-0">
                  ⌘K
                </kbd>
              )}
            </div>

            {/* Global Search Results Dropdown across Stacked PRs & Diff Hunks */}
            {isSearchDropdownOpen && globalSearchQuery.trim().length > 0 && (
              <div
                data-testid="global-search-results"
                role="listbox"
                aria-label="Search Results for Commits and Hunks"
                className="absolute left-0 top-full mt-1.5 w-[440px] max-w-[85vw] max-h-[380px] overflow-y-auto z-50 rounded-2xl bg-[#181B24] text-zinc-100 border border-white/[0.12] shadow-2xl p-2 space-y-1 font-mono text-xs"
              >
                <div className="px-2.5 py-1.5 flex items-center justify-between text-[10px] text-zinc-400 border-b border-white/[0.07]">
                  <span>
                    {searchMatches.length}{' '}
                    {searchMatches.length === 1 ? 'match' : 'matches'} across{' '}
                    {allUnits.length} stacked commits &amp; PRs
                  </span>
                  <button
                    type="button"
                    onClick={() => setIsSearchDropdownOpen(false)}
                    className="text-zinc-400 hover:text-white cursor-pointer"
                  >
                    Esc
                  </button>
                </div>

                {searchMatches.length === 0 ? (
                  <div className="px-3 py-5 text-center text-zinc-400 text-xs">
                    No commits, files, or diff hunks matching &ldquo;
                    {globalSearchQuery}&rdquo;
                  </div>
                ) : (
                  searchMatches.slice(0, 12).map((match) => (
                    <button
                      key={match.id}
                      type="button"
                      data-testid="global-search-result-item"
                      onClick={() => handleSelectSearchMatch(match)}
                      className="w-full text-left px-2.5 py-2 rounded-xl hover:bg-white/[0.08] transition-colors flex flex-col gap-1 cursor-pointer"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-1.5 min-w-0">
                          <span
                            className={`px-1.5 py-0.5 rounded text-[9.5px] font-semibold uppercase shrink-0 ${
                              match.kind === 'hunk'
                                ? 'bg-indigo-500/25 text-indigo-200 border border-indigo-400/30'
                                : 'bg-emerald-500/20 text-emerald-300 border border-emerald-400/30'
                            }`}
                          >
                            {match.kind === 'hunk'
                              ? `Hunk ${match.hunkIndex}/${match.totalHunksInCommit}`
                              : 'Commit'}
                          </span>
                          <span className="text-zinc-100 font-semibold truncate">
                            {match.filePath}
                          </span>
                        </div>
                        <span className="text-[10px] text-zinc-400 shrink-0">
                          {match.prNumber
                            ? `PR #${match.prNumber}`
                            : match.commitSha}
                        </span>
                      </div>
                      <div className="text-[11px] text-zinc-300 truncate">
                        {match.conventionalHeader}
                      </div>
                      <div className="text-[10px] text-emerald-300/90 bg-black/30 px-2 py-0.5 rounded truncate">
                        {match.matchedLinePreview}
                      </div>
                    </button>
                  ))
                )}
              </div>
            )}
          </div>

          <div className="inline-flex items-center bg-[#E6E3DC] p-0.5 rounded-full border border-black/[0.05] shrink-0">
            <button
              type="button"
              data-testid="mode-git-diff-btn"
              onClick={() => setCanvasMode('sliced')}
              className={`px-3.5 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-all cursor-pointer ${
                canvasMode === 'sliced'
                  ? 'bg-white text-[#1D1D1F] shadow-2xs'
                  : 'text-zinc-600 hover:text-zinc-900'
              }`}
            >
              Git Diff
            </button>
            <button
              type="button"
              data-testid="mode-rebase-playground-btn"
              onClick={() => setCanvasMode('rebase')}
              className={`px-3.5 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-all cursor-pointer flex items-center gap-1.5 ${
                canvasMode === 'rebase'
                  ? 'bg-white text-[#1D1D1F] shadow-2xs'
                  : 'text-zinc-600 hover:text-zinc-900'
              }`}
            >
              <span>Rebase Playground</span>
              <span className="px-1.5 py-0.2 rounded-full bg-indigo-500/15 text-indigo-700 font-mono text-[9.5px] font-bold">
                {stagedAtomicStack.length}
              </span>
            </button>
            <button
              type="button"
              data-testid="mode-working-tree-btn"
              onClick={() => setCanvasMode('original')}
              className={`px-3.5 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-all cursor-pointer ${
                canvasMode === 'original'
                  ? 'bg-white text-[#1D1D1F] shadow-2xs'
                  : 'text-zinc-600 hover:text-zinc-900'
              }`}
            >
              Working Tree
            </button>
          </div>

          {/* Right side of center bar: Share/Push PR Stack + More */}
          <div className="flex items-center gap-2 shrink-0">
            <div className="hidden 2xl:block scale-95 origin-right">
              <NavbarGitHubSyncStatus
                githubConfig={githubConfig}
                stagedAtomicStack={stagedAtomicStack}
                pushedStack={pushedStack}
                daemonActive={daemonActive}
                onPushAllStaged={onPushAllStaged}
                onPromoteDraftPr={onPromoteDraftPr}
                onChangeBaseBranch={onChangeBaseBranch}
                onNavigateToStack={() => setShowTimeMachine(true)}
              />
            </div>

            <button
              type="button"
              onClick={onPushAllStaged}
              disabled={stagedAtomicStack.length === 0}
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-white hover:bg-zinc-50 disabled:opacity-50 border border-black/[0.08] shadow-2xs text-xs font-medium text-[#1D1D1F] whitespace-nowrap shrink-0 transition-all cursor-pointer"
            >
              <Share className="w-3.5 h-3.5 text-zinc-600 shrink-0" />
              <span>Push Stack ({stagedAtomicStack.length})</span>
            </button>

            <button
              type="button"
              onClick={() => setShowVariantsDrawer((prev) => !prev)}
              className="p-1.5 rounded-lg hover:bg-black/[0.05] text-zinc-600 shrink-0 cursor-pointer"
              title="Hotkeys & Guardrails (⌥⇧Q)"
            >
              <MoreVertical className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Right Header: Time Machine Header */}
        <div className="w-[272px] shrink-0 pl-4 border-l border-black/[0.06] flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-xs font-medium text-[#1D1D1F]">
            <History className="w-3.5 h-3.5 text-zinc-500" />
            <span>Time Machine</span>
            <span className="text-zinc-400 font-normal ml-1 tabular-nums">
              {allUnits.length} versions
            </span>
          </div>
          <button
            type="button"
            onClick={() => setShowTimeMachine((prev) => !prev)}
            className="p-1 rounded-md hover:bg-black/[0.05] text-zinc-400 hover:text-zinc-700 cursor-pointer"
            title="Toggle Time Machine Panel"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      </header>

      {/* MAIN 3-PANE DESKTOP WORKSPACE */}
      <div className="flex-1 flex min-h-0 overflow-hidden">
        {/* LEFT PANE: Active Agent Pill + "Working on" + "Completed" Atomic Slices */}
        {showLeftSidebar && (
          <aside className="w-[268px] shrink-0 bg-[#F5F3EE] border-r border-black/[0.06] flex flex-col justify-between p-3.5 overflow-y-auto">
            <div className="space-y-5">
              {/* Top Agent Selector Card (Matches "Claude Code · Idle" card in screenshot) */}
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setShowAgentMenu((prev) => !prev)}
                  className="w-full p-2.5 rounded-2xl bg-white/85 hover:bg-white border border-black/[0.06] shadow-2xs flex items-center justify-between transition-all cursor-pointer text-left"
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <AgentIcon
                      agentId={activeAgent}
                      sizeClass="w-8 h-8"
                      roundedClass="rounded-full"
                    />
                    <div className="min-w-0">
                      <div className="text-[13px] font-semibold text-[#1D1D1F] truncate">
                        {activeAgentMeta.label}
                      </div>
                      <div className="flex items-center gap-1.5 text-[11px] text-zinc-500">
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            daemonActive ? 'bg-emerald-500' : 'bg-zinc-400'
                          }`}
                        />
                        <span>
                          {stagedAtomicStack.length > 0
                            ? `Slicing (${stagedAtomicStack.length})`
                            : 'Idle · Watching'}
                        </span>
                      </div>
                    </div>
                  </div>
                  <ChevronDown className="w-4 h-4 text-zinc-400 shrink-0" />
                </button>

                {/* Dropdown to switch between all 8 coding agents */}
                {showAgentMenu && (
                  <div className="absolute left-0 right-0 top-full mt-1.5 z-30 bg-white rounded-2xl border border-black/[0.08] shadow-xl p-1.5 space-y-0.5">
                    {ALL_IDE_IDS.map((ideId) => {
                      const meta = AGENT_ICON_ASSETS[ideId];
                      return (
                        <button
                          key={ideId}
                          type="button"
                          onClick={() => {
                            setActiveAgent(ideId);
                            setShowAgentMenu(false);
                          }}
                          className={`w-full flex items-center justify-between px-2.5 py-1.5 rounded-xl text-xs font-medium cursor-pointer ${
                            activeAgent === ideId
                              ? 'bg-[#EEF0FF] text-indigo-950 font-semibold'
                              : 'text-zinc-700 hover:bg-zinc-100'
                          }`}
                        >
                          <span className="flex items-center gap-2">
                            <AgentIcon
                              agentId={ideId}
                              sizeClass="w-5 h-5"
                              roundedClass="rounded-md"
                            />
                            <span>{meta.label}</span>
                          </span>
                          {activeAgent === ideId && (
                            <Check className="w-3.5 h-3.5 text-indigo-600" />
                          )}
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* "Working on" Section (Staged Atomic Slices in Flight) */}
              <div className="space-y-2">
                <div className="flex items-center justify-between px-1">
                  <span className="text-xs font-semibold text-[#1D1D1F]">
                    Working on
                  </span>
                  <span className="text-[11px] text-zinc-400 tabular-nums">
                    {filteredStagedStack.length === 0
                      ? 'No matching items'
                      : `${filteredStagedStack.length} active slices`}
                  </span>
                </div>

                {filteredStagedStack.length > 0 && (
                  <div className="space-y-1.5">
                    {filteredStagedStack.map((slice, idx) => {
                      const isSelected = activeUnit?.id === slice.id;
                      const ciReport = resolveCommitCiCdStatus(
                        slice,
                        githubConfig
                      );
                      const sliceConflict = scanStackForMergeConflicts(
                        slice,
                        allUnits
                      );
                      return (
                        <button
                          key={slice.id}
                          type="button"
                          data-testid={`staged-commit-card-${idx + 1}`}
                          onClick={() => {
                            setSelectedUnitId(slice.id);
                            setSelectedFileFilter('all');
                            setActiveHunkCursor(0);
                            setCanvasMode('sliced');
                          }}
                          className={`w-full p-2.5 rounded-2xl flex flex-col gap-2 text-left transition-all cursor-pointer ${
                            isSelected
                              ? 'bg-[#ECEEFE] border-[1.5px] border-[#7B83EB] shadow-2xs'
                              : 'bg-white/55 hover:bg-white/90 border-[1.5px] border-black/[0.04]'
                          }`}
                        >
                          <div className="flex items-center gap-2.5 w-full">
                            {/* Mini Thumbnail Preview Card with Status Badge */}
                            <div className="w-11 h-9 rounded-lg bg-[#E4E2DC] border border-black/[0.06] shrink-0 relative flex items-center justify-center overflow-hidden">
                              <div className="w-6 h-7 rounded-xs bg-[#1E2028] p-1 flex flex-col gap-0.5">
                                <span className="h-0.5 w-full bg-emerald-400/80 rounded-full" />
                                <span className="h-0.5 w-3/4 bg-indigo-300/70 rounded-full" />
                                <span className="h-0.5 w-full bg-white/40 rounded-full" />
                              </div>
                              <span className="absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full bg-white border border-black/10 flex items-center justify-center shadow-2xs">
                                <GitCommit className="w-2.5 h-2.5 text-indigo-600" />
                              </span>
                            </div>

                            <div className="min-w-0 flex-1">
                              <div className="text-[12px] font-medium text-[#1D1D1F] leading-snug line-clamp-2">
                                {slice.scope} · Slice {idx + 1} · {slice.title}
                              </div>
                            </div>
                          </div>

                          {/* CI/CD Visual Progress Bar & Timeline Indicator per Atomic Commit */}
                          <div
                            data-testid="commit-cicd-progress-bar"
                            data-cicd-status={ciReport.status}
                            className="w-full pt-1.5 border-t border-black/[0.05] space-y-1"
                          >
                            <div className="flex items-center justify-between text-[10px] font-mono">
                              <div className="flex items-center gap-1.5 min-w-0">
                                <span
                                  className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded font-semibold uppercase tracking-wider text-[9px] ${
                                    ciReport.status === 'passing'
                                      ? 'bg-emerald-500/15 text-emerald-800 border border-emerald-500/30'
                                      : ciReport.status === 'failing'
                                      ? 'bg-rose-500/15 text-rose-800 border border-rose-500/30'
                                      : 'bg-amber-500/15 text-amber-800 border border-amber-500/30'
                                  }`}
                                >
                                  <span
                                    className={`w-1.5 h-1.5 rounded-full ${
                                      ciReport.status === 'passing'
                                        ? 'bg-emerald-500'
                                        : ciReport.status === 'failing'
                                        ? 'bg-rose-500'
                                        : 'bg-amber-500 animate-pulse'
                                    }`}
                                  />
                                  CI: {ciReport.statusLabel}
                                </span>
                                {sliceConflict.hasConflicts && (
                                  <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded bg-rose-600 text-white font-semibold text-[9px]">
                                    <AlertTriangle className="w-2.5 h-2.5" />
                                    Conflict
                                  </span>
                                )}
                              </div>
                              <span className="text-zinc-500 tabular-nums shrink-0">
                                {ciReport.progressPercent}%
                              </span>
                            </div>

                            {/* 4-Stage Visual CI/CD Pipeline Timeline Progress Bar */}
                            <div className="grid grid-cols-4 gap-1 w-full">
                              {ciReport.steps.map((step) => (
                                <div
                                  key={step.id}
                                  title={`${step.label}: ${step.status}`}
                                  className={`h-1.5 rounded-full transition-all ${
                                    step.status === 'passing'
                                      ? 'bg-emerald-500'
                                      : step.status === 'failing'
                                      ? 'bg-rose-500'
                                      : 'bg-amber-400 animate-pulse'
                                  }`}
                                />
                              ))}
                            </div>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* "Completed" Section (Pushed & Stacked PRs — matches screenshot list) */}
              <div className="space-y-2">
                <div className="flex items-center justify-between px-1">
                  <span className="text-xs font-medium text-zinc-500">
                    Completed{' '}
                    <span className="tabular-nums ml-0.5">
                      {pushedStack.length}
                    </span>
                  </span>
                  <button
                    type="button"
                    onClick={() => onSimulateLiveAgentTick(activeAgent)}
                    className="text-[11px] font-medium text-indigo-600 hover:text-indigo-800 cursor-pointer"
                  >
                    + Slice edit
                  </button>
                </div>

                <div className="space-y-1.5">
                  {visibleCompleted.map((pr, idx) => {
                    const isSelected = activeUnit?.id === pr.id;
                    const ciReport = resolveCommitCiCdStatus(pr, githubConfig);
                    return (
                      <button
                        key={pr.id}
                        type="button"
                        onClick={() => {
                          setSelectedUnitId(pr.id);
                          setSelectedFileFilter('all');
                          setActiveHunkCursor(0);
                          setCanvasMode('sliced');
                        }}
                        className={`w-full p-2.5 rounded-2xl flex flex-col gap-2 text-left transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-[#ECEEFE] border-[1.5px] border-[#7B83EB] shadow-2xs'
                            : 'bg-white/45 hover:bg-white/80 border-[1.5px] border-black/[0.04]'
                        }`}
                      >
                        <div className="flex items-center gap-2.5 w-full">
                          {/* Mini Visual Preview Thumbnail with Green Check Badge */}
                          <div className="w-11 h-9 rounded-lg bg-[#E4E2DC] border border-black/[0.06] shrink-0 relative flex items-center justify-center overflow-hidden">
                            <div className="w-6 h-7 rounded-xs bg-[#22252E] p-1 flex flex-col justify-center gap-0.5">
                              <span className="h-1 w-full bg-white/90 rounded-[1px]" />
                              <span className="h-0.5 w-2/3 bg-emerald-400/80 rounded-full" />
                            </div>
                            <span className="absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full bg-white border border-black/10 flex items-center justify-center shadow-2xs">
                              <Check className="w-2.5 h-2.5 text-emerald-600 stroke-[2.5]" />
                            </span>
                          </div>

                          <div className="min-w-0 flex-1">
                            <div className="text-[12px] font-medium text-[#1D1D1F] leading-snug line-clamp-2">
                              Otto · PR #{pr.prNumber || 141 + idx} · {pr.title}
                            </div>
                          </div>
                        </div>

                        {/* CI/CD Visual Progress Bar & Timeline Indicator per Stacked PR */}
                        <div
                          data-testid="commit-cicd-progress-bar"
                          data-cicd-status={ciReport.status}
                          className="w-full pt-1.5 border-t border-black/[0.05] space-y-1"
                        >
                          <div className="flex items-center justify-between text-[10px] font-mono">
                            <span
                              className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded font-semibold uppercase tracking-wider text-[9px] ${
                                ciReport.status === 'passing'
                                  ? 'bg-emerald-500/15 text-emerald-800 border border-emerald-500/30'
                                  : ciReport.status === 'failing'
                                  ? 'bg-rose-500/15 text-rose-800 border border-rose-500/30'
                                  : 'bg-amber-500/15 text-amber-800 border border-amber-500/30'
                              }`}
                            >
                              <span
                                className={`w-1.5 h-1.5 rounded-full ${
                                  ciReport.status === 'passing'
                                    ? 'bg-emerald-500'
                                    : ciReport.status === 'failing'
                                    ? 'bg-rose-500'
                                    : 'bg-amber-500 animate-pulse'
                                }`}
                              />
                              CI: {ciReport.statusLabel}
                            </span>
                            <span className="text-zinc-500 tabular-nums">
                              {ciReport.progressPercent}% · {ciReport.durationLabel}
                            </span>
                          </div>
                          <div className="grid grid-cols-4 gap-1 w-full">
                            {ciReport.steps.map((step) => (
                              <div
                                key={step.id}
                                title={`${step.label}: ${step.status}`}
                                className={`h-1.5 rounded-full ${
                                  step.status === 'passing'
                                    ? 'bg-emerald-500'
                                    : step.status === 'failing'
                                    ? 'bg-rose-500'
                                    : 'bg-amber-400'
                                }`}
                              />
                            ))}
                          </div>
                        </div>
                      </button>
                    );
                  })}
                </div>

                <button
                  type="button"
                  onClick={() => setShowAllCompleted((prev) => !prev)}
                  className="px-1 pt-1 text-[11px] text-zinc-400 hover:text-zinc-700 cursor-pointer"
                >
                  {showAllCompleted
                    ? 'Show fewer completed'
                    : `Show all ${pushedStack.length} completed`}
                </button>
              </div>
            </div>

            {/* Bottom Sidebar Status / Reset */}
            <div className="pt-3 border-t border-black/[0.06] flex items-center justify-between text-[11px] text-zinc-400">
              <span>{allUnits.length} atomic slices</span>
              <button
                type="button"
                onClick={onResetDemo}
                className="hover:text-zinc-700 underline cursor-pointer"
              >
                Reset
              </button>
            </div>
          </aside>
        )}

        {/* CENTER PANE: Recessed Stone Stage + Popped-Out Focus Card + Bottom Prompt Bar */}
        <main className="flex-1 flex flex-col min-w-0 bg-[#F5F3EE] p-3 sm:p-4 overflow-hidden">
          {statusNotice && (
            <div
              role="status"
              className="mb-2.5 px-3.5 py-2 rounded-xl bg-white border border-black/[0.08] shadow-2xs flex items-center justify-between text-xs text-zinc-800 shrink-0"
            >
              <span>{statusNotice}</span>
              <button
                type="button"
                onClick={onDismissNotice}
                className="text-zinc-400 hover:text-zinc-800 ml-3 underline cursor-pointer"
              >
                Dismiss
              </button>
            </div>
          )}

          {/* Recessed Stone Canvas Container — Dedicated Real-Time Git Diff Panel */}
          <div
            id="otto-git-diff-panel"
            aria-label="Git Diff Panel"
            className="flex-1 rounded-2xl bg-[#E9E6DF] border border-black/[0.05] p-3 sm:p-5 flex flex-col overflow-hidden"
          >
            {activeUnit && canvasMode === 'sliced' ? (
              <div className="w-full max-w-[960px] mx-auto flex-1 flex flex-col min-h-0 rounded-2xl bg-[#14161C] border border-black/20 shadow-[0_16px_40px_rgba(0,0,0,0.12)] overflow-hidden">
                {/* Dedicated 'Git Diff' Panel Header */}
                <div className="px-4 py-3 bg-[#1B1E26] border-b border-white/[0.08] flex flex-wrap items-center justify-between gap-3 shrink-0">
                  <div className="min-w-0 flex-1 space-y-1">
                    <div className="flex flex-wrap items-center gap-2 text-[11px] font-mono text-zinc-400">
                      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-indigo-500/20 text-indigo-300 border border-indigo-400/30 font-semibold uppercase tracking-wider text-[10px]">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                        Git Diff
                      </span>
                      <span className="px-1.5 py-0.5 rounded bg-white/[0.06] text-zinc-300">
                        {activeUnit.sha}
                      </span>
                      <GitBranch className="w-3.5 h-3.5 text-indigo-400 shrink-0" />
                      <span>{activeUnit.parentBranch || githubConfig.defaultBranch}</span>
                      <span className="text-zinc-600">←</span>
                      <span className="text-indigo-300 font-medium truncate">
                        {activeUnit.branchName}
                      </span>
                      {activeUnit.prNumber && (
                        <>
                          <span className="text-zinc-600">·</span>
                          <span className="text-emerald-400">
                            PR #{activeUnit.prNumber}
                          </span>
                        </>
                      )}
                    </div>
                    <div className="text-xs sm:text-[13px] font-mono font-semibold text-white truncate">
                      {activeUnit.conventionalHeader}
                    </div>
                  </div>

                  <div className="flex items-center gap-2.5 shrink-0">
                    {/* Unified / Split Diff View Toggle */}
                    <div className="inline-flex items-center bg-[#111318] p-0.5 rounded-lg border border-white/[0.08] font-mono text-[10px]">
                      <button
                        type="button"
                        onClick={() => setDiffLayout('unified')}
                        className={`px-2 py-0.5 rounded-md transition-colors cursor-pointer ${
                          diffLayout === 'unified'
                            ? 'bg-white/[0.14] text-white font-semibold'
                            : 'text-zinc-400 hover:text-zinc-200'
                        }`}
                      >
                        Unified
                      </button>
                      <button
                        type="button"
                        onClick={() => setDiffLayout('split')}
                        className={`px-2 py-0.5 rounded-md transition-colors cursor-pointer ${
                          diffLayout === 'split'
                            ? 'bg-white/[0.14] text-white font-semibold'
                            : 'text-zinc-400 hover:text-zinc-200'
                        }`}
                      >
                        Split
                      </button>
                    </div>

                    <div className="flex items-center gap-2 font-mono text-xs tabular-nums">
                      <span className="text-emerald-400 font-medium">
                        +{activeUnit.totalAdditions}
                      </span>
                      <span className="text-rose-400 font-medium">
                        -{activeUnit.totalDeletions}
                      </span>
                      <span className="px-2 py-0.5 rounded bg-white/[0.07] text-zinc-300 text-[11px]">
                        {activeUnit.totalLoc} LOC
                      </span>
                    </div>

                    {activeHunks.length > 1 && activeUnit.status === 'staged' && (
                      <button
                        type="button"
                        onClick={() =>
                          onSplitCommit(activeUnit.id, activeHunks[0].id)
                        }
                        className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white/[0.08] hover:bg-white/[0.14] text-[11px] font-mono text-zinc-200 cursor-pointer"
                      >
                        <Scissors className="w-3 h-3" />
                        <span>Split Hunk</span>
                      </button>
                    )}

                    {activeUnit.status === 'staged' && (
                      <button
                        type="button"
                        onClick={() => onPushSingleCommit(activeUnit.id)}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-xs font-medium text-white transition-colors cursor-pointer"
                      >
                        <GitPullRequest className="w-3.5 h-3.5" />
                        <span>Commit &amp; Push PR</span>
                      </button>
                    )}

                    {activeUnit.status === 'draft' && (
                      <button
                        type="button"
                        onClick={() => onPromoteDraftPr(activeUnit.id)}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-500 text-xs font-medium text-white transition-colors cursor-pointer"
                      >
                        <GitPullRequest className="w-3.5 h-3.5" />
                        <span>Mark Ready</span>
                      </button>
                    )}

                    {activeUnit.status === 'pr_open' && (
                      <button
                        type="button"
                        onClick={() => onMergeTopPr(activeUnit.id)}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-xs font-medium text-white transition-colors cursor-pointer"
                      >
                        <GitMerge className="w-3.5 h-3.5" />
                        <span>Merge PR</span>
                      </button>
                    )}
                  </div>
                </div>

                {/* CI/CD Pipeline Timeline Bar for Active Commit (Fetched from mock GitHub Config) */}
                {activeCiCdReport && (
                  <div
                    data-testid="active-commit-cicd-timeline"
                    data-cicd-status={activeCiCdReport.status}
                    className="px-4 py-2 bg-[#171A23] border-b border-white/[0.07] flex flex-wrap items-center justify-between gap-3 shrink-0 font-mono text-[11px]"
                  >
                    <div className="flex items-center gap-2 min-w-0">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider shrink-0 ${
                          activeCiCdReport.status === 'passing'
                            ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-400/30'
                            : activeCiCdReport.status === 'failing'
                            ? 'bg-rose-500/25 text-rose-200 border border-rose-400/40'
                            : 'bg-amber-500/20 text-amber-200 border border-amber-400/30'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            activeCiCdReport.status === 'passing'
                              ? 'bg-emerald-400'
                              : activeCiCdReport.status === 'failing'
                              ? 'bg-rose-400'
                              : 'bg-amber-400 animate-pulse'
                          }`}
                        />
                        CI/CD: {activeCiCdReport.statusLabel}
                      </span>
                      <span className="text-zinc-300 truncate">
                        {activeCiCdReport.workflowName}
                      </span>
                      <span className="text-zinc-500 hidden lg:inline">·</span>
                      <span className="text-zinc-400 truncate hidden lg:inline">
                        {activeCiCdReport.checksSummary}
                      </span>
                    </div>

                    {/* 4-Step Visual Pipeline Timeline Indicator */}
                    <div className="flex items-center gap-2 shrink-0">
                      <div className="flex items-center gap-1.5">
                        {activeCiCdReport.steps.map((step, sIdx) => (
                          <div
                            key={step.id}
                            className="flex items-center gap-1"
                          >
                            <span
                              className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] ${
                                step.status === 'passing'
                                  ? 'bg-emerald-500/15 text-emerald-300 border border-emerald-500/30'
                                  : step.status === 'failing'
                                  ? 'bg-rose-500/20 text-rose-300 border border-rose-500/40'
                                  : 'bg-amber-500/15 text-amber-200 border border-amber-500/30'
                              }`}
                            >
                              <span
                                className={`w-1.5 h-1.5 rounded-full ${
                                  step.status === 'passing'
                                    ? 'bg-emerald-400'
                                    : step.status === 'failing'
                                    ? 'bg-rose-400'
                                    : 'bg-amber-400 animate-pulse'
                                }`}
                              />
                              {step.label}
                            </span>
                            {sIdx < activeCiCdReport.steps.length - 1 && (
                              <span className="text-zinc-600 text-[10px]">→</span>
                            )}
                          </div>
                        ))}
                      </div>
                      <span className="text-zinc-400 tabular-nums text-[10px]">
                        {activeCiCdReport.progressPercent}%
                      </span>
                    </div>
                  </div>
                )}

                {/* Proactive Stack Merge Conflict Alert System (Before User Hits 'Push') */}
                {activeConflictReport.hasConflicts && (
                  <div
                    role="alert"
                    data-testid="proactive-merge-conflict-alert"
                    className="px-4 py-2.5 bg-rose-950/75 border-b border-rose-500/50 flex flex-wrap items-center justify-between gap-2.5 shrink-0 font-mono text-xs text-rose-100"
                  >
                    <div className="flex items-start sm:items-center gap-2.5 min-w-0 flex-1">
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-rose-500/30 border border-rose-400/60 text-rose-200 text-[10px] font-bold uppercase tracking-wider shrink-0">
                        <AlertTriangle className="w-3.5 h-3.5 text-rose-300 shrink-0" />
                        Merge Conflict Risk
                      </span>
                      <div className="min-w-0 flex-1 text-[11px] leading-snug">
                        <span className="font-semibold text-rose-200">
                          {activeConflictReport.conflictingFilePaths.length}{' '}
                          conflicting{' '}
                          {activeConflictReport.conflictingFilePaths.length === 1
                            ? 'file'
                            : 'files'}{' '}
                          detected across pending stack before Push:
                        </span>{' '}
                        {activeConflictReport.conflicts.map((c, cIdx) => (
                          <span key={`${c.filePath}-${c.conflictingCommitId}-${cIdx}`}>
                            <span
                              data-testid="proactive-conflict-file-pill"
                              className="inline-flex items-center px-1.5 py-0.5 mx-1 rounded bg-rose-600/40 border border-rose-400/60 text-rose-100 font-semibold text-[10.5px]"
                            >
                              {c.filePath}
                            </span>
                            <span className="text-rose-200/90">
                              ({c.overlapLineRange} with{' '}
                              <strong className="text-white">
                                {c.conflictingBranchName}
                              </strong>
                              )
                            </span>
                          </span>
                        ))}
                      </div>
                    </div>

                    {activeConflictReport.conflicts[0] && (
                      <button
                        type="button"
                        data-testid="inspect-conflicting-commit-btn"
                        onClick={() => {
                          const targetConflict = activeConflictReport.conflicts[0];
                          setSelectedUnitId(targetConflict.conflictingCommitId);
                          setSelectedFileFilter(targetConflict.filePath);
                          setActiveHunkCursor(0);
                          setCanvasMode('sliced');
                        }}
                        className="px-2.5 py-1 rounded-lg bg-rose-600 hover:bg-rose-500 text-white font-semibold text-[11px] whitespace-nowrap transition-colors cursor-pointer shrink-0 shadow-xs"
                      >
                        Inspect Conflicting Commit →
                      </button>
                    )}
                  </div>
                )}

                {/* Hunk Navigation Arrows, Copy Hunk & File Hunk Selector Bar */}
                <div className="px-4 py-2 bg-[#161922] border-b border-white/[0.07] flex flex-wrap items-center justify-between gap-2 shrink-0 font-mono text-[11px]">
                  {/* Left: Hunk Cycling Navigation Arrows + All Hunks + Copy Hunk */}
                  <div className="flex items-center gap-2 shrink-0">
                    <div
                      role="group"
                      aria-label="Hunk Navigation Controls"
                      className="inline-flex items-center bg-[#0F1117] rounded-lg border border-white/[0.1] p-0.5"
                    >
                      <button
                        type="button"
                        data-testid="prev-hunk-button"
                        onClick={handlePrevHunk}
                        aria-label="Previous Hunk"
                        title="Previous Hunk in Commit"
                        className="p-1 rounded-md text-zinc-300 hover:text-white hover:bg-white/[0.1] transition-colors cursor-pointer"
                      >
                        <ChevronLeft className="w-3.5 h-3.5" />
                      </button>
                      <span
                        data-testid="hunk-counter-badge"
                        className="px-2.5 py-0.5 text-[11px] font-semibold text-indigo-200 tabular-nums whitespace-nowrap"
                      >
                        Hunk {safeHunkCursor + 1} of {navigableHunks.length}
                      </span>
                      <button
                        type="button"
                        data-testid="next-hunk-button"
                        onClick={handleNextHunk}
                        aria-label="Next Hunk"
                        title="Next Hunk in Commit"
                        className="p-1 rounded-md text-zinc-300 hover:text-white hover:bg-white/[0.1] transition-colors cursor-pointer"
                      >
                        <ChevronRight className="w-3.5 h-3.5" />
                      </button>
                    </div>

                    {/* Step-by-Hunk vs Show All Hunks Toggle */}
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedFileFilter('all');
                        setShowAllCommitHunks((prev) => !prev);
                      }}
                      className={`px-2.5 py-1 rounded-md whitespace-nowrap transition-colors cursor-pointer ${
                        showAllCommitHunks && selectedFileFilter === 'all'
                          ? 'bg-indigo-500/20 text-indigo-200 border border-indigo-400/30 font-semibold'
                          : 'text-zinc-400 hover:text-zinc-200 bg-white/[0.04] hover:bg-white/[0.08]'
                      }`}
                    >
                      {showAllCommitHunks
                        ? `Showing All (${navigableHunks.length})`
                        : `All Hunks (${navigableHunks.length})`}
                    </button>

                    {/* Dedicated 'Copy Hunk' Button in Git Diff Toolbar */}
                    <button
                      type="button"
                      data-testid="copy-hunk-toolbar-btn"
                      aria-label="Copy Hunk"
                      data-copied-payload={lastCopiedClipboardText ? 'ready' : 'idle'}
                      onClick={handleCopyActiveHunk}
                      title="Copy current diff hunk to clipboard for external debugging or manual PR comments"
                      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md whitespace-nowrap transition-colors cursor-pointer ${
                        copiedToolbarHunk
                          ? 'bg-emerald-500/25 text-emerald-200 border border-emerald-400/40 font-semibold'
                          : 'bg-white/[0.06] hover:bg-white/[0.14] text-zinc-200 border border-white/[0.1]'
                      }`}
                    >
                      {copiedToolbarHunk ? (
                        <>
                          <Check className="w-3.5 h-3.5 text-emerald-300" />
                          <span>Copied Hunk!</span>
                        </>
                      ) : (
                        <>
                          <Copy className="w-3.5 h-3.5 text-indigo-300" />
                          <span>Copy Hunk</span>
                        </>
                      )}
                    </button>
                  </div>

                  {/* Right: File Tabs inside the Atomic Commit (Conflicting Files Highlighted in Red) */}
                  <div className="flex items-center gap-1.5 overflow-x-auto">
                    {activeHunks.map((hunk) => {
                      const isFileActive =
                        selectedFileFilter === hunk.filePath ||
                        (selectedFileFilter === 'all' &&
                          !showAllCommitHunks &&
                          currentNavigableHunk?.filePath === hunk.filePath);
                      const fileConflicts =
                        activeConflictReport.conflictsByFile[hunk.filePath] || [];
                      const isConflictingFile = fileConflicts.length > 0;

                      return (
                        <button
                          key={hunk.id}
                          type="button"
                          data-testid={
                            isConflictingFile
                              ? 'conflicting-file-tab'
                              : 'clean-file-tab'
                          }
                          data-conflict={isConflictingFile ? 'true' : 'false'}
                          onClick={() => {
                            const firstMatchingIdx = navigableHunks.findIndex(
                              (nh) => nh.filePath === hunk.filePath
                            );
                            if (firstMatchingIdx >= 0) {
                              setActiveHunkCursor(firstMatchingIdx);
                            }
                            setSelectedFileFilter(
                              selectedFileFilter === hunk.filePath
                                ? 'all'
                                : hunk.filePath
                            );
                          }}
                          className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-md whitespace-nowrap transition-colors cursor-pointer ${
                            isConflictingFile
                              ? 'bg-rose-500/25 text-rose-200 border border-rose-500/70 ring-1 ring-rose-500/40 font-semibold'
                              : isFileActive
                              ? 'bg-indigo-500/20 text-indigo-200 border border-indigo-400/30 font-semibold'
                              : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/[0.05]'
                          }`}
                        >
                          {isConflictingFile && (
                            <AlertTriangle className="w-3 h-3 text-rose-300 shrink-0" />
                          )}
                          <span
                            className={
                              isConflictingFile ? 'text-rose-200 font-bold' : ''
                            }
                          >
                            {hunk.filePath}
                          </span>
                          {isConflictingFile && (
                            <span className="px-1 py-0.2 rounded bg-rose-600 text-white text-[9px] font-bold uppercase">
                              Conflict
                            </span>
                          )}
                          <span className="text-emerald-400 text-[10px]">
                            +{hunk.additions}
                          </span>
                          <span className="text-rose-400 text-[10px]">
                            -{hunk.deletions}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Scrollable Syntax-Highlighted Diff Hunks Viewer */}
                <div className="flex-1 overflow-y-auto divide-y divide-white/[0.08]">
                  {displayedNavigableHunks.map((navHunk) => (
                    <SyntaxHighlightedDiffViewer
                      key={navHunk.id}
                      hunk={navHunk}
                      commitHeader={activeUnit.conventionalHeader}
                      totalHunksInCommit={navigableHunks.length}
                      isFocusedHunk={currentNavigableHunk?.id === navHunk.id}
                      diffLayout={diffLayout}
                      fileConflicts={
                        activeConflictReport.conflictsByFile[navHunk.filePath]
                      }
                      canExtractHunk={
                        activeHunks.length > 1 && activeUnit.status === 'staged'
                      }
                      onExtractHunk={() =>
                        onSplitCommit(activeUnit.id, navHunk.parentHunkId)
                      }
                      onSelectHunk={() =>
                        setActiveHunkCursor(navHunk.hunkIndex - 1)
                      }
                      onCopyHunk={(_copiedHunk, payload) => {
                        setLastCopiedClipboardText(payload);
                        setCopiedToolbarHunk(true);
                        window.setTimeout(() => {
                          setCopiedToolbarHunk(false);
                        }, 1800);
                      }}
                    />
                  ))}
                </div>
              </div>
            ) : canvasMode === 'rebase' ? (
              <RebasePlaygroundView
                pendingStack={stagedAtomicStack}
                allUnits={allUnits}
                policy={policy}
                githubConfig={githubConfig}
                selectedUnitId={activeUnit?.id || null}
                onSelectUnit={(commitId) => {
                  setSelectedUnitId(commitId);
                  setSelectedFileFilter('all');
                  setActiveHunkCursor(0);
                }}
                onReorderPendingStack={(nextStack, summaryMessage) => {
                  prevHeadIdsRef.current.stagedHead = nextStack[0]?.id;
                  onReorderStagedStack?.(nextStack, summaryMessage);
                }}
                onReturnToGitDiff={() => setCanvasMode('sliced')}
              />
            ) : (
              /* "Working Tree" Un-sliced Working Tree Diff View */
              <div className="w-full max-w-[960px] mx-auto flex-1 flex flex-col min-h-0 rounded-2xl bg-[#14161C] text-zinc-200 shadow-xl border border-black/20 overflow-hidden font-mono text-xs">
                <div className="px-4 py-3 bg-[#1B1E26] border-b border-white/[0.08] flex items-center justify-between shrink-0">
                  <div className="flex items-center gap-2.5">
                    <span className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-300 border border-rose-400/30 text-[10px]">
                      UN-SLICED WORKING TREE DIFF (
                      {(workingTreeHunks.length > 0 ? workingTreeHunks : activeHunks).length}{' '}
                      FILES)
                    </span>
                    <span className="text-zinc-400">
                      {githubConfig.owner}/{githubConfig.repo}
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() => setCanvasMode('sliced')}
                    className="px-2.5 py-1 rounded bg-indigo-600 hover:bg-indigo-500 text-white text-[11px] cursor-pointer"
                  >
                    Return to Git Diff Panel →
                  </button>
                </div>
                <pre className="p-4 text-[11px] leading-relaxed overflow-y-auto text-emerald-300/90 flex-1">
                  {(workingTreeHunks.length > 0 ? workingTreeHunks : activeHunks)
                    .map(
                      (h) =>
                        `diff --git a/${h.filePath} b/${h.filePath}\n${h.diffSnippet}`
                    )
                    .join('\n\n')}
                </pre>
              </div>
            )}
          </div>

          {/* BOTTOM FLOATING PROMPT & ACTION BAR */}
          <div className="pt-3 flex items-center gap-2.5 max-w-[960px] w-full mx-auto shrink-0">
            <form
              onSubmit={handlePromptBarSubmit}
              className="flex-1 bg-white rounded-full border border-black/[0.08] shadow-xs px-3.5 py-2 flex items-center gap-2.5"
            >
              <button
                type="button"
                onClick={() => onSimulateLiveAgentTick(activeAgent)}
                title="Stage next working tree change"
                className="w-6 h-6 rounded-full hover:bg-zinc-100 flex items-center justify-center text-zinc-500 hover:text-zinc-900 cursor-pointer shrink-0"
              >
                <Plus className="w-4 h-4" />
              </button>

              <input
                type="text"
                value={promptInput}
                onChange={(e) => setPromptInput(e.target.value)}
                placeholder="Enter file path or change (e.g. src/auth/session.ts +42 -8 | Harden JWT TTL)..."
                className="flex-1 text-xs sm:text-[13px] text-[#1D1D1F] placeholder:text-zinc-400 focus:outline-none bg-transparent"
              />

              {/* Agent Badge inside Input Bar (Only visible here and in top-left switcher) */}
              <button
                type="button"
                onClick={() => {
                  const idx = ALL_IDE_IDS.indexOf(activeAgent);
                  const next = ALL_IDE_IDS[(idx + 1) % ALL_IDE_IDS.length];
                  setActiveAgent(next);
                }}
                title={`Active Agent: ${activeAgentMeta.label} (Click to switch)`}
                className="inline-flex items-center gap-1 px-2 py-1 rounded-full hover:bg-zinc-100 text-xs text-zinc-600 cursor-pointer shrink-0"
              >
                <AgentIcon
                  agentId={activeAgent}
                  sizeClass="w-4 h-4"
                  roundedClass="rounded-full"
                />
                <ChevronDown className="w-3 h-3 text-zinc-400" />
              </button>

              <button
                type="submit"
                title="Slice into Atomic Commits"
                className="w-7 h-7 rounded-full bg-[#F2F0EB] hover:bg-[#1D1D1F] text-zinc-600 hover:text-white flex items-center justify-center transition-colors cursor-pointer shrink-0"
              >
                <ArrowUp className="w-3.5 h-3.5" />
              </button>
            </form>

            {/* "Show variants" / Hotkeys & Guardrails Pill Button */}
            <button
              type="button"
              onClick={() => setShowVariantsDrawer((prev) => !prev)}
              className={`px-4 py-2.5 rounded-full border text-xs font-semibold flex items-center gap-2 shadow-xs transition-all cursor-pointer shrink-0 ${
                showVariantsDrawer
                  ? 'bg-[#1D1D1F] text-white border-[#1D1D1F]'
                  : 'bg-white hover:bg-zinc-50 text-[#1D1D1F] border-black/[0.08]'
              }`}
            >
              <Sparkles className="w-3.5 h-3.5 text-indigo-600" />
              <span>Show variants</span>
            </button>
          </div>
        </main>

        {/* RIGHT PANE: "Time Machine" Version Stack & Rebase History */}
        {showTimeMachine && (
          <aside className="w-[272px] shrink-0 bg-[#F5F3EE] border-l border-black/[0.06] p-4 flex flex-col justify-between overflow-y-auto">
            <div className="space-y-5">
              {/* 3D Layered Atomic Diff Card Stack (Back card + Periwinkle-bordered Front card) */}
              <div className="pt-2 flex flex-col items-center">
                <div className="relative w-full pt-3">
                  {/* Back Card in Stack */}
                  <div className="w-[84%] mx-auto h-24 rounded-xl bg-white/70 border border-black/[0.08] shadow-xs -mb-20 scale-95 opacity-75" />

                  {/* Front Active Card with Periwinkle/Indigo Border showing Real Diff Hunk */}
                  <div className="relative z-10 w-full rounded-xl bg-white p-2.5 border-[2px] border-[#7B83EB] shadow-md space-y-2">
                    <div className="flex items-center justify-between text-[10px] font-mono">
                      <span className="px-1.5 py-0.5 rounded bg-[#ECEEFE] text-[#4F56D3] font-semibold truncate">
                        {activeUnit?.branchName}
                      </span>
                      <span className="text-emerald-700 font-semibold tabular-nums shrink-0">
                        +{activeUnit?.totalAdditions} / -{activeUnit?.totalDeletions}
                      </span>
                    </div>
                    <div className="rounded-lg bg-[#14161C] p-2 space-y-1 font-mono text-[9.5px]">
                      <div className="text-zinc-400 truncate">
                        {primaryHunk?.filePath}
                      </div>
                      {primaryParsedPreview.map((pLine, pIdx) => (
                        <div
                          key={pIdx}
                          className={`truncate ${
                            pLine.type === 'add'
                              ? 'text-emerald-300'
                              : 'text-rose-300'
                          }`}
                        >
                          {pLine.type === 'add' ? '+' : '-'} {pLine.content.trim()}
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* "Now" Caption Underneath Stack */}
                <div className="text-center mt-3 space-y-0.5 px-2">
                  <div className="text-xs font-semibold text-[#1D1D1F]">
                    {activeUnit?.sha} · {activeHunks.length}{' '}
                    {activeHunks.length === 1 ? 'hunk' : 'hunks'}
                  </div>
                  <div className="text-[11px] text-zinc-500 truncate max-w-[220px]">
                    {activeUnit?.conventionalHeader}
                  </div>
                </div>
              </div>

              {/* Version History List (Zero Agent Logos) */}
              <div className="space-y-1.5 pt-2 border-t border-black/[0.06]">
                <button
                  type="button"
                  onClick={() => setCanvasMode('sliced')}
                  className={`w-full p-2.5 rounded-xl flex items-center justify-between gap-2 text-left transition-colors cursor-pointer ${
                    canvasMode === 'sliced'
                      ? 'bg-[#E6E3DC]/90'
                      : 'hover:bg-black/[0.04]'
                  }`}
                >
                  <div className="min-w-0">
                    <div className="text-xs font-medium text-[#1D1D1F] truncate">
                      {activeUnit?.conventionalHeader}
                    </div>
                    <div className="text-[11px] text-zinc-500">
                      Git Diff · {activeUnit?.totalLoc} LOC ({activeHunks.length}{' '}
                      {activeHunks.length === 1 ? 'file' : 'files'})
                    </div>
                  </div>
                  <OttoLogo sizeClass="w-5 h-5" />
                </button>

                <button
                  type="button"
                  onClick={() => setCanvasMode('original')}
                  className={`w-full p-2.5 rounded-xl flex items-center justify-between gap-2 text-left transition-colors cursor-pointer ${
                    canvasMode === 'original'
                      ? 'bg-[#E6E3DC]/90'
                      : 'hover:bg-black/[0.04]'
                  }`}
                >
                  <div className="min-w-0">
                    <div className="text-xs font-medium text-[#1D1D1F] truncate">
                      Working Tree Diff
                    </div>
                    <div className="text-[11px] text-zinc-500">
                      Combined patch across all files
                    </div>
                  </div>
                  <span className="w-5 h-5 rounded-md bg-zinc-200/80 flex items-center justify-center font-mono text-[10px] text-zinc-600 shrink-0">
                    ±
                  </span>
                </button>

                <button
                  type="button"
                  onClick={() => setCanvasMode('rebase')}
                  className={`w-full p-2.5 rounded-xl flex items-center justify-between gap-2 text-left transition-colors cursor-pointer ${
                    canvasMode === 'rebase'
                      ? 'bg-[#E6E3DC]/90'
                      : 'hover:bg-black/[0.04]'
                  }`}
                >
                  <div className="min-w-0">
                    <div className="text-xs font-medium text-[#1D1D1F] truncate">
                      Rebase Playground
                    </div>
                    <div className="text-[11px] text-zinc-500">
                      Drag & drop {stagedAtomicStack.length} pending slices + DAG
                    </div>
                  </div>
                  <span className="w-5 h-5 rounded-md bg-indigo-500/15 flex items-center justify-center font-mono text-[10px] font-bold text-indigo-700 shrink-0">
                    ⇄
                  </span>
                </button>
              </div>

              {/* Compact Guardrails & Shortcuts Card inside Right Sidebar */}
              <div className="p-3 rounded-2xl bg-white/80 border border-black/[0.06] space-y-3">
                <div className="flex items-center justify-between text-[11px] font-medium text-zinc-700">
                  <span>Max Slice Cap</span>
                  <span className="font-mono font-semibold text-indigo-600 tabular-nums">
                    ≤{policy.maxLocPerCommit} LOC
                  </span>
                </div>
                <input
                  type="range"
                  min={40}
                  max={160}
                  step={10}
                  value={policy.maxLocPerCommit}
                  onChange={(e) =>
                    onUpdatePolicy({
                      ...policy,
                      maxLocPerCommit: Number(e.target.value),
                    })
                  }
                  className="w-full accent-indigo-600 cursor-pointer"
                />

                <div className="pt-1 border-t border-black/[0.05] space-y-1.5">
                  <div className="flex items-center justify-between text-[10.5px] text-zinc-500">
                    <span>Quick Commit</span>
                    <kbd className="px-1.5 py-0.5 rounded bg-zinc-100 border border-black/10 font-mono text-[10px] text-zinc-800">
                      {formatCompactShortcut(hotkeyBindings[0]?.combo || 'Alt+Shift+C')}
                    </kbd>
                  </div>
                  <div className="flex items-center justify-between text-[10.5px] text-zinc-500">
                    <span>Overlay Queue</span>
                    <kbd className="px-1.5 py-0.5 rounded bg-zinc-100 border border-black/10 font-mono text-[10px] text-zinc-800">
                      {formatCompactShortcut(hotkeyBindings[1]?.combo || 'Alt+Shift+Q')}
                    </kbd>
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-3 border-t border-black/[0.06] flex items-center justify-between text-[11px] text-zinc-500">
              <button
                type="button"
                onClick={onRefineWithAi}
                disabled={isRefiningAi}
                className="text-indigo-600 hover:text-indigo-800 font-medium cursor-pointer"
              >
                {isRefiningAi ? 'Refining...' : '✦ Refine Headers'}
              </button>
              <a
                href="/"
                onClick={(e) => {
                  e.preventDefault();
                  onNavigateToLanding();
                }}
                className="hover:text-zinc-900 cursor-pointer"
              >
                ← Landing (/)
              </a>
            </div>
          </aside>
        )}
      </div>

      {/* FLOATING VARIANTS & HOTKEY DRAWER (When clicking "Show variants" or "⋮") */}
      {showVariantsDrawer && (
        <div className="fixed bottom-16 right-6 z-40 w-[380px] rounded-3xl bg-white border border-black/[0.08] shadow-2xl p-5 space-y-4">
          <div className="flex items-center justify-between border-b border-black/[0.06] pb-3">
            <div className="flex items-center gap-2">
              <OttoLogo sizeClass="w-5 h-5" />
              <span className="text-xs font-semibold text-[#1D1D1F]">
                Otto Hotkeys &amp; Slice Variants
              </span>
            </div>
            <button
              type="button"
              onClick={() => setShowVariantsDrawer(false)}
              className="text-xs text-zinc-400 hover:text-zinc-800 cursor-pointer"
            >
              Close
            </button>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-[11px] text-zinc-500">Keymap Preset</span>
            <div className="flex items-center gap-1">
              {KEYMAP_PRESET_BUTTONS.map((p) => (
                <button
                  key={p.id}
                  type="button"
                  onClick={() => onUpdateHotkeyBindings(applyHotkeyPreset(p.id))}
                  className="px-2 py-0.5 rounded-md bg-zinc-100 hover:bg-zinc-200 text-[10px] font-mono text-zinc-700 cursor-pointer"
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            {hotkeyBindings.slice(0, 4).map((b) => {
              const isRec = recordingActionId === b.actionId;
              return (
                <div
                  key={b.actionId}
                  className="p-2.5 rounded-xl bg-[#F7F6F2] border border-black/[0.05] flex items-center justify-between gap-2"
                >
                  <span className="text-xs font-medium text-[#1D1D1F] truncate">
                    {b.label.replace(' (Top Slice)', '')}
                  </span>
                  <div className="flex items-center gap-1.5 shrink-0">
                    {isRec ? (
                      <input
                        type="text"
                        autoFocus
                        readOnly
                        onKeyDown={(e) => handleKeyDownForRecording(e, b.actionId)}
                        onBlur={() => setRecordingActionId(null)}
                        placeholder="Keys..."
                        className="w-20 px-1.5 py-0.5 rounded bg-indigo-50 border border-indigo-400 text-[10px] font-mono text-indigo-700 text-center"
                      />
                    ) : (
                      <button
                        type="button"
                        onClick={() => setRecordingActionId(b.actionId)}
                        className="px-2 py-0.5 rounded bg-white border border-black/10 font-mono text-[11px] font-semibold text-zinc-800 cursor-pointer"
                      >
                        {formatCompactShortcut(b.combo)}
                      </button>
                    )}
                    <button
                      type="button"
                      onClick={() => onTriggerHotkeyAction(b.actionId)}
                      className="px-2 py-0.5 rounded bg-[#1D1D1F] text-white text-[10px] font-semibold cursor-pointer"
                    >
                      Run
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};
