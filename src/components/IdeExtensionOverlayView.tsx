import React, { useEffect, useState } from 'react';
import {
  AtomicCommitUnit,
  DiffHunk,
  GitHubConnectionConfig,
  GuardrailPolicy,
  IdeAgentProfile,
  IdeHostId,
} from '../types/git';
import { parseRawPatchOrPromptInput } from '../utils/atomicEngine';
import { AGENT_ICON_ASSETS, AgentIcon, OttoLogo } from './AgentIcon';
import { CustomIdeOverlayShowcase } from './LiveIdeOverlayVideoStage';
import { PrStatusBadge } from './PrStatusBadge';
import {
  AlertCircle,
  Check,
  CheckCircle2,
  ChevronRight,
  FolderGit2,
  GitBranch,
  Maximize2,
  PanelLeft,
  Plus,
} from 'lucide-react';

interface IdeExtensionOverlayViewProps {
  ideProfiles: IdeAgentProfile[];
  selectedIde: IdeHostId | 'all';
  onSelectIde: (ide: IdeHostId | 'all') => void;
  workingTreeHunks: DiffHunk[];
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  daemonActive: boolean;
  onToggleDaemon: () => void;
  onPushSingleCommit: (commitId: string) => void;
  onPushAllStaged: () => void;
  onSplitCommit: (commitId: string, hunkIdToExtract: string) => void;
  onMergeTopPr: (commitId: string) => void;
  onPromoteDraftPr?: (commitId: string) => void;
  onSimulateLiveAgentTick: (ide: IdeHostId) => void;
  onInjectNotesCapture: (payload: {
    promptText: string;
    rawFilesInput: string;
    sourceAgent: IdeHostId;
    autoPushImmediately: boolean;
  }) => void;
  onNavigateToInstall: () => void;
}

const AGENT_META = AGENT_ICON_ASSETS;

interface CursorKeyframe {
  x: string;
  y: string;
  label: string;
  frameTransform: string;
  secondaryTransform: string;
}

const CARD_MOTION_KEYFRAMES: Record<number, CursorKeyframe[]> = {
  0: [
    {
      x: '46%',
      y: '62%',
      label: 'Moving to PR stack',
      frameTransform: '-rotate-3 scale-[0.98] -translate-x-1',
      secondaryTransform: 'translate-y-1',
    },
    {
      x: '32%',
      y: '42%',
      label: 'Slicing <80 LOC hunk',
      frameTransform: '-rotate-1 scale-100 translate-x-0',
      secondaryTransform: 'translate-y-0',
    },
    {
      x: '54%',
      y: '50%',
      label: 'Creating worktree',
      frameTransform: '-rotate-2 scale-[1.02] translate-x-1',
      secondaryTransform: '-translate-y-0.5',
    },
    {
      x: '38%',
      y: '68%',
      label: 'Adding diff highlight',
      frameTransform: '-rotate-3 scale-100 translate-x-0',
      secondaryTransform: 'translate-y-0.5',
    },
  ],
  1: [
    {
      x: '52%',
      y: '38%',
      label: 'Isolating test spec',
      frameTransform: 'rotate-0 scale-100 translate-y-0',
      secondaryTransform: 'translate-x-1 scale-[1.02]',
    },
    {
      x: '28%',
      y: '58%',
      label: 'Resizing diff slice',
      frameTransform: '-rotate-1 scale-[1.03] -translate-y-0.5',
      secondaryTransform: 'translate-x-0 scale-95',
    },
    {
      x: '58%',
      y: '64%',
      label: 'Chaining PR #142',
      frameTransform: 'rotate-1 scale-[0.98] translate-y-0.5',
      secondaryTransform: '-translate-x-1 scale-100',
    },
    {
      x: '42%',
      y: '46%',
      label: 'Checking LOC cap',
      frameTransform: 'rotate-0 scale-100 translate-y-0',
      secondaryTransform: 'translate-x-0 scale-100',
    },
  ],
  2: [
    {
      x: '56%',
      y: '60%',
      label: 'Syncing to GitHub',
      frameTransform: 'rotate-0 scale-100',
      secondaryTransform: '-rotate-2 translate-y-0 scale-100',
    },
    {
      x: '36%',
      y: '44%',
      label: 'Moving to mobile PR',
      frameTransform: 'scale-[0.98] -translate-x-1',
      secondaryTransform: 'rotate-0 -translate-y-1 scale-[1.04]',
    },
    {
      x: '48%',
      y: '34%',
      label: 'Updating PR status',
      frameTransform: 'scale-[1.01] translate-x-0',
      secondaryTransform: '-rotate-1 translate-y-0.5 scale-100',
    },
    {
      x: '60%',
      y: '52%',
      label: 'Zero-click pushed',
      frameTransform: 'scale-100 translate-x-0.5',
      secondaryTransform: 'rotate-1 translate-y-0 scale-[1.02]',
    },
  ],
};

const STAGE_BACKGROUNDS: Record<IdeHostId, [string, string, string]> = {
  antigravity: [
    'from-[#E4DEFF] via-[#EDE9FE] to-[#DCE8FF]',
    'from-[#DBEAFE] via-[#E8F0FE] to-[#F3E8FF]',
    'from-[#F5F3FF] via-[#E0F2FE] to-[#FEF3C7]/70',
  ],
  'claude-code': [
    'from-[#F5EBE1] via-[#FAF0E6] to-[#EDE5DC]',
    'from-[#EDE9E0] via-[#F7EFE8] to-[#E6E1DA]',
    'from-[#F3ECE4] via-[#EDE6DF] to-[#E2ECE9]',
  ],
  'codex-cli': [
    'from-[#E5E7EB] via-[#EBEEF5] to-[#E0E7FF]',
    'from-[#EFECE6] via-[#F5EFE6] to-[#E8E4DC]',
    'from-[#E0E7FF] via-[#EAE8FF] to-[#E2E8F0]',
  ],
  cursor: [
    'from-[#E8E8EE] via-[#F1F1F6] to-[#E2E8F0]',
    'from-[#E0E7FF] via-[#EDE9FE] to-[#F1F5F9]',
    'from-[#EFECE6] via-[#E5E7EB] to-[#E0F2FE]',
  ],
  vscode: [
    'from-[#DBEAFE] via-[#E0F2FE] to-[#EFF6FF]',
    'from-[#E0E7FF] via-[#DBEAFE] to-[#F0F9FF]',
    'from-[#E8F0FE] via-[#EDE9FE] to-[#DBEAFE]',
  ],
  windsurf: [
    'from-[#CCFBF1]/70 via-[#E0F2FE] to-[#F0FDFA]',
    'from-[#E0F2FE] via-[#E8F0FE] to-[#CCFBF1]/60',
    'from-[#F0FDFA] via-[#E0E7FF] to-[#E0F2FE]',
  ],
  'gemini-cli': [
    'from-[#EDE9FE] via-[#E0E7FF] to-[#FCE7F3]/60',
    'from-[#DBEAFE] via-[#EDE9FE] to-[#E0F2FE]',
    'from-[#F3E8FF] via-[#E0E7FF] to-[#DBEAFE]',
  ],
  kiro: [
    'from-[#EDE9FE] via-[#DDD6FE]/75 to-[#F3E8FF]',
    'from-[#F3E8FF] via-[#EDE9FE] to-[#E0E7FF]',
    'from-[#E9D5FF]/70 via-[#EDE9FE] to-[#DBEAFE]',
  ],
};

interface PromptScenario {
  id: string;
  tabLabel: string;
  agentId: IdeHostId;
  promptText: string;
  steps: string[];
  filesCount: string;
  draftTitle: string;
  slices: {
    header: string;
    branch: string;
    file: string;
    loc: string;
    badge: string;
  }[];
}

const PROMPT_SCENARIOS: PromptScenario[] = [
  {
    id: 'feature',
    tabLabel: 'Feature slice',
    agentId: 'antigravity',
    promptText: 'Add PKCE OAuth login, fix session cookie bug, and write unit tests.',
    steps: [
      'Separated feature, bugfix, and test into 3 commits',
      'Capped every commit under 80 LOC',
      'Opened stacked PRs #141 → #142 → #143',
    ],
    filesCount: '3 atomic commits for OAuth',
    draftTitle: 'Stacked PR draft',
    slices: [
      {
        header: 'feat(auth): implement PKCE code_verifier exchange',
        branch: 'stack/01-feat-auth',
        file: 'src/auth/pkceCallback.ts',
        loc: '+54 -9',
        badge: 'PR #141 · 1m review',
      },
      {
        header: 'fix(cookie): enforce SameSite lax maxAge bounds',
        branch: 'stack/02-fix-cookie',
        file: 'src/auth/cookieJar.ts',
        loc: '+26 -8',
        badge: 'PR #142 · 1m review',
      },
      {
        header: 'test(auth): verify PKCE verifier mismatch rejection',
        branch: 'stack/03-test-auth',
        file: 'src/auth/pkceCallback.test.ts',
        loc: '+44 -0',
        badge: 'PR #143 · 1m review',
      },
    ],
  },
  {
    id: 'bugfix',
    tabLabel: 'Bugfix isolation',
    agentId: 'claude-code',
    promptText: 'Refactor Stripe webhook retry loop and fix idempotency key collision.',
    steps: [
      'Isolated hotfix from background refactor hunks',
      'Verified Conventional Commit header format',
      'Pushed hotfix PR first for instant merge',
    ],
    filesCount: '2 isolated commits for Billing',
    draftTitle: 'Hotfix + Refactor stack',
    slices: [
      {
        header: 'fix(webhook): guard idempotency key against duplicate retry',
        branch: 'stack/01-fix-webhook',
        file: 'src/billing/idempotency.ts',
        loc: '+19 -4',
        badge: 'PR #144 · 1m review',
      },
      {
        header: 'refactor(webhook): extract exponential backoff scheduler',
        branch: 'stack/02-refactor-retry',
        file: 'src/billing/retryQueue.ts',
        loc: '+48 -22',
        badge: 'PR #145 · 2m review',
      },
    ],
  },
  {
    id: 'brainstorm',
    tabLabel: 'Plans & notes',
    agentId: 'cursor',
    promptText: 'Update architecture roadmap notes while scaffolding rate-limiter middleware.',
    steps: [
      'Split markdown roadmap from production TypeScript',
      'Zero mixed-scope files in code review',
      'Auto-synced both branches to GitHub',
    ],
    filesCount: '2 clean slices for Docs + API',
    draftTitle: 'Docs & Code separation',
    slices: [
      {
        header: 'docs(roadmap): record Q3 token bucket architecture plan',
        branch: 'stack/01-docs-plan',
        file: 'docs/rate-limiter-plan.md',
        loc: '+38 -0',
        badge: 'PR #146 · 1m review',
      },
      {
        header: 'feat(api): scaffold sliding window rate limiter middleware',
        branch: 'stack/02-feat-limiter',
        file: 'src/middleware/rateLimit.ts',
        loc: '+52 -6',
        badge: 'PR #147 · 2m review',
      },
    ],
  },
  {
    id: 'stack',
    tabLabel: 'Full PR stack',
    agentId: 'codex-cli',
    promptText: 'Migrate checkout schema, add currency formatter, and wire UI receipt card.',
    steps: [
      'Ordered commits: schema → utils → UI component',
      'Linked parent-child branches automatically',
      'Ready for 1-click merge without conflicts',
    ],
    filesCount: '3 chained PRs for Checkout',
    draftTitle: 'Chained dependency stack',
    slices: [
      {
        header: 'feat(schema): add multi-currency minor unit columns',
        branch: 'stack/01-feat-schema',
        file: 'src/db/checkoutSchema.ts',
        loc: '+31 -3',
        badge: 'PR #148 · Base',
      },
      {
        header: 'feat(currency): format zero-decimal JPY and KRW totals',
        branch: 'stack/02-feat-currency',
        file: 'src/utils/currencyFormat.ts',
        loc: '+41 -5',
        badge: 'PR #149 · Stacked',
      },
      {
        header: 'feat(ui): render localized receipt summary breakdown',
        branch: 'stack/03-feat-receipt',
        file: 'src/components/ReceiptCard.tsx',
        loc: '+49 -11',
        badge: 'PR #150 · Top',
      },
    ],
  },
];

export const IdeExtensionOverlayView: React.FC<IdeExtensionOverlayViewProps> = ({
  ideProfiles,
  selectedIde,
  onSelectIde,
  workingTreeHunks,
  stagedAtomicStack,
  pushedStack,
  policy,
  githubConfig,
  daemonActive,
  onToggleDaemon,
  onPushSingleCommit,
  onPushAllStaged,
  onSplitCommit,
  onMergeTopPr,
  onPromoteDraftPr,
  onSimulateLiveAgentTick,
  onInjectNotesCapture,
  onNavigateToInstall,
}) => {
  const [heroAgent, setHeroAgent] = useState<IdeHostId>('antigravity');
  const [activeScenarioId, setActiveScenarioId] = useState<string>('feature');
  const [showQuickCapture, setShowQuickCapture] = useState<boolean>(false);
  const [prStatusFilter, setPrStatusFilter] = useState<
    'all' | 'open' | 'merged' | 'draft'
  >('all');
  const [motionTick, setMotionTick] = useState<number>(0);

  const [notePrompt, setNotePrompt] = useState('');
  const [noteFiles, setNoteFiles] = useState('');
  const [noteAgent, setNoteAgent] = useState<IdeHostId>('antigravity');
  const [autoCommitNote, setAutoCommitNote] = useState(true);
  const [noteError, setNoteError] = useState<string | null>(null);
  const [noteSuccess, setNoteSuccess] = useState<string | null>(null);

  // Continuous Moonjar-style live studio cursor & device motion loop (matches test_acc44596.mp4)
  useEffect(() => {
    const timer = window.setInterval(() => {
      setMotionTick((prev) => (prev + 1) % 4);
    }, 2200);
    return () => window.clearInterval(timer);
  }, []);

  const activeAgentForHero: IdeHostId =
    selectedIde === 'all' ? heroAgent : selectedIde;
  const heroMeta = AGENT_META[activeAgentForHero];

  const cycleHeroAgent = () => {
    const order: IdeHostId[] = [
      'antigravity',
      'claude-code',
      'codex-cli',
      'cursor',
      'vscode',
      'windsurf',
      'gemini-cli',
      'kiro',
    ];
    const nextIdx = (order.indexOf(activeAgentForHero) + 1) % order.length;
    const nextAgent = order[nextIdx];
    setHeroAgent(nextAgent);
    if (selectedIde !== 'all') {
      onSelectIde(nextAgent);
    }
  };

  const visibleStaged =
    selectedIde === 'all'
      ? stagedAtomicStack
      : stagedAtomicStack.filter(
          (c) => (c.sourceAgent || 'antigravity') === selectedIde
        );

  const visiblePushed =
    selectedIde === 'all'
      ? pushedStack
      : pushedStack.filter(
          (c) => (c.sourceAgent || 'antigravity') === selectedIde
        );

  const activeScenario =
    PROMPT_SCENARIOS.find((s) => s.id === activeScenarioId) ||
    PROMPT_SCENARIOS[0];

  const handleNoteSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const check = parseRawPatchOrPromptInput({
      promptText: notePrompt,
      rawFilesInput: noteFiles,
      sourceAgent: noteAgent,
    });
    if (!check.valid) {
      setNoteError(check.error || 'Enter prompt and modified files.');
      setNoteSuccess(null);
      return;
    }
    setNoteError(null);
    onInjectNotesCapture({
      promptText: notePrompt.trim(),
      rawFilesInput: noteFiles.trim(),
      sourceAgent: noteAgent,
      autoPushImmediately: autoCommitNote,
    });
    setNoteSuccess(
      `Sliced ${check.hunks.length} files from ${AGENT_META[noteAgent].shortName}.`
    );
    setNotePrompt('');
    setNoteFiles('');
  };

  const handleFillQuickNotePreset = () => {
    setNoteAgent(activeAgentForHero);
    setNotePrompt('Add PKCE callback handler and unit test');
    setNoteFiles(
      [
        'src/auth/pkceCallback.ts | +54 -9 | Implement PKCE verifier exchange',
        'src/auth/pkceCallback.test.ts | +44 -0 | Add PKCE mismatch test',
      ].join('\n')
    );
    setNoteError(null);
    setNoteSuccess(null);
  };

  const swimlaneAgents: IdeHostId[] =
    selectedIde === 'all'
      ? ['antigravity', 'claude-code', 'codex-cli']
      : [selectedIde];

  return (
    <div className="space-y-20 pb-10">
      {/* 1. Moonjar-Style Minimal Hero Section */}
      <section className="text-center max-w-3xl mx-auto pt-4 sm:pt-8 space-y-6">
        <h1 className="text-4xl sm:text-[56px] font-semibold tracking-[-0.035em] text-[#1D1D1F] leading-[1.08]">
          What if{' '}
          <button
            type="button"
            onClick={cycleHeroAgent}
            title="Click to switch coding agent"
            className="inline-flex items-center gap-2.5 align-baseline hover:opacity-85 transition-opacity cursor-pointer"
          >
            <AgentIcon
              agentId={activeAgentForHero}
              sizeClass="w-8 h-8 sm:w-11 sm:h-11"
              roundedClass="rounded-xl"
              className="translate-y-[-2px] shadow-xs"
            />
            <span className="text-[#1D1D1F]">{heroMeta.shortName}</span>
          </button>{' '}
          committed your code every time you shipped?
        </h1>

        <p className="text-base sm:text-[19px] text-[#71717A] leading-relaxed max-w-xl mx-auto font-normal">
          Otto is a{' '}
          <mark className="bg-[#FCE588] text-[#1D1D1F] px-2 py-0.5 rounded-md font-medium underline decoration-[#1D1D1F]/30 underline-offset-4">
            fully agentic →
          </mark>{' '}
          overlay for atomic commits and stacked PRs. Your agent slices and pushes to GitHub while you keep prompting.
        </p>

        <div className="flex flex-wrap items-center justify-center gap-3 pt-1">
          <button
            type="button"
            onClick={() => onSimulateLiveAgentTick(activeAgentForHero)}
            className="inline-flex items-center gap-2 px-6 py-3 text-sm font-semibold text-white bg-[#232325] hover:bg-[#141416] rounded-full shadow-sm transition-colors whitespace-nowrap shrink-0 cursor-pointer"
          >
            <span>Simulate {heroMeta.shortName} edit</span>
          </button>

          <button
            type="button"
            onClick={onNavigateToInstall}
            className="inline-flex items-center gap-1.5 px-6 py-3 text-sm font-medium text-[#1D1D1F] bg-white hover:bg-zinc-50 border border-black/[0.09] rounded-full shadow-2xs transition-colors whitespace-nowrap shrink-0 cursor-pointer"
          >
            <span>See what it can do</span>
            <ChevronRight className="w-4 h-4 text-zinc-400" />
          </button>
        </div>
      </section>

      {/* 2. Pure Light Moonjar Studio Window (Matches test_acc44596.mp4 1-for-1: Warm White Window + 3 Live Motion Stage Cards per Agent Row) */}
      <section aria-label="Live Agent Commit Studio">
        <div className="p-2.5 sm:p-6 rounded-[32px] bg-gradient-to-b from-[#EDE9FE]/65 via-[#F3E8FF]/40 to-[#FAF8F5]">
          <div className="bg-[#FAF9F5] border border-black/[0.08] rounded-2xl shadow-xl shadow-indigo-950/5 overflow-hidden">
            {/* Clean Light macOS Window Top Bar (Matches test_acc44596.mp4) */}
            <div className="flex flex-wrap items-center justify-between gap-3 px-4 py-3 border-b border-black/[0.05] bg-[#FAF9F5]">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1.5" aria-hidden="true">
                  <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-black/10" />
                  <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-black/10" />
                  <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-black/10" />
                </div>
                <PanelLeft className="w-4 h-4 text-zinc-400 ml-1" />
                <span className="text-xs font-medium text-zinc-500 font-mono hidden sm:inline">
                  {githubConfig.owner}/{githubConfig.repo} · ≤{policy.maxLocPerCommit} LOC
                </span>
              </div>

              <div className="flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  onClick={() => setShowQuickCapture((v) => !v)}
                  className="inline-flex items-center gap-1 px-3 py-1 text-xs font-medium text-zinc-700 bg-white hover:bg-zinc-100 border border-black/[0.08] rounded-full transition-colors cursor-pointer"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Stream edit</span>
                </button>

                <button
                  type="button"
                  onClick={onToggleDaemon}
                  className={`px-3 py-1 text-xs font-medium rounded-full border transition-colors cursor-pointer ${
                    daemonActive
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                      : 'bg-amber-50 text-amber-800 border-amber-200'
                  }`}
                >
                  {daemonActive ? 'Auto-Pilot: ON' : 'Auto-Pilot: Paused'}
                </button>

                {visibleStaged.length > 0 && (
                  <button
                    type="button"
                    onClick={onPushAllStaged}
                    className="px-3.5 py-1 text-xs font-semibold text-white bg-[#232325] hover:bg-black rounded-full transition-colors cursor-pointer"
                  >
                    Push all ({visibleStaged.length})
                  </button>
                )}

                <Maximize2 className="w-3.5 h-3.5 text-zinc-400 ml-1 hidden sm:block" />
              </div>
            </div>

            {/* Optional Collapsible Quick Stream Input */}
            {showQuickCapture && (
              <form
                onSubmit={handleNoteSubmit}
                noValidate
                className="p-4 bg-white border-b border-black/[0.06] space-y-3"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-zinc-900">
                      Stream live agent changes
                    </span>
                    <select
                      aria-label="Source IDE or Coding Agent"
                      value={noteAgent}
                      onChange={(e) => setNoteAgent(e.target.value as IdeHostId)}
                      className="bg-zinc-100 border border-zinc-200 rounded-lg px-2 py-1 text-xs text-zinc-800"
                    >
                      <option value="antigravity">Antigravity</option>
                      <option value="claude-code">Claude Code</option>
                      <option value="codex-cli">Codex</option>
                      <option value="cursor">Cursor</option>
                      <option value="vscode">VS Code</option>
                      <option value="windsurf">Windsurf</option>
                      <option value="gemini-cli">Gemini CLI</option>
                      <option value="kiro">Kiro</option>
                    </select>
                  </div>

                  <button
                    type="button"
                    onClick={handleFillQuickNotePreset}
                    className="text-xs font-medium text-indigo-600 hover:text-indigo-800 cursor-pointer"
                  >
                    Load sample diff
                  </button>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  <input
                    id="quick-note-prompt"
                    type="text"
                    value={notePrompt}
                    onChange={(e) => setNotePrompt(e.target.value)}
                    placeholder="Agent prompt (e.g. Add PKCE callback handler)"
                    className="text-xs bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-2 text-zinc-900"
                  />
                  <input
                    id="quick-note-files"
                    type="text"
                    value={noteFiles}
                    onChange={(e) => setNoteFiles(e.target.value)}
                    placeholder="src/auth/pkce.ts | +54 -9 | Add PKCE verifier"
                    className="text-xs font-mono bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-2 text-zinc-900"
                  />
                </div>

                {noteError && (
                  <div
                    role="alert"
                    className="flex items-center gap-1.5 text-xs text-rose-700"
                  >
                    <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                    <span>{noteError}</span>
                  </div>
                )}

                {noteSuccess && (
                  <div
                    role="status"
                    className="flex items-center gap-1.5 text-xs text-emerald-700"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />
                    <span>{noteSuccess}</span>
                  </div>
                )}

                <div className="flex items-center justify-between">
                  <label className="inline-flex items-center gap-1.5 text-xs text-zinc-600 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={autoCommitNote}
                      onChange={(e) => setAutoCommitNote(e.target.checked)}
                    />
                    <span>Auto-commit &amp; stack PR immediately</span>
                  </label>
                  <button
                    type="submit"
                    className="px-3.5 py-1.5 text-xs font-semibold text-white bg-[#232325] rounded-full cursor-pointer"
                  >
                    Slice &amp; Commit
                  </button>
                </div>
              </form>
            )}

            {/* Main Light Studio Body: Agent Swimlanes with Real IDE Motion Cards */}
            <div className="p-5 sm:p-7 space-y-8 bg-[#FAF9F5]">
              {swimlaneAgents.map((agentId, rowIdx) => {
                const meta = AGENT_META[agentId];
                const agentStaged = stagedAtomicStack.filter(
                  (c) => (c.sourceAgent || 'antigravity') === agentId
                );
                const agentPushed = pushedStack.filter(
                  (c) => (c.sourceAgent || 'antigravity') === agentId
                );
                const ownCards = [...agentStaged, ...agentPushed];
                const fallbackPool = [...stagedAtomicStack, ...pushedStack].filter(
                  (c) => !ownCards.some((o) => o.id === c.id)
                );
                const combinedCards = [...ownCards, ...fallbackPool].slice(0, 3);
                const rowBgs =
                  STAGE_BACKGROUNDS[agentId] || STAGE_BACKGROUNDS.antigravity;

                return (
                  <div key={agentId} className="space-y-3">
                    {/* Agent Row Header (Matches Moonjar: [Icon] Antigravity  3 in progress >) */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <AgentIcon
                          agentId={agentId}
                          sizeClass="w-5 h-5"
                          roundedClass="rounded-md"
                        />
                        <span className="text-sm font-semibold text-[#1D1D1F]">
                          {meta.shortName}
                        </span>
                        <span className="text-xs text-zinc-400 font-medium inline-flex items-center gap-0.5">
                          3 in progress
                          <ChevronRight className="w-3.5 h-3.5" />
                        </span>
                      </div>

                      <button
                        type="button"
                        onClick={() => onSimulateLiveAgentTick(agentId)}
                        className="text-xs font-medium text-zinc-500 hover:text-zinc-900 transition-colors cursor-pointer"
                      >
                        + Simulate {meta.shortName} edit
                      </button>
                    </div>

                    {/* 3 Live Motion Stage Cards Row (Matches test_acc44596.mp4) */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      {combinedCards.map((unit, idx) => {
                        const isStaged = unit.status === 'staged';
                        const primaryFile =
                          unit.hunks[0]?.filePath.split('/').pop() || 'index.ts';
                        const keyframes =
                          CARD_MOTION_KEYFRAMES[idx] || CARD_MOTION_KEYFRAMES[0];
                        const kf =
                          keyframes[(motionTick + rowIdx + idx) % keyframes.length];
                        const cardBg = rowBgs[idx % 3];

                        return (
                          <div key={`${agentId}-${unit.id}-${idx}`} className="space-y-1.5 group">
                            {/* Top Caption (Matches Moonjar `:: Ellie · Today, one task in focus`) */}
                            <div className="flex items-center justify-between text-[11px] text-zinc-500 px-0.5">
                              <span className="truncate font-medium text-zinc-700">
                                <span className="text-indigo-400 mr-1.5">∷</span>
                                {primaryFile} · {unit.scope}
                              </span>
                              <span className="font-mono text-[10px] text-zinc-400 shrink-0">
                                +{unit.totalAdditions}/-{unit.totalDeletions}
                              </span>
                            </div>

                            {/* Pastel Motion Stage Card (h-52, no black boxes, real floating IDE & device frames) */}
                            <div
                              className={`relative h-52 rounded-2xl bg-gradient-to-br ${cardBg} p-3.5 flex flex-col justify-between border border-black/[0.05] overflow-hidden shadow-2xs`}
                            >
                              {/* CARD VARIANT 0: Tilted Light IDE / Antigravity Worktree Canvas (like Moonjar's tilted device card 1) */}
                              {idx === 0 && (
                                <div className="relative flex-1 flex items-center justify-center pt-1">
                                  <div
                                    className={`w-[88%] rounded-xl bg-white/95 border border-black/[0.08] shadow-md p-2.5 space-y-1.5 transition-all duration-700 ease-out ${kf.frameTransform}`}
                                  >
                                    {/* Mini Light IDE Header */}
                                    <div className="flex items-center justify-between border-b border-zinc-100 pb-1.5">
                                      <div className="flex items-center gap-1.5 text-[10px] font-medium text-zinc-700 truncate">
                                        <FolderGit2 className="w-3 h-3 text-indigo-500 shrink-0" />
                                        <span className="truncate">{primaryFile}</span>
                                      </div>
                                      <PrStatusBadge
                                        status={unit.status}
                                        prNumber={
                                          isStaged ? undefined : unit.prNumber || 141 + idx
                                        }
                                      />
                                    </div>

                                    {/* Mini Light Diff Lines */}
                                    <div className="space-y-1 font-mono text-[10px]">
                                      <div className="px-1.5 py-0.5 rounded bg-emerald-50/90 text-emerald-900 truncate">
                                        + {unit.conventionalHeader}
                                      </div>
                                      <div className="px-1.5 py-0.5 rounded bg-sky-50/80 text-sky-900 flex items-center justify-between">
                                        <span className="truncate">
                                          ⑂ {unit.branchName}
                                        </span>
                                        <span className="font-semibold shrink-0">
                                          {unit.totalLoc} LOC
                                        </span>
                                      </div>
                                    </div>
                                  </div>
                                </div>
                              )}

                              {/* CARD VARIANT 1: Dual Split IDE Worktree + Mobile PR Sheet (like Moonjar's 2-device card 2) */}
                              {idx === 1 && (
                                <div className="relative flex-1 flex items-center justify-center gap-2 pt-1">
                                  {/* Left Mini IDE Diff Card */}
                                  <div
                                    className={`w-[54%] rounded-xl bg-white/95 border border-black/[0.08] shadow-md p-2.5 space-y-1.5 transition-all duration-700 ease-out ${kf.frameTransform}`}
                                  >
                                    <div className="flex items-center justify-between text-[9px] font-mono text-zinc-400">
                                      <span className="truncate">{primaryFile}</span>
                                      <span className="text-emerald-700 font-semibold">
                                        +{unit.totalAdditions}
                                      </span>
                                    </div>
                                    <p className="text-[10px] font-mono font-semibold text-[#1D1D1F] line-clamp-2 leading-tight">
                                      {unit.conventionalHeader}
                                    </p>
                                    <div className="h-1.5 w-full rounded-full bg-zinc-100 overflow-hidden">
                                      <div className="h-full w-3/4 bg-indigo-500 rounded-full" />
                                    </div>
                                  </div>

                                  {/* Right Mini Mobile Companion PR Frame */}
                                  <div
                                    className={`w-[42%] rounded-xl bg-white/95 border border-black/[0.08] shadow-md p-2 space-y-1.5 transition-all duration-700 ease-out ${kf.secondaryTransform}`}
                                  >
                                    <div className="w-6 h-1 rounded-full bg-zinc-200 mx-auto" />
                                    <div className="flex justify-center">
                                      <PrStatusBadge
                                        status={unit.status}
                                        prNumber={
                                          isStaged ? undefined : unit.prNumber || 142
                                        }
                                      />
                                    </div>
                                    <div className="text-[9px] font-mono text-center text-zinc-500 truncate">
                                      {unit.branchName}
                                    </div>
                                  </div>
                                </div>
                              )}

                              {/* CARD VARIANT 2: Multi-Device Desktop IDE + Overlapping PR Stack Card (like Moonjar's Mac + iPad + iPhone card 3) */}
                              {idx === 2 && (
                                <div className="relative flex-1 flex items-center justify-center pt-1">
                                  {/* Back Desktop IDE Window */}
                                  <div
                                    className={`w-[82%] rounded-xl bg-white/95 border border-black/[0.08] shadow-md p-2.5 space-y-1.5 transition-all duration-700 ease-out ${kf.frameTransform}`}
                                  >
                                    <div className="flex items-center justify-between text-[10px] font-mono text-zinc-500 border-b border-zinc-100 pb-1">
                                      <span className="inline-flex items-center gap-1 truncate">
                                        <GitBranch className="w-3 h-3 text-indigo-500 shrink-0" />
                                        <span className="truncate">{unit.branchName}</span>
                                      </span>
                                      <PrStatusBadge
                                        status={unit.status}
                                        prNumber={
                                          isStaged ? undefined : unit.prNumber || 143
                                        }
                                      />
                                    </div>
                                    <p className="text-[10px] font-mono font-semibold text-zinc-900 line-clamp-2 leading-snug">
                                      {unit.conventionalHeader}
                                    </p>
                                  </div>

                                  {/* Overlapping Bottom-Right Companion Card */}
                                  <div
                                    className={`absolute right-1.5 bottom-1.5 w-[44%] rounded-xl bg-[#1D1D1F] text-white p-2 shadow-lg border border-white/10 transition-all duration-700 ease-out ${kf.secondaryTransform}`}
                                  >
                                    <div className="flex items-center justify-between text-[9px] font-mono text-zinc-400">
                                      <span>Stack Ready</span>
                                      <span className="text-emerald-400">
                                        {unit.totalLoc} LOC
                                      </span>
                                    </div>
                                    <div className="text-[10px] font-semibold truncate mt-0.5">
                                      ✓ Checks passed
                                    </div>
                                  </div>
                                </div>
                              )}

                              {/* Animated Moonjar Pointer Arrow + Purple Action Pill Gliding Across Card */}
                              <div
                                style={{
                                  left: kf.x,
                                  top: kf.y,
                                }}
                                className="pointer-events-none absolute z-20 transition-all duration-700 ease-out flex items-start gap-0.5"
                              >
                                <svg
                                  width="15"
                                  height="15"
                                  viewBox="0 0 16 16"
                                  fill="none"
                                  className="drop-shadow-xs -mt-1 -ml-1 shrink-0"
                                >
                                  <path
                                    d="M2.5 2L7.2 13.5L9.3 8.8L14 6.7L2.5 2Z"
                                    fill="#6366F1"
                                    stroke="white"
                                    strokeWidth="1.5"
                                    strokeLinejoin="round"
                                  />
                                </svg>
                                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-[#6366F1] text-white shadow-md whitespace-nowrap">
                                  {kf.label}
                                </span>
                              </div>

                              {/* Bottom Action Bar Inside Stage Card */}
                              <div className="relative z-30 flex items-center justify-between gap-2 pt-1">
                                <span className="text-[10px] font-mono text-zinc-600 bg-white/75 backdrop-blur-xs px-2 py-0.5 rounded-full border border-black/[0.05]">
                                  {unit.totalLoc} LOC · {unit.reviewMinutes}m
                                </span>

                                <div className="flex items-center gap-1">
                                  {isStaged && unit.hunks.length > 1 && (
                                    <button
                                      type="button"
                                      onClick={() =>
                                        onSplitCommit(
                                          unit.id,
                                          unit.hunks[unit.hunks.length - 1].id
                                        )
                                      }
                                      className="px-2 py-0.5 text-[10px] font-medium bg-white/90 hover:bg-white text-zinc-700 rounded-full border border-black/[0.08] cursor-pointer"
                                    >
                                      Split
                                    </button>
                                  )}

                                  {isStaged ? (
                                    <button
                                      type="button"
                                      onClick={() => onPushSingleCommit(unit.id)}
                                      className="px-2.5 py-0.5 text-[10px] font-semibold bg-[#1D1D1F] hover:bg-black text-white rounded-full shadow-2xs cursor-pointer"
                                    >
                                      Commit &amp; PR
                                    </button>
                                  ) : unit.status === 'draft' && onPromoteDraftPr ? (
                                    <button
                                      type="button"
                                      onClick={() => onPromoteDraftPr(unit.id)}
                                      className="px-2.5 py-0.5 text-[10px] font-medium bg-white/90 hover:bg-white text-amber-900 rounded-full border border-amber-300 cursor-pointer"
                                    >
                                      Mark Open
                                    </button>
                                  ) : unit.status === 'pr_open' ? (
                                    <button
                                      type="button"
                                      onClick={() => onMergeTopPr(unit.id)}
                                      className="px-2.5 py-0.5 text-[10px] font-medium bg-white/90 hover:bg-white text-zinc-800 rounded-full border border-black/[0.08] cursor-pointer"
                                    >
                                      Merge PR
                                    </button>
                                  ) : null}
                                </div>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                );
              })}

              {/* Pushed PR Stack List with Visual Status Indicators ('Open', 'Merged', 'Draft') */}
              <div className="pt-4 border-t border-black/[0.06] space-y-3.5">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold text-[#1D1D1F]">
                      Pushed PR Stack
                    </span>
                    <span className="text-xs font-mono text-zinc-400">
                      ({visiblePushed.length} stacked PRs)
                    </span>
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
                        onClick={() => setPrStatusFilter(tab.id)}
                        className={`px-2.5 py-1 rounded-full font-medium transition-colors cursor-pointer ${
                          prStatusFilter === tab.id
                            ? 'bg-white text-[#1D1D1F] shadow-2xs'
                            : 'text-zinc-600 hover:text-zinc-900'
                        }`}
                      >
                        {tab.label}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {visiblePushed
                    .filter((pr) => {
                      if (prStatusFilter === 'all') return true;
                      if (prStatusFilter === 'open')
                        return pr.status === 'pr_open' || pr.status === 'pushed';
                      if (prStatusFilter === 'merged') return pr.status === 'merged';
                      return pr.status === 'draft' || pr.status === 'staged';
                    })
                    .map((pr, idx) => (
                      <div
                        key={`${pr.id}-${idx}`}
                        className="p-3.5 rounded-2xl bg-white border border-black/[0.06] shadow-2xs flex items-center justify-between gap-3"
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <AgentIcon
                            agentId={pr.sourceAgent || 'antigravity'}
                            sizeClass="w-8 h-8"
                            roundedClass="rounded-xl"
                          />
                          <div className="min-w-0 space-y-0.5">
                            <div className="flex items-center gap-2">
                              <span className="text-[11px] font-mono text-zinc-500 truncate">
                                {pr.branchName}
                              </span>
                              <span className="text-[10px] font-mono text-emerald-700 font-semibold shrink-0">
                                +{pr.totalAdditions}/-{pr.totalDeletions} LOC
                              </span>
                            </div>
                            <p className="text-xs font-mono font-semibold text-[#1D1D1F] truncate">
                              {pr.conventionalHeader}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center gap-2 shrink-0">
                          <PrStatusBadge
                            status={pr.status}
                            prNumber={pr.prNumber || 141 + idx}
                            size="sm"
                          />
                          {pr.status === 'draft' && onPromoteDraftPr && (
                            <button
                              type="button"
                              onClick={() => onPromoteDraftPr(pr.id)}
                              className="px-2.5 py-1 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white text-[11px] font-semibold cursor-pointer"
                            >
                              Ready
                            </button>
                          )}
                          {pr.status === 'pr_open' && (
                            <button
                              type="button"
                              onClick={() => onMergeTopPr(pr.id)}
                              className="px-2.5 py-1 rounded-full bg-[#1D1D1F] hover:bg-black text-white text-[11px] font-semibold cursor-pointer"
                            >
                              Merge
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 3. Moonjar "Works with your existing agent." Icon Grid */}
      <section className="text-center max-w-2xl mx-auto space-y-6">
        <div className="space-y-2">
          <h2 className="text-2xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Works with your existing agent.
          </h2>
          <p className="text-sm sm:text-base text-[#71717A] max-w-md mx-auto">
            Otto runs silently in your IDE and terminal. Whatever agent you already code with drives it automatically.
          </p>
        </div>

        <div
          role="group"
          aria-label="Filter by coding agent"
          className="flex flex-wrap items-center justify-center gap-3 sm:gap-4 pt-2"
        >
          <button
            type="button"
            onClick={() => onSelectIde('all')}
            className={`h-14 px-4 rounded-2xl border text-xs font-semibold transition-all cursor-pointer flex items-center gap-2 ${
              selectedIde === 'all'
                ? 'bg-[#1D1D1F] text-white border-[#1D1D1F] shadow-md scale-105'
                : 'bg-white text-zinc-700 border-black/[0.08] hover:border-zinc-300'
            }`}
          >
            <span>All Agents ({workingTreeHunks.length})</span>
          </button>

          {ideProfiles.map((prof) => {
            const meta = AGENT_META[prof.id];
            const isSelected = selectedIde === prof.id;
            return (
              <button
                key={prof.id}
                type="button"
                onClick={() => {
                  onSelectIde(prof.id);
                  setHeroAgent(prof.id);
                }}
                title={`${prof.name} (${prof.autoCommittedToday} commits today)`}
                className={`group h-14 px-3.5 rounded-2xl border transition-all cursor-pointer flex items-center gap-2.5 ${
                  isSelected
                    ? 'bg-white border-zinc-900 ring-2 ring-zinc-900/10 shadow-md scale-105'
                    : 'bg-white/90 hover:bg-white border-black/[0.08]'
                }`}
              >
                <AgentIcon
                  agentId={prof.id}
                  sizeClass="w-9 h-9"
                  roundedClass="rounded-xl"
                />
                <div className="text-left pr-1">
                  <div className="text-xs font-semibold text-[#1D1D1F] leading-tight">
                    {meta.shortName}
                  </div>
                  <div className="text-[10px] text-zinc-400 font-mono">
                    {prof.autoCommittedToday} commits
                  </div>
                </div>
              </button>
            );
          })}
        </div>

        {/* Interactive Native IDE / CLI Environment Preview for Selected Agent */}
        <div className="max-w-4xl mx-auto pt-4 text-left">
          <CustomIdeOverlayShowcase
            activeAgent={
              selectedIde === 'all' ? activeAgentForHero : selectedIde
            }
            onSelectAgent={(agent) => {
              onSelectIde(agent);
              setHeroAgent(agent);
            }}
            onSimulateEdit={onSimulateLiveAgentTick}
          />
        </div>
      </section>

      {/* 4. Moonjar "One prompt. Every commit you need." Interactive Showcase */}
      <section className="max-w-4xl mx-auto space-y-7">
        <div className="text-center space-y-2.5">
          <h2 className="text-3xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F] leading-tight">
            One prompt.
            <br />
            Every commit you need.
          </h2>
          <p className="text-sm sm:text-base text-[#71717A] max-w-md mx-auto">
            Each tab is one{' '}
            <mark className="bg-[#FCE588] text-[#1D1D1F] px-1.5 py-0.5 rounded">
              real request to your agent
            </mark>
            , and every atomic commit &amp; PR Otto made from it.
          </p>
        </div>

        {/* Segmented Pill Selector */}
        <div className="flex justify-center">
          <div className="inline-flex flex-wrap items-center gap-1 p-1.5 bg-[#EBE8E0] rounded-full">
            {PROMPT_SCENARIOS.map((scen) => {
              const active = scen.id === activeScenario.id;
              return (
                <button
                  key={scen.id}
                  type="button"
                  onClick={() => setActiveScenarioId(scen.id)}
                  className={`px-4 py-1.5 text-xs sm:text-sm font-medium rounded-full transition-all cursor-pointer ${
                    active
                      ? 'bg-white text-[#1D1D1F] shadow-xs'
                      : 'text-zinc-600 hover:text-zinc-900'
                  }`}
                >
                  {scen.tabLabel}
                </button>
              );
            })}
          </div>
        </div>

        {/* Moonjar 2-Column Flow Container */}
        <div className="bg-[#EFECE6] border border-black/[0.05] rounded-[28px] p-5 sm:p-8 grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
          {/* Left Column: Agent Prompt Card -> AtomikGit Checkmarks Card */}
          <div className="lg:col-span-5 space-y-3">
            {/* Card 1: You, to Agent */}
            <div className="bg-white rounded-2xl p-4 border border-black/[0.05] shadow-2xs space-y-1.5">
              <div className="flex items-center gap-2 text-xs text-zinc-400 font-mono">
                <AgentIcon
                  agentId={activeScenario.agentId}
                  sizeClass="w-5 h-5"
                  roundedClass="rounded-md"
                />
                <span>
                  You, to {AGENT_META[activeScenario.agentId].shortName}
                </span>
              </div>
              <p className="text-sm font-medium text-[#1D1D1F] leading-snug">
                {activeScenario.promptText}
              </p>
            </div>

            {/* Down Arrow */}
            <div className="flex justify-center text-zinc-400 text-xs font-mono">
              ↓
            </div>

            {/* Card 2: Otto 3 Green Checkmarks */}
            <div className="bg-white rounded-2xl p-4 border border-black/[0.05] shadow-2xs space-y-2.5">
              <div className="flex items-center gap-2">
                <OttoLogo sizeClass="w-5 h-5" roundedClass="rounded-md" />
                <span className="text-xs font-semibold text-[#1D1D1F]">
                  Otto Overlay
                </span>
              </div>
              <ul className="space-y-1.5">
                {activeScenario.steps.map((step, i) => (
                  <li
                    key={i}
                    className="flex items-start gap-2 text-xs text-zinc-600"
                  >
                    <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0 mt-0.5" />
                    <span>{step}</span>
                  </li>
                ))}
              </ul>
            </div>

            <div className="text-center text-[11px] font-mono text-zinc-500 pt-1">
              {activeScenario.filesCount}
            </div>
          </div>

          {/* Right Column: Clean Interactive Stack Preview Card */}
          <div className="lg:col-span-7 bg-white rounded-2xl border border-black/[0.06] shadow-sm p-5 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-zinc-100">
              <span className="text-xs font-semibold text-[#1D1D1F]">
                {activeScenario.draftTitle}
              </span>
              <button
                type="button"
                onClick={() =>
                  onSimulateLiveAgentTick(activeScenario.agentId)
                }
                className="px-3.5 py-1 text-xs font-semibold text-white bg-[#1D1D1F] hover:bg-black rounded-full transition-colors cursor-pointer"
              >
                Push all
              </button>
            </div>

            <div className="space-y-3">
              {activeScenario.slices.map((s, idx) => (
                <div
                  key={idx}
                  className="p-3.5 rounded-xl bg-[#FAF9F5] border border-black/[0.05] flex flex-col sm:flex-row sm:items-center justify-between gap-2"
                >
                  <div className="space-y-1 min-w-0">
                    <div className="flex items-center gap-2 text-[11px] font-mono text-zinc-500">
                      <span className="text-zinc-900 font-semibold">
                        0{idx + 1}
                      </span>
                      <span>{s.file}</span>
                      <span className="text-emerald-700 font-medium">
                        {s.loc}
                      </span>
                    </div>
                    <p className="text-xs font-mono font-semibold text-[#1D1D1F] truncate">
                      {s.header}
                    </p>
                  </div>

                  <span className="px-2.5 py-1 rounded-full text-[11px] font-mono bg-white border border-black/[0.06] text-zinc-700 shrink-0 self-start sm:self-center">
                    {s.badge}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* 5. Moonjar "Fair questions." iMessage-Style Q&A Card */}
      <section className="max-w-xl mx-auto space-y-6">
        <h2 className="text-center text-3xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
          Fair questions.
        </h2>

        <div className="bg-white rounded-3xl border border-black/[0.07] shadow-sm p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-zinc-100">
            <OttoLogo sizeClass="w-6 h-6" roundedClass="rounded-lg" />
            <span className="text-xs font-semibold text-[#1D1D1F]">
              Otto
            </span>
          </div>

          {/* Q1 */}
          <div className="flex justify-end">
            <div className="bg-[#007AFF] text-white text-xs sm:text-sm font-medium px-4 py-2 rounded-2xl rounded-br-xs max-w-xs">
              Why can’t Antigravity or Claude Code just do this?
            </div>
          </div>
          <div className="flex items-end gap-2">
            <OttoLogo sizeClass="w-5 h-5" roundedClass="rounded-md" />
            <div className="bg-[#F1F0EC] text-[#1D1D1F] text-xs sm:text-sm leading-relaxed px-4 py-2.5 rounded-2xl rounded-bl-xs max-w-sm">
              Coding agents focus on finishing your prompt—often touching 12 files in one bulk dump. Otto watches the file tree and slices changes into small, reviewable PRs automatically.
            </div>
          </div>

          {/* Q2 */}
          <div className="flex justify-end pt-1">
            <div className="bg-[#007AFF] text-white text-xs sm:text-sm font-medium px-4 py-2 rounded-2xl rounded-br-xs max-w-xs">
              Do I have to click anything while I work?
            </div>
          </div>
          <div className="flex items-end gap-2">
            <OttoLogo sizeClass="w-5 h-5" roundedClass="rounded-md" />
            <div className="bg-[#F1F0EC] text-[#1D1D1F] text-xs sm:text-sm leading-relaxed px-4 py-2.5 rounded-2xl rounded-bl-xs max-w-sm">
              Zero clicks. Keep prompting your next feature, bugfix, or plan—Otto commits and stacks PRs in the background.
            </div>
          </div>

          {/* Q3 */}
          <div className="flex justify-end pt-1">
            <div className="bg-[#007AFF] text-white text-xs sm:text-sm font-medium px-4 py-2 rounded-2xl rounded-br-xs max-w-xs">
              Does it work in any IDE or CLI?
            </div>
          </div>
          <div className="flex items-end gap-2">
            <OttoLogo sizeClass="w-5 h-5" roundedClass="rounded-md" />
            <div className="bg-[#F1F0EC] text-[#1D1D1F] text-xs sm:text-sm leading-relaxed px-4 py-2.5 rounded-2xl rounded-bl-xs max-w-sm">
              Yes—Antigravity, Claude Code, Codex, Cursor, VS Code, Windsurf, Gemini CLI, and Kiro all share the same local overlay.
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};
