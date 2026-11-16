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
  parseUnifiedDiffLines,
  resolveCommitRealHunks,
} from '../utils/atomicEngine';
import { SyntaxHighlightedDiffViewer } from './SyntaxHighlightedDiffViewer';
import {
  ArrowUp,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  GitBranch,
  GitCommit,
  GitMerge,
  GitPullRequest,
  History,
  MoreVertical,
  PanelLeft,
  Plus,
  Scissors,
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
}) => {
  const [activeAgent, setActiveAgent] = useState<IdeHostId>('claude-code');
  const [showAgentMenu, setShowAgentMenu] = useState(false);
  const [canvasMode, setCanvasMode] = useState<'sliced' | 'original'>('sliced');
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

  const prevHeadIdsRef = useRef<{ stagedHead?: string; pushedHead?: string }>({
    stagedHead: stagedAtomicStack[0]?.id,
    pushedHead: pushedStack[0]?.id,
  });

  // Automatically select newly sliced or auto-pushed real-time commits so the Git Diff panel updates immediately
  useEffect(() => {
    const currentStagedHead = stagedAtomicStack[0]?.id;
    const currentPushedHead = pushedStack[0]?.id;

    if (
      currentStagedHead &&
      currentStagedHead !== prevHeadIdsRef.current.stagedHead
    ) {
      setSelectedUnitId(currentStagedHead);
      setSelectedFileFilter('all');
      setActiveHunkCursor(0);
      setCanvasMode('sliced');
    } else if (
      currentPushedHead &&
      currentPushedHead !== prevHeadIdsRef.current.pushedHead
    ) {
      setSelectedUnitId(currentPushedHead);
      setSelectedFileFilter('all');
      setActiveHunkCursor(0);
      setCanvasMode('sliced');
    }

    prevHeadIdsRef.current = {
      stagedHead: currentStagedHead,
      pushedHead: currentPushedHead,
    };
  }, [stagedAtomicStack, pushedStack]);

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

  const visibleCompleted = showAllCompleted
    ? pushedStack
    : pushedStack.slice(0, 4);

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

        {/* Center Segmented Pill ("Sliced" | "Original" — matches "Styled" | "Original" in screenshot) */}
        <div className="flex-1 flex items-center justify-between px-4 min-w-0">
          <div className="hidden xl:flex items-center gap-2 text-[11px] font-mono text-zinc-500 whitespace-nowrap truncate">
            <span className="truncate">{githubConfig.owner}/{githubConfig.repo}</span>
          </div>

          <div className="mx-auto inline-flex items-center bg-[#E6E3DC] p-0.5 rounded-full border border-black/[0.05] shrink-0">
            <button
              type="button"
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
                    {stagedAtomicStack.length === 0
                      ? 'No active items'
                      : `${stagedAtomicStack.length} active slices`}
                  </span>
                </div>

                {stagedAtomicStack.length > 0 && (
                  <div className="space-y-1.5">
                    {stagedAtomicStack.map((slice, idx) => {
                      const isSelected = activeUnit?.id === slice.id;
                      return (
                        <button
                          key={slice.id}
                          type="button"
                          onClick={() => {
                            setSelectedUnitId(slice.id);
                            setSelectedFileFilter('all');
                            setActiveHunkCursor(0);
                            setCanvasMode('sliced');
                          }}
                          className={`w-full p-2 rounded-2xl flex items-center gap-2.5 text-left transition-all cursor-pointer ${
                            isSelected
                              ? 'bg-[#ECEEFE] border-[1.5px] border-[#7B83EB] shadow-2xs'
                              : 'hover:bg-black/[0.03] border-[1.5px] border-transparent'
                          }`}
                        >
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
                        className={`w-full p-2 rounded-2xl flex items-center gap-2.5 text-left transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-[#ECEEFE] border-[1.5px] border-[#7B83EB] shadow-2xs'
                            : 'hover:bg-black/[0.03] border-[1.5px] border-transparent'
                        }`}
                      >
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

                {/* Hunk Navigation Arrows & File Hunk Selector Bar */}
                <div className="px-4 py-2 bg-[#161922] border-b border-white/[0.07] flex flex-wrap items-center justify-between gap-2 shrink-0 font-mono text-[11px]">
                  {/* Left: Hunk Cycling Navigation Arrows */}
                  <div className="flex items-center gap-2 shrink-0">
                    <div
                      role="group"
                      aria-label="Hunk Navigation Controls"
                      className="inline-flex items-center bg-[#0F1117] rounded-lg border border-white/[0.1] p-0.5"
                    >
                      <button
                        type="button"
                        onClick={handlePrevHunk}
                        aria-label="Previous Hunk"
                        title="Previous Hunk in Commit"
                        className="p-1 rounded-md text-zinc-300 hover:text-white hover:bg-white/[0.1] transition-colors cursor-pointer"
                      >
                        <ChevronLeft className="w-3.5 h-3.5" />
                      </button>
                      <span className="px-2.5 py-0.5 text-[11px] font-semibold text-indigo-200 tabular-nums whitespace-nowrap">
                        Hunk {safeHunkCursor + 1} of {navigableHunks.length}
                      </span>
                      <button
                        type="button"
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
                  </div>

                  {/* Right: File Tabs inside the Atomic Commit */}
                  <div className="flex items-center gap-1.5 overflow-x-auto">
                    {activeHunks.map((hunk) => {
                      const isFileActive =
                        selectedFileFilter === hunk.filePath ||
                        (selectedFileFilter === 'all' &&
                          !showAllCommitHunks &&
                          currentNavigableHunk?.filePath === hunk.filePath);
                      return (
                        <button
                          key={hunk.id}
                          type="button"
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
                            isFileActive
                              ? 'bg-indigo-500/20 text-indigo-200 border border-indigo-400/30 font-semibold'
                              : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/[0.05]'
                          }`}
                        >
                          <span>{hunk.filePath}</span>
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
                      totalHunksInCommit={navigableHunks.length}
                      isFocusedHunk={currentNavigableHunk?.id === navHunk.id}
                      diffLayout={diffLayout}
                      canExtractHunk={
                        activeHunks.length > 1 && activeUnit.status === 'staged'
                      }
                      onExtractHunk={() =>
                        onSplitCommit(activeUnit.id, navHunk.parentHunkId)
                      }
                      onSelectHunk={() =>
                        setActiveHunkCursor(navHunk.hunkIndex - 1)
                      }
                    />
                  ))}
                </div>
              </div>
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
