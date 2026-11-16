import React, { useState } from 'react';
import {
  AtomicCommitUnit,
  DailyCadenceDay,
  DiffHunk,
  GitHubConnectionConfig,
  GuardrailPolicy,
  IdeAgentProfile,
  IdeHostId,
} from '../types/git';
import {
  generateIdeExtensionBundle,
  summarizeThirtyDayCadence,
} from '../utils/atomicEngine';
import {
  DEFAULT_HOTKEY_BINDINGS,
  HotkeyActionId,
  HotkeyBinding,
} from '../utils/hotkeyManager';
import { AgentIcon, OttoLogo } from './AgentIcon';
import { PrStatusBadge } from './PrStatusBadge';
import { LiveIdeOverlayVideoStage } from './LiveIdeOverlayVideoStage';
import { NavbarGitHubSyncStatus } from './NavbarGitHubSyncStatus';
import { IdeHotkeyOverlayShowcase } from './IdeHotkeyOverlayShowcase';
import {
  Area,
  Bar,
  CartesianGrid,
  ComposedChart,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import {
  ArrowUp,
  BarChart3,
  Copy,
  GitCommit,
  GitMerge,
  Layers,
  Monitor,
  Scissors,
  Search,
  ShieldCheck,
  Smartphone,
  Sparkles,
  Terminal,
} from 'lucide-react';

interface FeaturesViewProps {
  ideProfiles: IdeAgentProfile[];
  workingTreeHunks: DiffHunk[];
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  dailyCadence: DailyCadenceDay[];
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  daemonActive?: boolean;
  isRefiningAi: boolean;
  onSimulateLiveAgentTick: (ide: IdeHostId) => void;
  onPushSingleCommit: (commitId: string) => void;
  onPushAllStaged: () => void;
  onSplitCommit: (commitId: string, hunkIdToExtract: string) => void;
  onMergeTopPr: (commitId: string) => void;
  onPromoteDraftPr?: (commitId: string) => void;
  onChangeBaseBranch?: (branch: string) => void;
  onRefineWithAi: () => void;
  onUpdatePolicy: (policy: GuardrailPolicy) => void;
  onResetDemo: () => void;
  appIconStyle: string;
  onChangeAppIconStyle: (style: string) => void;
  hotkeyBindings?: HotkeyBinding[];
  onUpdateHotkeyBindings?: (next: HotkeyBinding[]) => void;
  lastTriggeredShortcut?: {
    actionLabel: string;
    combo: string;
    timestamp: string;
  } | null;
  onTriggerHotkeyAction?: (actionId: HotkeyActionId) => void;
  onOpenInstallModal?: (tab: 'desktop' | 'ide' | 'daemon') => void;
}

const FEATURE_NAV_PILLS = [
  { num: '01', label: 'Agents', targetId: 'feat-01-agents' },
  { num: '02', label: 'Capture', targetId: 'feat-02-capture' },
  { num: '03', label: 'Style & Stack', targetId: 'feat-03-style' },
  { num: '04', label: 'Slice and cut', targetId: 'feat-04-cut' },
  { num: '05', label: 'Time Machine', targetId: 'feat-05-timemachine' },
  { num: '06', label: 'Organize and find', targetId: 'feat-06-organize' },
  { num: '07', label: 'Make it yours', targetId: 'feat-07-yours' },
];

const IDE_SHOWCASE_SCREENS: Record<
  IdeHostId,
  {
    title: string;
    subtitle: string;
    cursorLabel: string;
  }
> = {
  antigravity: {
    title: 'Google Antigravity IDE · Worktree & CodeLens Slicer',
    subtitle:
      'Hooks directly into Antigravity New Worktree sessions, isolates Implementation plan.md into docs(plans), and slices every prompt into ≤80 LOC stacked PRs.',
    cursorLabel: 'Creating atomic worktree slice',
  },
  'claude-code': {
    title: 'Claude Code Desktop · Multi-Pane Session & Post-Edit Hook',
    subtitle:
      'Intercepts Claude Opus multi-file edits in real time, splitting implementation and property-based test specs into chained Conventional Commits.',
    cursorLabel: 'Slicing idempotency.ts (+54 -9)',
  },
  'codex-cli': {
    title: 'OpenAI Codex Desktop · Monorepo PR Sitter & Auto-Stacker',
    subtitle:
      'Watches Codex o3-pro full-auto worktrees and slices multi-package monorepo diffs into 1-minute reviewable stacked PRs.',
    cursorLabel: 'Splitting ledger rounding PR stack',
  },
  cursor: {
    title: 'Cursor Mission Control + CLI · Parallel Composer Sync',
    subtitle:
      'Monitors parallel Cursor Mission Control agents and background CLI sessions simultaneously, auto-rebasing child PRs when base slices merge.',
    cursorLabel: 'Syncing replayStream.ts (+58 -9)',
  },
  vscode: {
    title: 'Visual Studio Code · Next Edit Suggestion (7 ↳|) & CodeLens',
    subtitle:
      'Pairs with VS Code inline Next Edit Suggestions and Copilot Agent Sessions to commit clean ≤80 LOC checkpoints in the background.',
    cursorLabel: 'Capturing VS Code Next Edit diff',
  },
  windsurf: {
    title: 'Windsurf IDE + Cascade · Flow Eagerness & Hunk Guard (→|)',
    subtitle:
      'Splits multi-file Windsurf Cascade Write flows and Tab →| Supercomplete jumps into chained GitHub PRs without breaking flow.',
    cursorLabel: 'Isolating Cascade hunk',
  },
  'gemini-cli': {
    title: 'Google Gemini CLI · MCP @otto/daemon Terminal Slicer',
    subtitle:
      'Connects natively to @google/gemini-cli via MCP to slice WriteFile tool edits into atomic branches and push stacked PRs from your shell.',
    cursorLabel: 'Auto-committing Gemini CLI patch',
  },
  kiro: {
    title: 'Kiro IDE · .kiro/specs/ Tasks to Stacked GitHub PRs',
    subtitle:
      'Maps Kiro Requirements, Design, and Tasks 1-to-1 to atomic commits and stacked GitHub PRs with automated spec CI checks.',
    cursorLabel: 'Syncing Kiro Spec PR #142',
  },
};

export const FeaturesView: React.FC<FeaturesViewProps> = ({
  ideProfiles,
  workingTreeHunks,
  stagedAtomicStack,
  pushedStack,
  dailyCadence,
  policy,
  githubConfig,
  daemonActive = true,
  isRefiningAi,
  onSimulateLiveAgentTick,
  onPushSingleCommit,
  onPushAllStaged,
  onSplitCommit,
  onMergeTopPr,
  onPromoteDraftPr,
  onChangeBaseBranch,
  onRefineWithAi,
  onUpdatePolicy,
  onResetDemo,
  appIconStyle,
  onChangeAppIconStyle,
  hotkeyBindings = DEFAULT_HOTKEY_BINDINGS,
  onUpdateHotkeyBindings,
  lastTriggeredShortcut = null,
  onTriggerHotkeyAction,
  onOpenInstallModal,
}) => {
  const [activeShowcaseAgent, setActiveShowcaseAgent] =
    useState<IdeHostId>('antigravity');
  const [selectedBeatIdx, setSelectedBeatIdx] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedHistoryIdx, setSelectedHistoryIdx] = useState(0);
  const [motionMode, setMotionMode] = useState<'Full' | 'Calm' | 'Still'>('Full');
  const [copiedCmd, setCopiedCmd] = useState(false);
  const [chartWindowDays, setChartWindowDays] = useState<30 | 14 | 7>(30);
  const [pushedFilter, setPushedFilter] = useState<
    'all' | 'open' | 'merged' | 'draft'
  >('all');

  const cadenceSlice = dailyCadence.slice(-chartWindowDays);
  const cadenceSummary = summarizeThirtyDayCadence(cadenceSlice);

  const allCommits = [...stagedAtomicStack, ...pushedStack];
  const activeBeat = allCommits[selectedBeatIdx] || allCommits[0];
  const activeHistoryUnit = allCommits[selectedHistoryIdx] || allCommits[0];
  const activeIdeShowcase =
    IDE_SHOWCASE_SCREENS[activeShowcaseAgent] ||
    IDE_SHOWCASE_SCREENS.antigravity;

  const filteredCommits = allCommits.filter((c) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      c.conventionalHeader.toLowerCase().includes(q) ||
      c.branchName.toLowerCase().includes(q) ||
      c.scope.toLowerCase().includes(q) ||
      c.hunks.some((h) => h.filePath.toLowerCase().includes(q))
    );
  });

  const extensionBundle = generateIdeExtensionBundle(policy, githubConfig);
  const cliInstallCommand = `npx @otto/daemon --repo ${githubConfig.owner}/${githubConfig.repo} --max-loc ${policy.maxLocPerCommit}`;

  const scrollToSection = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCopyCli = () => {
    navigator.clipboard?.writeText(cliInstallCommand).catch(() => {});
    setCopiedCmd(true);
    setTimeout(() => setCopiedCmd(false), 2000);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-24 py-6 sm:py-10">
      {/* Screen 8: FEATURES HERO + 01-07 PILL BAR */}
      <section className="text-center space-y-6">
        <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
          FEATURES
        </div>
        <h1 className="text-4xl sm:text-[56px] font-semibold tracking-[-0.035em] text-[#1D1D1F] leading-[1.08] max-w-2xl mx-auto">
          Built to keep up with how fast you ship.
        </h1>
        <p className="text-base sm:text-lg text-[#71717A] max-w-xl mx-auto leading-relaxed">
          Your agent edits, slices, commits, and stacks PRs across desktop and mobile while you keep building. Otto keeps every version and learns your guardrails.
        </p>

        {/* 01 - 07 Numbered Pill Navigation */}
        <div className="flex flex-wrap items-center justify-center gap-2 pt-2">
          {FEATURE_NAV_PILLS.map((pill) => (
            <button
              key={pill.num}
              type="button"
              onClick={() => scrollToSection(pill.targetId)}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white hover:bg-zinc-50 border border-black/[0.08] shadow-2xs text-xs sm:text-sm font-medium text-[#1D1D1F] transition-transform active:scale-95 cursor-pointer"
            >
              <span className="font-mono text-[11px] text-zinc-400">
                {pill.num}
              </span>
              <span>{pill.label}</span>
            </button>
          ))}
        </div>

        {/* Prominent Sleek CTA Row for Features View */}
        <div className="pt-4 flex flex-wrap items-center justify-center gap-3">
          <button
            type="button"
            onClick={() => onOpenInstallModal ? onOpenInstallModal('ide') : scrollToSection('feat-07-yours')}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#1D1D1F] hover:bg-black text-white text-xs sm:text-sm font-semibold shadow-xs hover:shadow-md transition-all cursor-pointer group"
          >
            <Layers className="w-4 h-4 text-indigo-400 group-hover:scale-110 transition-transform" />
            <span>Install IDE Extension (.vsix for Cursor, VS Code, Windsurf, Kiro, Antigravity)</span>
          </button>

          <button
            type="button"
            onClick={() => onOpenInstallModal ? onOpenInstallModal('desktop') : scrollToSection('feat-07-yours')}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-full bg-white hover:bg-zinc-50 border border-black/[0.1] text-zinc-900 text-xs sm:text-sm font-medium shadow-2xs transition-all cursor-pointer"
          >
            <Monitor className="w-4 h-4 text-zinc-600" />
            <span>Download Desktop (Flutter Windows / Mac / Linux)</span>
          </button>

          <button
            type="button"
            onClick={() => onOpenInstallModal ? onOpenInstallModal('daemon') : scrollToSection('feat-07-yours')}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-full bg-zinc-100 hover:bg-zinc-200 border border-black/[0.08] text-zinc-800 text-xs sm:text-sm font-mono font-medium transition-all cursor-pointer"
          >
            <Terminal className="w-3.5 h-3.5 text-zinc-500" />
            <span>Run Native Go Daemon (<code className="text-indigo-600 font-semibold">go run cmd/daemon/main.go</code>)</span>
          </button>
        </div>

        <div className="pt-1 flex flex-wrap items-center justify-center gap-3 text-[11.5px] text-zinc-500 font-medium">
          <span className="inline-flex items-center gap-1">
            <span className="w-2 h-2 rounded-full bg-emerald-500" />
            Native Go Daemon (&lt;4ms AST Slicing)
          </span>
          <span>·</span>
          <span className="inline-flex items-center gap-1">
            <ShieldCheck className="w-3.5 h-3.5 text-indigo-600" />
            Clerk RS256 Enterprise Security
          </span>
          <span>·</span>
          <span>8 Verified AI Environments</span>
        </div>
      </section>

      {/* =====================================================================
          01 · YOUR AGENTS (Video & Motion Presentations + 30-Day Activity Chart)
         ===================================================================== */}
      <section id="feat-01-agents" className="space-y-8 scroll-mt-24">
        <div className="space-y-2">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            01 · YOUR AGENTS
          </div>
          <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Bring your coding agent.
          </h2>
          <p className="text-base text-[#71717A]">
            Keep prompting in Antigravity, Claude Code, Cursor, Codex, or Kiro—then watch clean slices land in real time.
          </p>
        </div>

        {/* Card 1: Watch any agent work in its native IDE & CLI (Live Motion Stage) */}
        <div className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] space-y-5">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div className="space-y-1.5">
              <div className="text-[11px] font-mono uppercase tracking-[0.16em] text-zinc-500">
                NATIVE IDE &amp; CLI ENVIRONMENTS · {activeIdeShowcase.title}
              </div>
              <h3 className="text-2xl font-semibold text-[#1D1D1F]">
                Watch any agent work in its real IDE or CLI.
              </h3>
              <p className="text-sm text-[#71717A] max-w-2xl leading-relaxed">
                {activeIdeShowcase.subtitle}
              </p>
            </div>
            <button
              type="button"
              onClick={() => onSimulateLiveAgentTick(activeShowcaseAgent)}
              className="px-4 py-2 rounded-full bg-[#1D1D1F] hover:bg-black text-white text-xs font-semibold cursor-pointer shrink-0 self-start md:self-auto"
            >
              Simulate edit in {activeShowcaseAgent}
            </button>
          </div>

          {/* Native 8-IDE/CLI Live Motion Stage */}
          <LiveIdeOverlayVideoStage
            activeAgent={activeShowcaseAgent}
            onSelectAgent={setActiveShowcaseAgent}
            onTriggerLiveCommit={onSimulateLiveAgentTick}
          />
        </div>

        {/* Card 2: Otto learns your senior rules (Screen 10) */}
        <div className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] space-y-5">
          <div className="space-y-1.5">
            <h3 className="text-xl font-semibold text-[#1D1D1F]">
              Otto learns your senior rules
            </h3>
            <p className="text-sm text-[#71717A] max-w-2xl">
              Tell an agent your LOC cap or scope rules once, and Otto enforces it before every commit across every IDE.
            </p>
          </div>

          <div className="flex justify-end">
            <div className="bg-[#007AFF] text-white text-xs sm:text-sm font-medium px-4 py-2.5 rounded-2xl rounded-br-xs max-w-lg shadow-2xs">
              Cap every commit at {policy.maxLocPerCommit} LOC, isolate markdown brainstorm notes into docs(plans) commits, and require matching tests.
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] grid grid-cols-1 sm:grid-cols-3 gap-4 items-center">
            <div className="space-y-1">
              <label
                htmlFor="max-loc-slider"
                className="text-xs font-semibold text-[#1D1D1F] flex justify-between"
              >
                <span>Max LOC per Commit</span>
                <span className="font-mono text-indigo-600">
                  {policy.maxLocPerCommit} LOC
                </span>
              </label>
              <input
                id="max-loc-slider"
                type="range"
                min={40}
                max={200}
                step={10}
                value={policy.maxLocPerCommit}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    maxLocPerCommit: Number(e.target.value),
                  })
                }
                className="w-full accent-[#1D1D1F] cursor-pointer"
              />
            </div>

            <label className="flex items-center gap-2 text-xs text-zinc-700 cursor-pointer">
              <input
                type="checkbox"
                checked={policy.isolateBrainstormingDocs}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    isolateBrainstormingDocs: e.target.checked,
                  })
                }
              />
              <span>Isolate brainstorm &amp; plan docs</span>
            </label>

            <label className="flex items-center gap-2 text-xs text-zinc-700 cursor-pointer">
              <input
                type="checkbox"
                checked={policy.requireTestsForFeatFix}
                onChange={(e) =>
                  onUpdatePolicy({
                    ...policy,
                    requireTestsForFeatFix: e.target.checked,
                  })
                }
              />
              <span>Separate test specs into own PR</span>
            </label>
          </div>
        </div>

        {/* Card 3: See what your agents did (Screen 11 Activity Log) */}
        <div className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] space-y-5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <h3 className="text-xl font-semibold text-[#1D1D1F]">
              See what your agents did
            </h3>
            <p className="text-sm text-[#71717A]">
              Activity shows every hunk slice, Conventional Commit header, and PR push your connected agents made, with LOC count and review time.
            </p>
          </div>

          <div className="flex justify-end">
            <div className="bg-[#007AFF] text-white text-xs sm:text-sm font-medium px-4 py-2 rounded-2xl rounded-br-xs">
              Slice the webhook retry queue and push stacked PRs
            </div>
          </div>

          <div className="bg-white rounded-2xl border border-black/[0.06] p-5 space-y-3 shadow-2xs">
            <div className="text-xs font-semibold text-zinc-400">Today</div>
            <div className="divide-y divide-zinc-100">
              {allCommits.slice(0, 5).map((unit, idx) => (
                <div
                  key={unit.id}
                  className="py-3 flex flex-wrap items-center justify-between gap-3 text-xs"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="font-mono text-zinc-400 tabular-nums">
                      10:{24 - idx} PM
                    </span>
                    <AgentIcon
                      agentId={unit.sourceAgent || 'antigravity'}
                      sizeClass="w-6 h-6"
                      roundedClass="rounded-lg"
                    />
                    <div className="min-w-0">
                      <div className="font-mono font-semibold text-[#1D1D1F] truncate">
                        {unit.conventionalHeader}
                      </div>
                      <div className="text-[11px] text-zinc-400 font-mono">
                        Branch: {unit.branchName} · +{unit.totalAdditions}/-{unit.totalDeletions} ({unit.totalLoc} LOC)
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 font-mono text-zinc-500 shrink-0">
                    <span>{unit.sourceAgent || 'antigravity'}</span>
                    <span>{unit.reviewMinutes}m review</span>
                    <PrStatusBadge
                      status={unit.status}
                      prNumber={unit.prNumber}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Card 4: 30-Day Daily Activity Chart (Recharts) + Pushed PR Stack Status Board */}
        <div
          id="feat-30d-activity-chart"
          className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] space-y-6"
        >
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="space-y-1.5">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white text-xs font-mono text-zinc-700 shadow-2xs">
                <BarChart3 className="w-3.5 h-3.5 text-indigo-600" />
                <span>30-Day Velocity &amp; Cadence</span>
              </span>
              <h3 className="text-2xl font-semibold text-[#1D1D1F]">
                Daily atomic commits &amp; stacked PRs over the last 30 days
              </h3>
              <p className="text-sm text-[#71717A] max-w-xl">
                Consistent, modular daily commits automatically sliced while your coding agents work—eliminating end-of-week bulk PR dumps.
              </p>
            </div>

            {/* Range Selector (30d / 14d / 7d) */}
            <div
              role="group"
              aria-label="Activity chart time range"
              className="inline-flex items-center gap-1 p-1 rounded-full bg-white border border-black/[0.06] text-xs"
            >
              {([30, 14, 7] as const).map((days) => (
                <button
                  key={days}
                  type="button"
                  onClick={() => setChartWindowDays(days)}
                  className={`px-3 py-1 rounded-full font-semibold transition-colors cursor-pointer ${
                    chartWindowDays === days
                      ? 'bg-[#1D1D1F] text-white'
                      : 'text-zinc-600 hover:text-zinc-900'
                  }`}
                >
                  Last {days}d
                </button>
              ))}
            </div>
          </div>

          {/* 4 KPI Summary Metrics */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div className="bg-white rounded-2xl p-4 border border-black/[0.06] shadow-2xs">
              <div className="text-[11px] font-mono text-zinc-500">
                Atomic Commits ({chartWindowDays}d)
              </div>
              <div className="text-2xl font-semibold text-[#1D1D1F] mt-0.5 tabular-nums">
                {cadenceSummary.totalCommits}
              </div>
              <div className="text-[11px] text-indigo-600 font-mono mt-0.5">
                Peak: {cadenceSummary.peakDayCommits} on {cadenceSummary.peakDayLabel}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-4 border border-black/[0.06] shadow-2xs">
              <div className="text-[11px] font-mono text-zinc-500">
                Stacked PRs ({chartWindowDays}d)
              </div>
              <div className="text-2xl font-semibold text-[#1D1D1F] mt-0.5 tabular-nums">
                {cadenceSummary.totalStackedPrs}
              </div>
              <div className="text-[11px] text-emerald-700 font-mono mt-0.5">
                100% chained cleanly
              </div>
            </div>

            <div className="bg-white rounded-2xl p-4 border border-black/[0.06] shadow-2xs">
              <div className="text-[11px] font-mono text-zinc-500">
                Avg Commit Size
              </div>
              <div className="text-2xl font-semibold text-[#1D1D1F] mt-0.5 tabular-nums">
                {cadenceSummary.avgLocPerCommit} LOC
              </div>
              <div className="text-[11px] text-zinc-500 font-mono mt-0.5">
                Cap ≤ {policy.maxLocPerCommit} LOC
              </div>
            </div>

            <div className="bg-white rounded-2xl p-4 border border-black/[0.06] shadow-2xs">
              <div className="text-[11px] font-mono text-zinc-500">
                Bulk Dumps Prevented
              </div>
              <div className="text-2xl font-semibold text-[#1D1D1F] mt-0.5 tabular-nums">
                {cadenceSummary.totalBulkPrevented}
              </div>
              <div className="text-[11px] text-amber-700 font-mono mt-0.5">
                Auto-sliced in IDE
              </div>
            </div>
          </div>

          {/* Recharts 30-Day Daily Activity Chart */}
          <div className="bg-white rounded-2xl border border-black/[0.06] p-4 sm:p-6 shadow-2xs space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
              <span className="font-semibold text-[#1D1D1F]">
                30-Day Atomic Commits vs. Stacked PRs Completed
              </span>
              <span className="font-mono text-[11px] text-zinc-400">
                Oct 8 – Nov 6, 2026 · Auto-updated on every agent commit
              </span>
            </div>

            <div
              className="w-full h-72"
              data-testid="recharts-daily-activity-container"
            >
              <ResponsiveContainer width="100%" height="100%">
                <ComposedChart
                  data={cadenceSlice}
                  margin={{ top: 10, right: 12, left: -16, bottom: 0 }}
                >
                  <defs>
                    <linearGradient
                      id="atomicCommitsGrad"
                      x1="0"
                      y1="0"
                      x2="0"
                      y2="1"
                    >
                      <stop
                        offset="5%"
                        stopColor="#6366F1"
                        stopOpacity={0.32}
                      />
                      <stop
                        offset="95%"
                        stopColor="#6366F1"
                        stopOpacity={0.02}
                      />
                    </linearGradient>
                  </defs>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                    stroke="#E4E4E7"
                  />
                  <XAxis
                    dataKey="label"
                    tick={{ fontSize: 11, fill: '#71717A' }}
                    tickLine={false}
                    axisLine={{ stroke: '#E4E4E7' }}
                    interval={chartWindowDays === 30 ? 3 : 0}
                  />
                  <YAxis
                    tick={{ fontSize: 11, fill: '#71717A' }}
                    tickLine={false}
                    axisLine={false}
                    allowDecimals={false}
                  />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#FFFFFF',
                      borderRadius: '14px',
                      border: '1px solid rgba(0,0,0,0.08)',
                      boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
                      fontSize: '12px',
                    }}
                  />
                  <Legend
                    wrapperStyle={{ fontSize: '12px', paddingTop: '8px' }}
                  />
                  <Area
                    type="monotone"
                    dataKey="atomicCommitsCount"
                    name="Atomic Commits"
                    stroke="#4F46E5"
                    strokeWidth={2.5}
                    fillOpacity={1}
                    fill="url(#atomicCommitsGrad)"
                  />
                  <Bar
                    dataKey="prsStackedCount"
                    name="Stacked PRs"
                    fill="#10B981"
                    radius={[6, 6, 0, 0]}
                    barSize={chartWindowDays === 30 ? 10 : 18}
                  />
                </ComposedChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Pushed PR Stack List with Visual Status Indicators ('Open', 'Merged', 'Draft') */}
          <div className="bg-white rounded-2xl border border-black/[0.06] p-5 shadow-2xs space-y-4">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h4 className="text-base font-semibold text-[#1D1D1F]">
                  Pushed PR Stack Status Board
                </h4>
                <p className="text-xs text-zinc-500">
                  Color-coded status indicators (Open, Merged, Draft) for every stacked PR branch.
                </p>
              </div>

              <div
                role="group"
                aria-label="Filter pushed PR stack by status"
                className="inline-flex items-center gap-1 p-1 rounded-full bg-[#EFECE6] text-xs"
              >
                {(
                  [
                    { id: 'all', label: 'All' },
                    { id: 'open', label: 'Open' },
                    { id: 'merged', label: 'Merged' },
                    { id: 'draft', label: 'Draft' },
                  ] as const
                ).map((tab) => (
                  <button
                    key={tab.id}
                    type="button"
                    onClick={() => setPushedFilter(tab.id)}
                    className={`px-3 py-1 rounded-full font-medium transition-colors cursor-pointer ${
                      pushedFilter === tab.id
                        ? 'bg-white text-[#1D1D1F] shadow-2xs'
                        : 'text-zinc-600 hover:text-zinc-900'
                    }`}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>
            </div>

            <div className="divide-y divide-zinc-100">
              {pushedStack
                .filter((pr) => {
                  if (pushedFilter === 'all') return true;
                  if (pushedFilter === 'open')
                    return pr.status === 'pr_open' || pr.status === 'pushed';
                  if (pushedFilter === 'merged') return pr.status === 'merged';
                  return pr.status === 'draft' || pr.status === 'staged';
                })
                .map((pr, idx) => (
                  <div
                    key={pr.id}
                    className="py-3.5 flex flex-wrap items-center justify-between gap-3"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <AgentIcon
                        agentId={pr.sourceAgent || 'antigravity'}
                        sizeClass="w-8 h-8"
                        roundedClass="rounded-xl"
                      />
                      <div className="min-w-0 space-y-0.5">
                        <div className="flex flex-wrap items-center gap-2">
                          <span className="text-xs font-mono font-semibold text-[#1D1D1F] truncate">
                            {pr.conventionalHeader}
                          </span>
                        </div>
                        <div className="flex flex-wrap items-center gap-2 text-[11px] font-mono text-zinc-400">
                          <span>
                            {pr.parentBranch} ← {pr.branchName}
                          </span>
                          <span>·</span>
                          <span className="text-emerald-700 font-medium">
                            +{pr.totalAdditions}/-{pr.totalDeletions} ({pr.totalLoc} LOC)
                          </span>
                          <span>·</span>
                          <span>{pr.reviewMinutes}m review</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2.5 shrink-0">
                      <PrStatusBadge
                        status={pr.status}
                        prNumber={pr.prNumber || 141 + idx}
                        size="sm"
                      />
                      {pr.status === 'draft' && onPromoteDraftPr && (
                        <button
                          type="button"
                          onClick={() => onPromoteDraftPr(pr.id)}
                          className="px-3 py-1 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold cursor-pointer"
                        >
                          Mark Open
                        </button>
                      )}
                      {pr.status === 'pr_open' && (
                        <button
                          type="button"
                          onClick={() => onMergeTopPr(pr.id)}
                          className="px-3 py-1 rounded-full bg-[#1D1D1F] hover:bg-black text-white text-xs font-semibold cursor-pointer"
                        >
                          Merge PR
                        </button>
                      )}
                    </div>
                  </div>
                ))}
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          02 · CAPTURE (Screens 12–13: From messy working tree to finished slice)
         ===================================================================== */}
      <section id="feat-02-capture" className="space-y-8 scroll-mt-24">
        <div className="space-y-2">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            02 · CAPTURE
          </div>
          <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            From file save to finished PR.
          </h2>
          <p className="text-base text-[#71717A] max-w-xl">
            Your agent edits files in the IDE or CLI and Otto captures every AST hunk automatically—keeping your raw working tree safe while building clean slices.
          </p>
        </div>

        <div className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
          <div className="lg:col-span-5 space-y-3">
            <span className="inline-block px-3 py-1 rounded-full bg-white text-xs font-mono text-zinc-700">
              Live Hunks ({workingTreeHunks.length})
            </span>
            <h3 className="text-2xl font-semibold text-[#1D1D1F]">
              The original diff, kept intact
            </h3>
            <p className="text-sm text-[#71717A] leading-relaxed">
              Every file edit starts as a clean AST capture. Refine commit messages with AI or split multi-file slices in one click.
            </p>
            <div className="pt-2 flex flex-wrap gap-2">
              <button
                type="button"
                onClick={onRefineWithAi}
                disabled={isRefiningAi}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#1D1D1F] text-white text-xs font-semibold cursor-pointer disabled:opacity-50"
              >
                <Sparkles className="w-3.5 h-3.5 text-amber-400" />
                <span>{isRefiningAi ? 'Refining...' : 'AI Refine Headers'}</span>
              </button>
              {stagedAtomicStack.length > 0 && (
                <button
                  type="button"
                  onClick={onPushAllStaged}
                  className="px-4 py-2 rounded-full bg-white border border-black/10 text-xs font-semibold text-[#1D1D1F] cursor-pointer"
                >
                  Push All ({stagedAtomicStack.length})
                </button>
              )}
            </div>
          </div>

          <div className="lg:col-span-7 bg-white rounded-2xl border border-black/[0.06] shadow-xs overflow-hidden">
            {/* Native Desktop / IDE Extension Top Bar with Real-Time GitHub Sync Indicator */}
            <div className="px-4 py-2.5 bg-[#FAF8F5] border-b border-black/[0.06] flex flex-wrap items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
                <span className="text-[11px] font-mono font-semibold text-zinc-700 ml-1">
                  IDE Extension Top Bar · Live GitHub Sync
                </span>
              </div>

              <NavbarGitHubSyncStatus
                githubConfig={githubConfig}
                stagedAtomicStack={stagedAtomicStack}
                pushedStack={pushedStack}
                daemonActive={daemonActive}
                onPushAllStaged={onPushAllStaged}
                onPromoteDraftPr={onPromoteDraftPr || (() => {})}
                onChangeBaseBranch={onChangeBaseBranch || (() => {})}
                onNavigateToStack={() => scrollToSection('feat-30d-activity-chart')}
              />
            </div>

            <div className="p-4 space-y-2.5">
              {workingTreeHunks.length === 0 ? (
                <div className="py-8 text-center text-xs text-zinc-500">
                  All working-tree hunks have been sliced and pushed! Click any agent above to simulate new edits.
                </div>
              ) : (
                workingTreeHunks.slice(0, 4).map((hunk) => (
                  <div
                    key={hunk.id}
                    className="p-3 rounded-xl bg-[#FAF9F5] border border-black/[0.05] flex items-center justify-between gap-2 text-xs font-mono"
                  >
                    <div className="truncate">
                      <div className="font-semibold text-[#1D1D1F] truncate">
                        {hunk.filePath}
                      </div>
                      <div className="text-[11px] text-zinc-500 font-sans truncate">
                        {hunk.summary}
                      </div>
                    </div>
                    <span className="shrink-0 text-[11px]">
                      <span className="text-emerald-700 font-semibold">
                        +{hunk.additions}
                      </span>{' '}
                      /{' '}
                      <span className="text-rose-700 font-semibold">
                        -{hunk.deletions}
                      </span>
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          03 · STYLE & STACK (Screens 14–17: Desktop + Mobile side-by-side)
         ===================================================================== */}
      <section id="feat-03-style" className="space-y-8 scroll-mt-24">
        <div className="space-y-2">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            03 · STYLE &amp; STACK
          </div>
          <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Finished PR stacks from one sentence.
          </h2>
          <p className="text-base text-[#71717A] max-w-xl">
            Ask your agent for a feature in plain English. Branches, Conventional Commit headers, and desktop + mobile PR previews land together.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {/* Left Card: Lift the one hunk that matters */}
          <div className="rounded-[28px] bg-[#EFECE6] p-6 border border-black/[0.05] flex flex-col justify-between space-y-4">
            <div className="space-y-1.5">
              <h3 className="text-xl font-semibold text-[#1D1D1F]">
                Lift the one hunk that matters
              </h3>
              <p className="text-xs sm:text-sm text-[#71717A]">
                The rest of the working tree steps back and the hotfix hunk floats into its own priority PR so reviewers can merge it in 60 seconds.
              </p>
            </div>

            <div className="flex justify-end">
              <div className="bg-[#007AFF] text-white text-xs font-medium px-3.5 py-1.5 rounded-2xl rounded-br-xs">
                Isolate the cookie expiry hotfix into PR #1
              </div>
            </div>

            <div className="rounded-2xl bg-gradient-to-br from-[#DBEAFE] to-[#EDE9FE] p-4 border border-black/[0.06]">
              <div className="bg-white rounded-xl p-3.5 shadow-md border border-indigo-500/30 space-y-1">
                <div className="flex justify-between text-[10px] font-mono text-indigo-600 font-bold">
                  <span>PRIORITY SLICE · 34 LOC</span>
                  <span>1m review</span>
                </div>
                <div className="text-xs font-mono font-bold text-[#1D1D1F]">
                  fix(cookie): enforce SameSite lax maxAge bounds
                </div>
              </div>
            </div>
          </div>

          {/* Right Card: Desktop & Mobile in one shot (Screen 16) */}
          <div className="rounded-[28px] bg-[#EFECE6] p-6 border border-black/[0.05] flex flex-col justify-between space-y-4">
            <div className="space-y-1.5">
              <h3 className="text-xl font-semibold text-[#1D1D1F]">
                Desktop and mobile in one flow
              </h3>
              <p className="text-xs sm:text-sm text-[#71717A]">
                Code in your Mac IDE and approve or merge stacked PRs from the iPhone companion app while away from your desk.
              </p>
            </div>

            <div className="flex justify-end">
              <div className="bg-[#007AFF] text-white text-xs font-medium px-3.5 py-1.5 rounded-2xl rounded-br-xs">
                Sync stacked PRs to Mac IDE and iPhone companion
              </div>
            </div>

            <div className="rounded-2xl bg-gradient-to-br from-[#E4E9E2] via-[#DBEAFE] to-[#EDE9FE] p-4 border border-black/[0.06] flex items-end gap-3">
              {/* Mac Window */}
              <div className="flex-1 bg-white rounded-xl p-3 border border-black/10 shadow-sm space-y-1.5">
                <div className="flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-rose-400" />
                  <span className="w-2 h-2 rounded-full bg-amber-400" />
                  <span className="w-2 h-2 rounded-full bg-emerald-400" />
                  <span className="text-[10px] font-mono text-zinc-400 ml-1">
                    Mac IDE Overlay
                  </span>
                </div>
                <div className="text-[11px] font-mono font-semibold text-[#1D1D1F] truncate">
                  stack/01-feat-payment
                </div>
                <div className="text-[10px] text-emerald-700 font-mono">
                  ✓ Auto-committed 54 LOC
                </div>
              </div>

              {/* iPhone Companion */}
              <div className="w-32 bg-[#1D1D1F] text-white rounded-2xl p-2.5 shadow-lg space-y-1.5 shrink-0">
                <div className="w-8 h-1 bg-zinc-700 rounded-full mx-auto" />
                <div className="text-[9px] font-mono text-zinc-400 flex items-center gap-1">
                  <Smartphone className="w-2.5 h-2.5" />
                  <span>iOS Review</span>
                </div>
                <div className="text-[10px] font-semibold leading-tight">
                  PR #142 Ready
                </div>
                <div className="text-[9px] bg-emerald-500 text-black font-bold text-center py-0.5 rounded-full">
                  Tap to Merge
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          04 · SLICE AND CUT (Screens 18–20: Multi-Track Commit Beats Timeline)
         ===================================================================== */}
      <section id="feat-04-cut" className="space-y-8 scroll-mt-24">
        <div className="space-y-2">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            04 · SLICE AND CUT
          </div>
          <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Edit a commit stack in beats.
          </h2>
          <p className="text-base text-[#71717A] max-w-xl">
            Every coding session is laid out as named atomic beats sized by LOC. Click any beat on the timeline to inspect, split hunks, or merge its PR.
          </p>
        </div>

        <div className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] space-y-5">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div>
              <h3 className="text-xl font-semibold text-[#1D1D1F]">
                Every track when you want it
              </h3>
              <p className="text-xs sm:text-sm text-[#71717A]">
                Commits, scopes, LOC budgets, and PR numbers lined up on one axis.
              </p>
            </div>
            <div className="bg-[#007AFF] text-white text-xs font-medium px-3.5 py-1.5 rounded-2xl rounded-br-xs">
              Split C2 at 80 LOC and chain PRs
            </div>
          </div>

          {/* Moonjar Timeline Track UI (Screen 20) */}
          <div className="bg-white rounded-2xl border border-black/[0.07] p-5 shadow-xs space-y-4">
            {/* Selected Beat Detail Bar */}
            {activeBeat && (
              <div className="p-3.5 rounded-xl bg-[#FAF9F5] border border-black/[0.06] flex flex-wrap items-center justify-between gap-3">
                <div className="space-y-0.5">
                  <div className="text-[11px] font-mono text-indigo-600 font-semibold">
                    Beat C{selectedBeatIdx + 1} · {activeBeat.branchName} · {activeBeat.totalLoc} LOC
                  </div>
                  <div className="text-xs sm:text-sm font-mono font-bold text-[#1D1D1F]">
                    {activeBeat.conventionalHeader}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {activeBeat.status === 'staged' && activeBeat.hunks.length > 1 && (
                    <button
                      type="button"
                      onClick={() =>
                        onSplitCommit(
                          activeBeat.id,
                          activeBeat.hunks[activeBeat.hunks.length - 1].id
                        )
                      }
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full bg-white border border-black/10 text-xs font-medium text-[#1D1D1F] cursor-pointer"
                    >
                      <Scissors className="w-3 h-3" />
                      <span>Split Beat</span>
                    </button>
                  )}
                  {activeBeat.status === 'staged' ? (
                    <button
                      type="button"
                      onClick={() => onPushSingleCommit(activeBeat.id)}
                      className="inline-flex items-center gap-1 px-3.5 py-1.5 rounded-full bg-[#1D1D1F] text-white text-xs font-semibold cursor-pointer"
                    >
                      <GitCommit className="w-3 h-3" />
                      <span>Commit &amp; PR</span>
                    </button>
                  ) : activeBeat.status === 'pr_open' ? (
                    <button
                      type="button"
                      onClick={() => onMergeTopPr(activeBeat.id)}
                      className="inline-flex items-center gap-1 px-3.5 py-1.5 rounded-full bg-emerald-600 text-white text-xs font-semibold cursor-pointer"
                    >
                      <GitMerge className="w-3 h-3" />
                      <span>Merge PR #{activeBeat.prNumber || 142}</span>
                    </button>
                  ) : null}
                </div>
              </div>
            )}

            {/* Multi-Track Axis */}
            <div className="space-y-2.5 text-xs font-mono">
              <div className="grid grid-cols-12 gap-2 items-center">
                <div className="col-span-2 text-[11px] text-zinc-400">Commits</div>
                <div className="col-span-10 grid grid-cols-2 sm:grid-cols-5 gap-2">
                  {allCommits.slice(0, 5).map((c, idx) => (
                    <button
                      key={c.id}
                      type="button"
                      onClick={() => setSelectedBeatIdx(idx)}
                      className={`p-2 rounded-lg border text-left transition-all cursor-pointer truncate ${
                        selectedBeatIdx === idx
                          ? 'bg-[#1D1D1F] text-white border-[#1D1D1F]'
                          : 'bg-[#F3F2EE] text-[#1D1D1F] border-black/[0.06] hover:bg-zinc-200/70'
                      }`}
                    >
                      <span className="font-bold">C{idx + 1}</span> · {c.totalLoc} LOC
                    </button>
                  ))}
                </div>
              </div>

              <div className="grid grid-cols-12 gap-2 items-center">
                <div className="col-span-2 text-[11px] text-zinc-400">Scopes</div>
                <div className="col-span-10 grid grid-cols-2 sm:grid-cols-5 gap-2">
                  {allCommits.slice(0, 5).map((c) => (
                    <div
                      key={c.id}
                      className="px-2 py-1 rounded bg-indigo-50 text-indigo-700 text-[11px] truncate border border-indigo-200/60"
                    >
                      {c.type}({c.scope})
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          05 · TIME MACHINE (Screen 21 + Real Time Machine Video Presentation)
         ===================================================================== */}
      <section id="feat-05-timemachine" className="space-y-6 scroll-mt-24">
        <div className="space-y-2">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            05 · TIME MACHINE
          </div>
          <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Every version, one scrub away.
          </h2>
          <p className="text-base text-[#71717A] max-w-xl">
            Every atomic slice and stacked PR keeps its full history. Flip back through checkpoints, see which agent changed what, or reset the demo stack.
          </p>
        </div>

        <div className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] space-y-6">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-6">
            <div className="space-y-2">
              <div className="text-xs font-mono text-zinc-500">
                Active Checkpoint #{selectedHistoryIdx + 1} of {allCommits.length}
              </div>
              <div className="text-lg font-mono font-bold text-[#1D1D1F]">
                {activeHistoryUnit?.conventionalHeader}
              </div>
              <div className="text-xs text-zinc-600">
                Compliance Score: {activeHistoryUnit?.complianceScore || 100}% · Agent: {activeHistoryUnit?.sourceAgent || 'antigravity'}
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2 shrink-0">
              {allCommits.slice(0, 5).map((u, idx) => (
                <button
                  key={u.id}
                  type="button"
                  onClick={() => setSelectedHistoryIdx(idx)}
                  className={`w-9 h-9 rounded-xl font-mono text-xs font-bold cursor-pointer ${
                    selectedHistoryIdx === idx
                      ? 'bg-[#1D1D1F] text-white'
                      : 'bg-white text-zinc-700 border border-black/10'
                  }`}
                >
                  v{idx + 1}
                </button>
              ))}
              <button
                type="button"
                onClick={onResetDemo}
                className="px-3.5 py-2 rounded-xl bg-white hover:bg-zinc-100 border border-black/10 text-xs font-semibold text-zinc-800 cursor-pointer"
              >
                Reset Stack
              </button>
            </div>
          </div>

          {/* Custom-Tailored AtomikGit Time Machine Checkpoint & Diff Scrubber */}
          <div className="rounded-2xl overflow-hidden border border-black/[0.08] bg-white shadow-sm grid grid-cols-1 lg:grid-cols-12">
            {/* Left 8 Cols: Active Checkpoint IDE Diff & PR Stack Snapshot */}
            <div className="lg:col-span-8 p-5 bg-[#FAF9F5] flex flex-col justify-between space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-2 px-3.5 py-2 rounded-xl bg-[#1D1D1F] text-white text-xs">
                <span>
                  Viewing checkpoint{' '}
                  <strong className="font-mono text-amber-300">
                    v{selectedHistoryIdx + 1} · {activeHistoryUnit?.branchName}
                  </strong>
                </span>
                <PrStatusBadge
                  status={activeHistoryUnit?.status || 'pr_open'}
                  prNumber={activeHistoryUnit?.prNumber || 141 + selectedHistoryIdx}
                />
              </div>

              <div className="rounded-2xl bg-gradient-to-br from-[#EDE9FE] via-[#DBEAFE] to-[#E0F2FE] p-4 border border-black/[0.06] space-y-3">
                <div className="bg-white rounded-xl p-4 border border-black/[0.07] shadow-xs space-y-2.5 font-mono text-xs">
                  <div className="flex items-center justify-between text-[11px] text-zinc-500">
                    <span>
                      Agent: {activeHistoryUnit?.sourceAgent || 'antigravity'} ·
                      Parent: {activeHistoryUnit?.parentBranch || 'main'}
                    </span>
                    <span className="text-emerald-700 font-semibold">
                      +{activeHistoryUnit?.totalAdditions || 54} / -
                      {activeHistoryUnit?.totalDeletions || 9} (
                      {activeHistoryUnit?.totalLoc || 63} LOC)
                    </span>
                  </div>
                  <div className="text-sm font-bold text-[#1D1D1F]">
                    {activeHistoryUnit?.conventionalHeader}
                  </div>
                  <div className="space-y-1 pt-1 border-t border-zinc-100 text-[11px]">
                    {(activeHistoryUnit?.hunks || []).slice(0, 2).map((h) => (
                      <div
                        key={h.id}
                        className="px-2.5 py-1 rounded bg-emerald-50/80 text-emerald-900 flex items-center justify-between"
                      >
                        <span className="truncate">+ {h.filePath}</span>
                        <span className="shrink-0 font-semibold">
                          +{h.additions}/-{h.deletions}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between text-xs font-mono text-zinc-500 px-1">
                <span>
                  ✓ Compliance: {activeHistoryUnit?.complianceScore || 100}%
                  single-scope verified
                </span>
                <span>Est. review: {activeHistoryUnit?.reviewMinutes || 1}m</span>
              </div>
            </div>

            {/* Right 4 Cols: Time Machine Version List */}
            <div className="lg:col-span-4 p-4 bg-white border-t lg:border-t-0 lg:border-l border-black/[0.06] space-y-2.5">
              <div className="text-[11px] font-mono uppercase tracking-wider text-zinc-400 font-semibold">
                Stack History ({allCommits.slice(0, 5).length} checkpoints)
              </div>
              {allCommits.slice(0, 5).map((unit, idx) => {
                const isSelected = selectedHistoryIdx === idx;
                return (
                  <button
                    key={unit.id}
                    type="button"
                    onClick={() => setSelectedHistoryIdx(idx)}
                    className={`w-full text-left p-2.5 rounded-xl border transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-[#F5F3FF] border-indigo-500 ring-1 ring-indigo-500/20'
                        : 'bg-[#FAF9F5] border-black/[0.05] hover:bg-zinc-100/70'
                    }`}
                  >
                    <div className="flex items-center justify-between text-[11px] font-mono">
                      <span className="font-bold text-[#1D1D1F]">
                        v{idx + 1} · {unit.sourceAgent || 'antigravity'}
                      </span>
                      <span className="text-emerald-700 font-semibold">
                        {unit.totalLoc} LOC
                      </span>
                    </div>
                    <div className="text-[11px] font-mono text-zinc-700 truncate mt-0.5">
                      {unit.conventionalHeader}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          06 · ORGANIZE AND FIND (Screen 27 Search + Metadata Popover)
         ===================================================================== */}
      <section id="feat-06-organize" className="space-y-6 scroll-mt-24">
        <div className="space-y-2">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            06 · ORGANIZE AND FIND
          </div>
          <h2 className="text-3xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Find any commit, file, or prompt in plain English.
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {/* Search Box Card */}
          <div className="rounded-[28px] bg-[#EFECE6] p-6 border border-black/[0.05] space-y-4">
            <div className="flex justify-end">
              <div className="bg-[#007AFF] text-white text-xs font-medium px-3.5 py-1.5 rounded-2xl rounded-br-xs">
                Find everything touching payment webhooks
              </div>
            </div>

            <div className="bg-white rounded-2xl p-4 border border-black/[0.06] space-y-3 shadow-2xs">
              <div className="flex items-center gap-2 px-3 py-2 rounded-xl bg-[#FAF9F5] border border-black/[0.07]">
                <Search className="w-4 h-4 text-zinc-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search payment, auth, ledger, plans..."
                  className="w-full text-xs bg-transparent focus:outline-none text-[#1D1D1F]"
                />
              </div>

              <div className="space-y-1.5 max-h-48 overflow-y-auto">
                {filteredCommits.slice(0, 4).map((c) => (
                  <div
                    key={c.id}
                    className="p-2.5 rounded-xl hover:bg-[#FAF9F5] flex items-center justify-between text-xs border border-transparent hover:border-black/[0.05]"
                  >
                    <div className="truncate pr-2">
                      <div className="font-mono font-semibold text-[#1D1D1F] truncate">
                        {c.conventionalHeader}
                      </div>
                      <div className="text-[10px] text-zinc-400 font-mono">
                        {c.branchName} · {c.totalLoc} LOC
                      </div>
                    </div>
                    <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-zinc-100 text-zinc-700 shrink-0">
                      {c.scope}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Inspector Metadata Card */}
          <div className="rounded-[28px] bg-[#EFECE6] p-6 border border-black/[0.05] space-y-4">
            <div className="flex justify-end">
              <div className="bg-[#007AFF] text-white text-xs font-medium px-3.5 py-1.5 rounded-2xl rounded-br-xs">
                What branch was this sliced from?
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 border border-black/[0.06] space-y-3 shadow-2xs text-xs">
              <div className="font-semibold text-[#1D1D1F] text-sm">
                {activeBeat?.conventionalHeader}
              </div>
              <div className="grid grid-cols-2 gap-y-2 text-zinc-500 font-mono text-[11px]">
                <span>Parent branch</span>
                <span className="text-[#1D1D1F]">
                  {activeBeat?.parentBranch || 'main'}
                </span>
                <span>Head branch</span>
                <span className="text-[#1D1D1F]">{activeBeat?.branchName}</span>
                <span>Line budget</span>
                <span className="text-[#1D1D1F]">
                  +{activeBeat?.totalAdditions} / -{activeBeat?.totalDeletions} ({activeBeat?.totalLoc} LOC)
                </span>
                <span>Platforms</span>
                <span className="text-[#1D1D1F]">Desktop IDE + Mobile App</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          07 · MAKE IT YOURS (Centralized IDE Hotkey Manager + Appearance + CLI Setup)
         ===================================================================== */}
      <section id="feat-07-yours" className="space-y-8 scroll-mt-24">
        <div className="space-y-2">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            07 · MAKE IT YOURS
          </div>
          <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Look around and make it yours.
          </h2>
          <p className="text-base text-[#71717A] max-w-xl">
            Customize global IDE shortcuts, choose how Otto moves, and connect your IDE or CLI in one command.
          </p>
        </div>

        {/* Native Desktop & IDE Extension Centralized Hotkey Manager + Floating Overlay Queue Stage */}
        <div id="feat-ide-hotkeys" className="scroll-mt-24">
          <IdeHotkeyOverlayShowcase
            bindings={hotkeyBindings}
            onUpdateBindings={onUpdateHotkeyBindings || (() => {})}
            stagedAtomicStack={stagedAtomicStack}
            pushedStack={pushedStack}
            githubConfig={githubConfig}
            daemonActive={daemonActive}
            lastTriggeredShortcut={lastTriggeredShortcut}
            onTriggerHotkeyAction={onTriggerHotkeyAction || (() => {})}
            onPushSingleCommit={onPushSingleCommit}
            onPushAllStaged={onPushAllStaged}
            onPromoteDraftPr={onPromoteDraftPr}
            onChangeBaseBranch={onChangeBaseBranch}
          />
        </div>

        <div className="rounded-[28px] bg-[#EFECE6] p-6 sm:p-8 border border-black/[0.05] grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          <div className="lg:col-span-5 space-y-4">
            <h3 className="text-xl font-semibold text-[#1D1D1F]">
              Motion, app icon &amp; CLI daemon
            </h3>
            <p className="text-sm text-[#71717A] leading-relaxed">
              Pick how much the overlay animates (Full, Calm, or Still), switch Otto’s icon from Meadow to Starry Night or Ceramic, and copy the one-line daemon installer.
            </p>

            <div className="p-4 rounded-2xl bg-white border border-black/[0.06] space-y-2">
              <div className="flex items-center justify-between text-xs">
                <span className="font-semibold text-[#1D1D1F]">
                  Universal IDE &amp; CLI Daemon
                </span>
                <button
                  type="button"
                  onClick={handleCopyCli}
                  className="inline-flex items-center gap-1 text-indigo-600 font-semibold cursor-pointer"
                >
                  <Copy className="w-3 h-3" />
                  <span>{copiedCmd ? 'Copied!' : 'Copy command'}</span>
                </button>
              </div>
              <pre className="text-[11px] font-mono bg-[#FAF9F5] p-2.5 rounded-xl overflow-x-auto text-zinc-800 border border-black/[0.05]">
                {cliInstallCommand}
              </pre>
              <div className="text-[10px] font-mono text-zinc-400 truncate">
                MCP &amp; Extension config: {extensionBundle.mcpConfigJson.length} bytes ready
              </div>
            </div>
          </div>

          {/* Right Card: Moonjar Appearance Selector (Screen 25) */}
          <div className="lg:col-span-7 bg-white rounded-2xl p-6 border border-black/[0.06] shadow-xs space-y-5">
            <div>
              <h4 className="text-base font-semibold text-[#1D1D1F]">
                Appearance
              </h4>
              <p className="text-xs text-zinc-500">
                How Otto moves, and the icon it wears in the Dock &amp; Mobile Home Screen.
              </p>
            </div>

            <div className="flex items-center justify-between pt-2 border-t border-zinc-100">
              <div>
                <div className="text-xs font-semibold text-[#1D1D1F]">Motion</div>
                <div className="text-[11px] text-zinc-500">
                  {motionMode} transitions across desktop and mobile sheets.
                </div>
              </div>
              <div className="inline-flex p-1 rounded-full bg-[#EFECE6] text-xs">
                {(['Full', 'Calm', 'Still'] as const).map((m) => (
                  <button
                    key={m}
                    type="button"
                    onClick={() => setMotionMode(m)}
                    className={`px-3 py-1 rounded-full font-medium cursor-pointer ${
                      motionMode === m
                        ? 'bg-white text-[#1D1D1F] shadow-2xs'
                        : 'text-zinc-600'
                    }`}
                  >
                    {m}
                  </button>
                ))}
              </div>
            </div>

            <div className="space-y-2 pt-2 border-t border-zinc-100">
              <div className="text-xs font-semibold text-[#1D1D1F]">App icon</div>
              <div className="space-y-1.5">
                {[
                  {
                    id: 'meadow',
                    name: 'Meadow Sky',
                    grad: 'from-[#60A5FA] via-[#BAE6FD] to-[#86EFAC]',
                  },
                  {
                    id: 'ceramic',
                    name: 'Ceramic Blossom',
                    grad: 'from-[#FDE68A] via-[#FCA5A5] to-[#FDBA74]',
                  },
                  {
                    id: 'starry',
                    name: 'Starry Night',
                    grad: 'from-[#1E1B4B] via-[#312E81] to-[#F59E0B]',
                  },
                  {
                    id: 'obsidian',
                    name: 'Obsidian Terminal',
                    grad: 'from-[#18181B] via-[#27272A] to-[#52525B]',
                  },
                ].map((ico) => (
                  <button
                    key={ico.id}
                    type="button"
                    onClick={() => onChangeAppIconStyle(ico.id)}
                    className={`w-full flex items-center justify-between p-2.5 rounded-xl border text-xs font-medium cursor-pointer transition-colors ${
                      appIconStyle === ico.id
                        ? 'bg-[#EFECE6]/70 border-zinc-900 text-[#1D1D1F]'
                        : 'bg-white hover:bg-zinc-50 border-zinc-100 text-zinc-600'
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <span
                        className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                          appIconStyle === ico.id
                            ? 'border-indigo-600 bg-indigo-600 text-white'
                            : 'border-zinc-300'
                        }`}
                      >
                        {appIconStyle === ico.id && (
                          <span className="w-1.5 h-1.5 rounded-full bg-white" />
                        )}
                      </span>
                      <span>{ico.name}</span>
                    </div>
                    <OttoLogo
                      sizeClass="w-7 h-7"
                      roundedClass="rounded-lg"
                      gradientClass={`bg-gradient-to-b ${ico.grad}`}
                    />
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-center pt-4">
          <button
            type="button"
            onClick={scrollToTop}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-white border border-black/[0.08] text-xs font-medium text-zinc-600 hover:text-zinc-900 shadow-2xs cursor-pointer"
          >
            <ArrowUp className="w-3.5 h-3.5" />
            <span>Back to top</span>
          </button>
        </div>
      </section>
    </div>
  );
};
