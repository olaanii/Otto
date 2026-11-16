import React, { useEffect, useState } from 'react';
import { IdeHostId } from '../types/git';
import { AgentIcon, AGENT_ICON_ASSETS } from './AgentIcon';
import { NativeIdeStage } from './NativeIdeEnvironments';
import { PrStatusBadge } from './PrStatusBadge';
import {
  Clock,
  GitBranch,
  Pause,
  Play,
  RotateCcw,
  Sparkles,
} from 'lucide-react';

interface LiveIdeOverlayVideoStageProps {
  activeAgent: IdeHostId;
  onSelectAgent: (agent: IdeHostId) => void;
  onTriggerLiveCommit: (agent: IdeHostId) => void;
}

type PresentationTab =
  | 'antigravity-ide'
  | 'multi-agent-studio'
  | 'time-machine';

const ALL_IDE_AGENTS: IdeHostId[] = [
  'antigravity',
  'claude-code',
  'cursor',
  'kiro',
  'codex-cli',
  'vscode',
  'windsurf',
  'gemini-cli',
];

interface TimeMachineVersion {
  id: string;
  time: string;
  agent: string;
  agentId: IdeHostId;
  branch: string;
  header: string;
  loc: string;
  prNum: number;
  status: 'merged' | 'pr_open' | 'draft';
  label: string;
  files: string[];
  tint: string;
}

const TIME_MACHINE_VERSIONS: TimeMachineVersion[] = [
  {
    id: 'tm-v4',
    time: '11:02 PM',
    agent: 'Antigravity',
    agentId: 'antigravity',
    branch: 'atomik/03-test-auth-pkce',
    header: 'test(auth): verify PKCE S256 verifier mismatch rejection',
    loc: '+44 -0 LOC',
    prNum: 143,
    status: 'pr_open',
    label: 'Isolated unit test suite into PR #143',
    files: ['src/auth/pkceCallback.test.ts'],
    tint: 'from-[#EDE9FE] via-[#E0E7FF] to-[#DBEAFE]',
  },
  {
    id: 'tm-v3',
    time: '10:59 PM',
    agent: 'Claude Code',
    agentId: 'claude-code',
    branch: 'atomik/02-fix-cookie-bounds',
    header: 'fix(cookie): enforce SameSite lax and 7d maxAge bounds',
    loc: '+26 -8 LOC',
    prNum: 142,
    status: 'pr_open',
    label: 'Extracted cookie hotfix into priority PR #142',
    files: ['src/auth/cookieJar.ts'],
    tint: 'from-[#DBEAFE] via-[#E0F2FE] to-[#EDE9FE]',
  },
  {
    id: 'tm-v2',
    time: '10:56 PM',
    agent: 'Antigravity',
    agentId: 'antigravity',
    branch: 'atomik/01-feat-auth-pkce',
    header: 'feat(auth): implement OAuth 2.1 PKCE S256 challenge exchange',
    loc: '+54 -9 LOC',
    prNum: 141,
    status: 'merged',
    label: 'Base feature slice merged cleanly (<80 LOC)',
    files: ['src/auth/pkceCallback.ts'],
    tint: 'from-[#DCFCE7] via-[#E0F2FE] to-[#EDE9FE]',
  },
  {
    id: 'tm-v1',
    time: '10:51 PM',
    agent: 'Cursor',
    agentId: 'cursor',
    branch: 'atomik/00-docs-auth-plan',
    header: 'docs(plans): isolate OAuth 2.1 architecture brainstorm notes',
    loc: '+38 -0 LOC',
    prNum: 140,
    status: 'merged',
    label: 'Separated markdown plan from production code',
    files: ['docs/plans/oauth-pkce-plan.md'],
    tint: 'from-[#FEF3C7] via-[#EDE9FE] to-[#E0F2FE]',
  },
];

export const LiveIdeOverlayVideoStage: React.FC<
  LiveIdeOverlayVideoStageProps
> = ({ activeAgent, onSelectAgent, onTriggerLiveCommit }) => {
  const [presentationMode, setPresentationMode] =
    useState<PresentationTab>('antigravity-ide');
  const [step, setStep] = useState(0);
  const [isPlaying, setIsPlaying] = useState(true);
  const [stackViewMode, setStackViewMode] = useState<'sliced' | 'raw'>(
    'sliced'
  );

  useEffect(() => {
    if (!isPlaying) return;
    const timer = window.setInterval(() => {
      setStep((prev) => (prev + 1) % 4);
    }, 2600);
    return () => window.clearInterval(timer);
  }, [isPlaying]);

  const activeTmIndex = step % TIME_MACHINE_VERSIONS.length;
  const activeTmVersion =
    TIME_MACHINE_VERSIONS[activeTmIndex] || TIME_MACHINE_VERSIONS[0];
  const agentMeta =
    AGENT_ICON_ASSETS[activeAgent] || AGENT_ICON_ASSETS.antigravity;

  return (
    <div
      className="space-y-3.5"
      data-testid="live-ide-overlay-video-presentation"
    >
      {/* Unified Single-Row Agent & Playback Bar (All 8 IDEs + Playback on 1 line) */}
      <div className="bg-white/95 px-2.5 py-2 rounded-2xl border border-black/[0.07] shadow-2xs flex flex-wrap items-center justify-between gap-1.5">
        {/* All 8 Native IDE / CLI Selectors */}
        <div
          role="group"
          aria-label="Select native IDE or CLI environment"
          className="flex flex-wrap items-center gap-1"
        >
          {ALL_IDE_AGENTS.map((id) => {
            const isSelected =
              presentationMode === 'antigravity-ide' && activeAgent === id;
            return (
              <button
                key={id}
                type="button"
                onClick={() => {
                  setPresentationMode('antigravity-ide');
                  onSelectAgent(id);
                }}
                className={`inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl text-[11.5px] font-semibold transition-all cursor-pointer whitespace-nowrap ${
                  isSelected
                    ? 'bg-[#1D1D1F] text-white shadow-2xs'
                    : 'bg-[#F4F3EF] text-zinc-700 hover:bg-zinc-200/80'
                }`}
              >
                <AgentIcon
                  agentId={id}
                  sizeClass="w-3.5 h-3.5"
                  roundedClass="rounded-xs"
                />
                <span>{AGENT_ICON_ASSETS[id].shortName}</span>
              </button>
            );
          })}
        </div>

        {/* Inline Compact Play/Pause + Step Dots */}
        <div className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-[#F4F3EF] text-[11px] ml-auto shrink-0">
          <button
            type="button"
            onClick={() => setIsPlaying((p) => !p)}
            className="inline-flex items-center gap-1 font-semibold text-[#1D1D1F] cursor-pointer"
          >
            {isPlaying ? (
              <>
                <Pause className="w-3 h-3" />
                <span>Pause</span>
              </>
            ) : (
              <>
                <Play className="w-3 h-3" />
                <span>Play</span>
              </>
            )}
          </button>
          <span className="text-zinc-300">·</span>
          <div className="flex items-center gap-1">
            {[0, 1, 2, 3].map((idx) => (
              <button
                key={idx}
                type="button"
                aria-label={`Jump to scene ${idx + 1}`}
                onClick={() => setStep(idx)}
                className={`h-1.5 rounded-full transition-all cursor-pointer ${
                  step === idx
                    ? 'w-3.5 bg-[#6366F1]'
                    : 'w-1.5 bg-zinc-300 hover:bg-zinc-400'
                }`}
              />
            ))}
          </div>
          <button
            type="button"
            onClick={() => setStep(0)}
            title="Restart motion loop"
            className="text-zinc-400 hover:text-zinc-700 cursor-pointer"
          >
            <RotateCcw className="w-3 h-3" />
          </button>
        </div>
      </div>

      {/* ===================================================================
          MODE 1: AUTHENTIC NATIVE IDE / CLI WORKSPACE SWITCHER
          Transforms 100% into Antigravity, Claude Code, Cursor, Kiro,
          Codex, VS Code, Windsurf, or Gemini CLI when clicked!
         =================================================================== */}
      {presentationMode === 'antigravity-ide' && (
        <NativeIdeStage
          agentId={activeAgent}
          step={step}
          onSimulateEdit={onTriggerLiveCommit}
        />
      )}

      {/* ===================================================================
          MODE 2: CUSTOM MULTI-AGENT LIVE COMMIT STUDIO PRESENTATION
         =================================================================== */}
      {presentationMode === 'multi-agent-studio' && (
        <div className="rounded-[28px] bg-[#FAF9F5] border border-black/[0.08] shadow-lg overflow-hidden p-5 sm:p-6 space-y-6">
          {[
            {
              agentId: 'antigravity' as IdeHostId,
              name: 'Antigravity',
              cards: [
                {
                  caption: 'LoginButton.tsx · Worktree Slice #1',
                  loc: '+12/-0',
                  branch: 'atomik/01-feat-strava-login',
                  header: 'feat(auth): add Strava OAuth LoginButton component',
                  codeLine: '+ <Link href="/api/auth/strava/login">',
                  status: 'merged' as const,
                  pr: 141,
                  pill:
                    step % 2 === 0
                      ? 'Slicing <80 LOC hunk'
                      : 'Pushed PR #141',
                  tint: 'from-[#E4DEFF] via-[#EDE9FE] to-[#DCE8FF]',
                },
                {
                  caption: 'cookieJar.ts · Worktree Slice #2',
                  loc: '+26/-8',
                  branch: 'atomik/02-fix-cookie',
                  header: 'fix(cookie): enforce SameSite lax maxAge bounds',
                  codeLine: "+ sameSite: 'lax', maxAgeSec: 604800",
                  status: 'pr_open' as const,
                  pr: 142,
                  pill:
                    step % 2 === 0
                      ? 'Isolating hotfix hunk'
                      : 'Chaining to #141',
                  tint: 'from-[#DBEAFE] via-[#E8F0FE] to-[#F3E8FF]',
                },
                {
                  caption: 'Implementation plan.md · Worktree Slice #3',
                  loc: '+38/-0',
                  branch: 'atomik/03-docs-plans',
                  header: 'docs(plans): isolate Strava OAuth rollout plan',
                  codeLine: '+ ## OAuth 2.1 Strava callback flow',
                  status: 'pr_open' as const,
                  pr: 143,
                  pill:
                    step % 2 === 0
                      ? 'Separating docs(plans)'
                      : '42/42 checks green',
                  tint: 'from-[#F5F3FF] via-[#E0F2FE] to-[#FEF3C7]/70',
                },
              ],
            },
            {
              agentId: 'claude-code' as IdeHostId,
              name: 'Claude Code',
              cards: [
                {
                  caption: 'ThemeProvider.tsx · Opus Session #1',
                  loc: '+18/-2',
                  branch: 'atomik/01-feat-theme',
                  header: 'feat(theme): lift dark mode state into ThemeProvider',
                  codeLine: "+ const prefersDark = useMediaQuery('(prefers-color-scheme: dark)')",
                  status: 'pr_open' as const,
                  pr: 144,
                  pill:
                    step % 2 === 0
                      ? 'Slicing ThemeProvider'
                      : 'Capped at 20 LOC',
                  tint: 'from-[#F5EBE1] via-[#FAF0E6] to-[#EDE5DC]',
                },
                {
                  caption: 'AppearanceSettings.tsx · Opus Session #2',
                  loc: '+42/-6',
                  branch: 'atomik/02-feat-settings-ui',
                  header: 'feat(settings): add Light / Dark segmented toggle',
                  codeLine: "+ localStorage.setItem('theme', nextMode)",
                  status: 'draft' as const,
                  pr: 145,
                  pill:
                    step % 2 === 0
                      ? 'Rebasing child branch'
                      : 'Moving to PR stack',
                  tint: 'from-[#EDE9E0] via-[#F7EFE8] to-[#E6E1DA]',
                },
                {
                  caption: 'ThemeProvider.test.tsx · Opus Session #3',
                  loc: '+36/-0',
                  branch: 'atomik/03-test-theme',
                  header: 'test(theme): verify system default and localStorage persistence',
                  codeLine: "+ expect(localStorage.getItem('theme')).toBe('dark')",
                  status: 'merged' as const,
                  pr: 146,
                  pill:
                    step % 2 === 0
                      ? 'Isolating unit test spec'
                      : 'Zero noise in code PR',
                  tint: 'from-[#F3ECE4] via-[#EDE6DF] to-[#E2ECE9]',
                },
              ],
            },
          ].map((row, rIdx) => (
            <div key={row.agentId} className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <AgentIcon
                    agentId={row.agentId}
                    sizeClass="w-5 h-5"
                    roundedClass="rounded-md"
                  />
                  <span className="text-sm font-semibold text-[#1D1D1F]">
                    {row.name}
                  </span>
                  <span className="text-xs text-zinc-400 font-medium">
                    3 atomic slices in progress ›
                  </span>
                </div>
                <span className="text-[11px] font-mono text-emerald-700 bg-emerald-50 px-2.5 py-0.5 rounded-full">
                  ● Zero-Click Auto-Commit Active
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {row.cards.map((c, cIdx) => {
                  const tiltClass =
                    (step + rIdx + cIdx) % 2 === 0
                      ? '-rotate-1 scale-[0.99]'
                      : 'rotate-1 scale-[1.01]';
                  const cursorLeft =
                    (step + cIdx) % 2 === 0 ? '34%' : '50%';
                  const cursorTop =
                    (step + rIdx) % 2 === 0 ? '62%' : '46%';

                  return (
                    <div key={c.branch} className="space-y-1.5">
                      <div className="flex items-center justify-between text-[11px] text-zinc-500 px-0.5">
                        <span className="font-medium text-zinc-700 truncate">
                          <span className="text-indigo-400 mr-1">∷</span>
                          {c.caption}
                        </span>
                        <span className="font-mono text-[10px] text-emerald-700 font-semibold">
                          {c.loc}
                        </span>
                      </div>

                      <div
                        className={`relative h-48 rounded-2xl bg-gradient-to-br ${c.tint} p-3.5 flex flex-col justify-between border border-black/[0.05] overflow-hidden`}
                      >
                        <div
                          className={`rounded-xl bg-white/95 border border-black/[0.07] shadow-md p-2.5 space-y-1.5 transition-all duration-700 ease-out ${tiltClass}`}
                        >
                          <div className="flex items-center justify-between gap-2">
                            <span className="text-[10px] font-mono text-zinc-500 truncate">
                              ⑂ {c.branch}
                            </span>
                            <PrStatusBadge status={c.status} prNumber={c.pr} />
                          </div>
                          <p className="text-[11px] font-mono font-semibold text-[#1D1D1F] truncate">
                            {c.header}
                          </p>
                          <div className="px-2 py-0.5 rounded bg-emerald-50 text-emerald-800 font-mono text-[10px] truncate">
                            {c.codeLine}
                          </div>
                        </div>

                        {/* Animated Pointer + Purple Pill */}
                        <div
                          style={{ left: cursorLeft, top: cursorTop }}
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
                            {c.pill}
                          </span>
                        </div>

                        <div className="flex items-center justify-between text-[10px] font-mono text-zinc-600 pt-1">
                          <span>Stacked on GitHub</span>
                          <span className="text-emerald-700 font-semibold">
                            ✓ ≤80 LOC verified
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ===================================================================
          MODE 3: CUSTOM ATOMIKGIT TIME MACHINE VERSION SCRUBBER STAGE
         =================================================================== */}
      {presentationMode === 'time-machine' && (
        <div className="rounded-[28px] bg-[#FAF9F5] border border-black/[0.08] shadow-xl overflow-hidden">
          <div className="px-4 py-3 bg-white border-b border-black/[0.06] flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56]" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E]" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F]" />
              </div>
              <span className="text-xs font-mono text-zinc-500">
                ‹ Repo ·{' '}
                <strong className="text-[#1D1D1F]">
                  {activeTmVersion.branch}
                </strong>
              </span>
            </div>

            <div className="inline-flex p-0.5 rounded-full bg-[#EFECE6] text-xs">
              <button
                type="button"
                onClick={() => setStackViewMode('sliced')}
                className={`px-3 py-1 rounded-full font-semibold cursor-pointer ${
                  stackViewMode === 'sliced'
                    ? 'bg-white text-[#1D1D1F] shadow-2xs'
                    : 'text-zinc-600'
                }`}
              >
                Sliced Stack
              </button>
              <button
                type="button"
                onClick={() => setStackViewMode('raw')}
                className={`px-3 py-1 rounded-full font-semibold cursor-pointer ${
                  stackViewMode === 'raw'
                    ? 'bg-white text-[#1D1D1F] shadow-2xs'
                    : 'text-zinc-600'
                }`}
              >
                Raw Bulk Diff
              </button>
            </div>

            <div className="flex items-center gap-2 text-xs font-medium text-zinc-600">
              <Clock className="w-3.5 h-3.5 text-indigo-600" />
              <span className="font-semibold text-[#1D1D1F]">Time Machine</span>
              <span className="text-zinc-400 font-mono">16 versions</span>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 min-h-[380px]">
            <div className="lg:col-span-8 p-5 sm:p-6 flex flex-col justify-between bg-[#F6F5F0] relative">
              <div className="flex flex-wrap items-center justify-between gap-2 px-3.5 py-2 rounded-xl bg-[#1D1D1F] text-white text-xs shadow-md">
                <span className="font-medium">
                  Viewing commit checkpoint from{' '}
                  <strong className="font-mono text-amber-300">
                    {activeTmVersion.time}
                  </strong>
                </span>
                <div className="flex items-center gap-1.5">
                  <button
                    type="button"
                    onClick={() => onTriggerLiveCommit(activeAgent)}
                    className="px-2.5 py-1 rounded-lg bg-white/15 hover:bg-white/25 text-[11px] font-semibold cursor-pointer"
                  >
                    Cherry-pick slice
                  </button>
                  <button
                    type="button"
                    onClick={() => setStep(0)}
                    className="px-2.5 py-1 rounded-lg bg-white text-[#1D1D1F] text-[11px] font-semibold cursor-pointer"
                  >
                    Back to HEAD
                  </button>
                </div>
              </div>

              <div
                className={`my-4 rounded-2xl bg-gradient-to-br ${activeTmVersion.tint} p-5 border border-black/[0.06] shadow-inner transition-all duration-500`}
              >
                {stackViewMode === 'sliced' ? (
                  <div className="bg-white rounded-2xl p-4 border border-black/[0.07] shadow-md space-y-3">
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-mono font-semibold text-indigo-600">
                          ⑂ {activeTmVersion.branch}
                        </span>
                        <span className="text-xs font-mono text-emerald-700 font-semibold">
                          {activeTmVersion.loc}
                        </span>
                      </div>
                      <PrStatusBadge
                        status={activeTmVersion.status}
                        prNumber={activeTmVersion.prNum}
                      />
                    </div>

                    <div className="text-sm font-mono font-bold text-[#1D1D1F]">
                      {activeTmVersion.header}
                    </div>

                    <div className="p-2.5 rounded-xl bg-[#FAF9F5] border border-black/[0.05] font-mono text-[11px] text-zinc-600 flex items-center justify-between">
                      <span>Isolated file: {activeTmVersion.files[0]}</span>
                      <span className="text-emerald-700 font-semibold">
                        ✓ 100% single-intent
                      </span>
                    </div>
                  </div>
                ) : (
                  <div className="bg-white rounded-2xl p-4 border border-rose-200 shadow-md space-y-2">
                    <div className="flex items-center justify-between text-xs font-mono text-rose-700 font-semibold">
                      <span>
                        BEFORE ATOMIKGIT: 162 LOC Mixed Bulk Working Tree
                      </span>
                      <span>4 mixed intents</span>
                    </div>
                    <p className="text-xs text-zinc-600">
                      pkceCallback.ts (+54), cookieJar.ts (+26),
                      pkceCallback.test.ts (+44), and oauth-pkce-plan.md (+38)
                      were dumped together in one unreviewable diff.
                    </p>
                  </div>
                )}
              </div>

              <div className="bg-white rounded-full px-4 py-2 border border-black/[0.08] shadow-2xs flex items-center justify-between gap-2 text-xs">
                <span className="text-zinc-500 truncate">
                  Rule: Cap every slice ≤80 LOC and chain PRs automatically...
                </span>
                <button
                  type="button"
                  onClick={() => onTriggerLiveCommit(activeAgent)}
                  className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-[#1D1D1F] text-white text-[11px] font-semibold shrink-0 cursor-pointer"
                >
                  <Sparkles className="w-3 h-3 text-amber-300" />
                  <span>Re-slice stack</span>
                </button>
              </div>
            </div>

            <div className="lg:col-span-4 bg-white border-t lg:border-t-0 lg:border-l border-black/[0.06] p-4 space-y-3">
              <div className="text-xs font-semibold text-zinc-400 uppercase tracking-wider font-mono">
                Checkpoints (Click to scrub)
              </div>

              <div className="space-y-2.5">
                {TIME_MACHINE_VERSIONS.map((ver, idx) => {
                  const selected = idx === activeTmIndex;
                  return (
                    <button
                      key={ver.id}
                      type="button"
                      onClick={() => {
                        setStep(idx);
                        setIsPlaying(false);
                      }}
                      className={`w-full text-left p-3 rounded-2xl border transition-all cursor-pointer ${
                        selected
                          ? 'bg-[#F5F3FF] border-indigo-500 ring-2 ring-indigo-500/20 shadow-xs'
                          : 'bg-[#FAF9F5] border-black/[0.05] hover:bg-zinc-100/70'
                      }`}
                    >
                      <div className="flex items-center justify-between text-[11px] font-mono">
                        <span className="font-bold text-[#1D1D1F]">
                          {ver.time} · {ver.agent}
                        </span>
                        <span className="text-emerald-700 font-semibold">
                          {ver.loc}
                        </span>
                      </div>
                      <div className="text-xs font-medium text-zinc-800 truncate mt-0.5">
                        {ver.label}
                      </div>
                      <div className="text-[10px] font-mono text-zinc-400 truncate mt-0.5">
                        {ver.header}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

/**
 * CustomIdeOverlayShowcase
 * Renders the exact, authentic native IDE or CLI workspace for the selected agent
 * (Antigravity, Claude Code, Cursor, Kiro, Codex, VS Code, Windsurf, or Gemini CLI)
 * with live choreographed motion steps.
 */
export const CustomIdeOverlayShowcase: React.FC<{
  activeAgent: IdeHostId;
  onSelectAgent: (agent: IdeHostId) => void;
  onSimulateEdit: (agent: IdeHostId) => void;
}> = ({ activeAgent, onSimulateEdit }) => {
  const [showcaseStep, setShowcaseStep] = useState(0);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setShowcaseStep((prev) => (prev + 1) % 4);
    }, 2800);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <div data-testid={`native-ide-env-${activeAgent}`}>
      <NativeIdeStage
        agentId={activeAgent}
        step={showcaseStep}
        onSimulateEdit={onSimulateEdit}
      />
    </div>
  );
};
