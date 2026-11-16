import React, { useState } from 'react';
import { IdeHostId } from '../types/git';
import { AGENT_ICON_ASSETS } from './AgentIcon';
import { PrStatusBadge } from './PrStatusBadge';
import {
  Bug,
  Check,
  ChevronDown,
  ChevronRight,
  Clock,
  Code2,
  FileCode2,
  FileText,
  Files,
  Folder,
  GitBranch,
  GitCommit,
  GitPullRequest,
  Globe,
  Laptop,
  Mic,
  PanelLeft,
  Play,
  Plus,
  Puzzle,
  RefreshCw,
  Search,
  Settings,
  Sparkles,
  Terminal,
} from 'lucide-react';

interface NativeIdeStageProps {
  agentId: IdeHostId;
  step: number;
  onSimulateEdit: (agent: IdeHostId) => void;
}

export const NativeIdeStage: React.FC<NativeIdeStageProps> = ({
  agentId,
  step,
  onSimulateEdit,
}) => {
  const [worktreeMode, setWorktreeMode] = useState<'worktree' | 'local'>('worktree');
  const [kiroActiveTab, setKiroActiveTab] = useState<
    'Requirements' | 'Design' | 'Tasks'
  >('Tasks');
  const [windsurfMode, setWindsurfMode] = useState<'Write' | 'Chat'>('Write');

  const meta = AGENT_ICON_ASSETS[agentId] || AGENT_ICON_ASSETS.antigravity;

  // Choreographed cursor coordinates per IDE & step
  const cursorPositions: Record<
    IdeHostId,
    { x: string; y: string; text: string }[]
  > = {
    antigravity: [
      {
        x: '28%',
        y: '42%',
        text: 'Streaming S256 PKCE verifier in pkceCallback.ts',
      },
      {
        x: '44%',
        y: '58%',
        text: 'Isolating Implementation plan.md → docs(plans)',
      },
      {
        x: '76%',
        y: '46%',
        text: 'Spawning clean Git Worktree (≤80 LOC)',
      },
      {
        x: '74%',
        y: '74%',
        text: 'Auto-stacked PR #141 → #142 → #143',
      },
    ],
    'claude-code': [
      {
        x: '46%',
        y: '34%',
        text: 'Claude Opus reading 4 auth & payment modules',
      },
      {
        x: '54%',
        y: '58%',
        text: 'Slicing idempotency.ts (+54 -9 LOC) → PR #141',
      },
      {
        x: '62%',
        y: '74%',
        text: 'Separating idempotency.test.ts → PR #142',
      },
      {
        x: '82%',
        y: '52%',
        text: 'Synced 3 stacked PRs via Claude post-edit hook',
      },
    ],
    cursor: [
      {
        x: '42%',
        y: '46%',
        text: 'Composer slicing replayStream.ts (+58 -9) → PR #141',
      },
      {
        x: '44%',
        y: '62%',
        text: 'Chaining jwtClaims.ts (+34 -11) → PR #142',
      },
      {
        x: '74%',
        y: '38%',
        text: 'Verifying live SSE preview on localhost:3000',
      },
      {
        x: '72%',
        y: '74%',
        text: 'Cursor CLI daemon rebased child branch #143',
      },
    ],
    kiro: [
      {
        x: '44%',
        y: '36%',
        text: 'Mapping .kiro/specs/tasks.md → atomic commits',
      },
      {
        x: '48%',
        y: '58%',
        text: 'Task 2.1 completed → feat(checkout): receipt tax',
      },
      {
        x: '78%',
        y: '38%',
        text: 'Verifying 42/42 CI checks on PR #142',
      },
      {
        x: '76%',
        y: '68%',
        text: 'Chaining spec task 2.2 → Draft PR #143',
      },
    ],
    'codex-cli': [
      {
        x: '46%',
        y: '38%',
        text: 'Codex agent refactoring currencyMath.ts (+46 -14)',
      },
      {
        x: '52%',
        y: '58%',
        text: 'AST boundary enforced at 60 LOC (≤80 LOC cap)',
      },
      {
        x: '78%',
        y: '44%',
        text: 'Codex PR Sitter chaining PR #142 onto #141',
      },
      {
        x: '76%',
        y: '72%',
        text: 'Zero-click pushed stack to GitHub',
      },
    ],
    vscode: [
      {
        x: '38%',
        y: '42%',
        text: 'Next Edit Suggestion (7 ↳|) accepted in editor',
      },
      {
        x: '48%',
        y: '54%',
        text: 'CodeLens slicing billingContract.ts (46 LOC)',
      },
      {
        x: '42%',
        y: '78%',
        text: 'Integrated terminal auto-pushed PR #142',
      },
      {
        x: '80%',
        y: '48%',
        text: 'Copilot Agent Sessions synced with GitHub stack',
      },
    ],
    windsurf: [
      {
        x: '42%',
        y: '40%',
        text: 'Windsurf Supercomplete (Tab →|) hunk captured',
      },
      {
        x: '46%',
        y: '60%',
        text: 'Isolating rateLimitHeaders.ts (+52 -8 LOC)',
      },
      {
        x: '78%',
        y: '46%',
        text: 'Cascade Write flow slicing 3 modular PRs',
      },
      {
        x: '76%',
        y: '74%',
        text: 'Stacked PR #141 → #142 → #143 synced live',
      },
    ],
    'gemini-cli': [
      {
        x: '36%',
        y: '38%',
        text: 'Gemini 2.5 Pro executing WriteFile tool call',
      },
      {
        x: '44%',
        y: '62%',
        text: 'MCP @atomikgit/daemon slicing 54 LOC diff',
      },
      {
        x: '76%',
        y: '46%',
        text: 'Generating Conventional Commit feat(auth): pkce',
      },
      {
        x: '74%',
        y: '74%',
        text: 'Pushed stacked PR #141 → #142 → #143 from CLI',
      },
    ],
  };

  const activeCursor =
    (cursorPositions[agentId] || cursorPositions.antigravity)[step % 4];

  return (
    <div
      className="relative select-none"
      data-testid={`authentic-ide-stage-${agentId}`}
    >
      {/* =====================================================================
          1. GOOGLE ANTIGRAVITY IDE
          Pure white Google Antigravity editor with Rainbow Aura border,
          5-icon Activity Bar with live Source Control badge (153 -> 3 -> 0),
          Explorer + Tabbed Code Editor with ghost-text streaming & CodeLens,
          and Right Antigravity Worktree + AtomikGit Stacked PR Panel.
         ===================================================================== */}
      {agentId === 'antigravity' && (
        <div className="relative rounded-[24px] p-[2.5px] bg-gradient-to-tr from-[#38BDF8] via-[#FACC15] to-[#4ADE80] shadow-xl">
          <div className="pointer-events-none absolute -inset-1.5 rounded-[28px] bg-gradient-to-r from-sky-400/20 via-amber-300/20 to-emerald-400/20 blur-lg" />

          <div className="relative rounded-[22px] bg-white overflow-hidden border border-black/[0.06] flex flex-col min-h-[430px]">
            {/* Top Antigravity macOS Title Bar */}
            <div className="px-4 py-2 bg-[#F8FAFC] border-b border-zinc-200/80 flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56]" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E]" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F]" />
                <span className="ml-2 font-semibold text-zinc-800 flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-sky-500" />
                  <span>Antigravity IDE — antigravity-core-platform</span>
                </span>
              </div>
              <div className="flex items-center gap-3 font-mono text-[11px] text-zinc-500">
                <span className="px-2 py-0.5 rounded-md bg-indigo-50 text-indigo-700 font-semibold border border-indigo-200/60">
                  ⑂ Worktree Auto-Slice: ≤80 LOC
                </span>
                <button
                  type="button"
                  onClick={() => onSimulateEdit('antigravity')}
                  className="px-2.5 py-1 rounded-lg bg-[#18181B] hover:bg-black text-white font-sans font-semibold text-[11px] cursor-pointer"
                >
                  + Slice live edit
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 flex-1">
              {/* Left 8 Cols: Activity Rail + Editor Canvas */}
              <div className="lg:col-span-8 flex border-b lg:border-b-0 lg:border-r border-zinc-200/80">
                {/* 5-Icon Left Activity Bar */}
                <div className="w-11 bg-[#FAFAFA] border-r border-zinc-200/70 py-3.5 flex flex-col items-center justify-between text-zinc-400 shrink-0">
                  <div className="space-y-4 flex flex-col items-center">
                    <Files className="w-4 h-4 text-zinc-700" />
                    <Search className="w-4 h-4 text-zinc-400" />
                    <div className="relative" title="Source Control">
                      <GitBranch className="w-4 h-4 text-indigo-600" />
                      <span className="absolute -bottom-1.5 -right-2.5 px-1.5 py-0.2 rounded-full bg-[#2563EB] text-white font-sans text-[9px] font-bold leading-tight shadow-2xs">
                        {step === 0 ? '153' : step === 1 ? '3' : '0'}
                      </span>
                    </div>
                    <Bug className="w-4 h-4 text-zinc-400" />
                    <Puzzle className="w-4 h-4 text-zinc-500" />
                  </div>
                  <div className="w-6 h-6 rounded-lg bg-indigo-50 border border-indigo-200 flex items-center justify-center text-[10px] font-bold text-indigo-600">
                    ✦
                  </div>
                </div>

                {/* Main Antigravity Editor */}
                <div className="flex-1 flex flex-col justify-between bg-white min-w-0">
                  <div>
                    {/* Editor Tabs */}
                    <div className="flex items-center border-b border-zinc-200/80 bg-[#F8FAFC] px-2 pt-1.5 gap-1.5 text-xs overflow-x-auto">
                      <div className="px-3 py-1.5 rounded-t-lg bg-white border-t border-x border-zinc-200/80 text-zinc-900 font-semibold flex items-center gap-1.5 shadow-2xs">
                        <span className="text-sky-500 font-bold">TS</span>
                        <span>pkceCallback.ts</span>
                        <span className="text-[10px] font-mono text-emerald-700 bg-emerald-50 px-1.5 py-0.2 rounded">
                          +54 -9
                        </span>
                      </div>
                      <div className="px-3 py-1.5 text-zinc-500 flex items-center gap-1.5">
                        <span className="text-sky-500 font-bold">TS</span>
                        <span>cookieJar.ts</span>
                        <span className="text-[10px] font-mono text-zinc-400">
                          +26 -8
                        </span>
                      </div>
                      <div className="px-3 py-1.5 text-zinc-400 italic flex items-center gap-1.5">
                        <FileText className="w-3.5 h-3.5 text-zinc-400 not-italic" />
                        <span>Implementation plan.md</span>
                        <span className="not-italic text-[9px] font-mono px-1.5 py-0.2 rounded bg-amber-100 text-amber-800">
                          docs(plans)
                        </span>
                      </div>
                    </div>

                    {/* Breadcrumb + AtomikGit Inline CodeLens */}
                    <div className="px-4 py-2 border-b border-zinc-100 flex flex-wrap items-center justify-between gap-2 text-[11px]">
                      <div className="text-zinc-400 flex items-center gap-1 font-sans">
                        <span>src</span>
                        <ChevronRight className="w-3 h-3 text-zinc-300" />
                        <span>auth</span>
                        <ChevronRight className="w-3 h-3 text-zinc-300" />
                        <span className="text-zinc-800 font-medium">
                          pkceCallback.ts
                        </span>
                      </div>
                      <span className="font-mono text-[10.5px] text-indigo-600 bg-indigo-50/80 px-2 py-0.5 rounded">
                        ⑂ AtomikGit Slice #1 · feat(auth): PKCE S256 verifier · 63 LOC ≤ 80 LOC
                      </span>
                    </div>

                    {/* Code Lines with Live Hunk Boundaries */}
                    <div className="p-3.5 font-mono text-[11.5px] leading-[1.65] space-y-1 relative">
                      <div className="flex items-center px-2 text-zinc-600">
                        <span className="w-6 text-right pr-3 text-zinc-400 select-none">
                          1
                        </span>
                        <span>
                          <span className="text-[#7C3AED] italic">import</span>{' '}
                          &#123; verifyChallengeS256, PkceMismatchError &#125;{' '}
                          <span className="text-[#7C3AED] italic">from</span>{' '}
                          <span className="text-[#15803D]">&apos;./crypto&apos;</span>;
                        </span>
                      </div>
                      <div className="flex items-center px-2 text-zinc-600">
                        <span className="w-6 text-right pr-3 text-zinc-400 select-none">
                          2
                        </span>
                        <span>
                          <span className="text-[#7C3AED] italic">import</span>{' '}
                          &#123; enforceSameSiteCookie &#125;{' '}
                          <span className="text-[#7C3AED] italic">from</span>{' '}
                          <span className="text-[#15803D]">&apos;./cookieJar&apos;</span>;
                        </span>
                      </div>

                      {/* Slice #1 Box */}
                      <div className="mt-1.5 rounded-xl border border-emerald-300/90 bg-emerald-50/40 p-2 space-y-0.5">
                        <div className="flex items-center justify-between text-[10px] text-emerald-800 font-semibold pb-1">
                          <span>
                            ⑂ Slice #1 · feat(auth): implement PKCE S256 challenge exchange (54 LOC)
                          </span>
                          <PrStatusBadge status="merged" prNumber={141} />
                        </div>
                        <div className="flex items-center px-1 text-zinc-800">
                          <span className="w-6 text-right pr-3 text-emerald-600">+4</span>
                          <span>
                            <span className="text-[#2563EB] italic">export async function</span>{' '}
                            <strong className="text-zinc-900">exchangePkceCode</strong>
                            (req: AuthCallbackReq) &#123;
                          </span>
                        </div>
                        <div className="flex items-center px-1 text-zinc-800">
                          <span className="w-6 text-right pr-3 text-emerald-600">+5</span>
                          <span className="pl-4">
                            const ok = <span className="text-[#7C3AED]">await</span>{' '}
                            verifyChallengeS256(req.verifier, req.challenge);
                          </span>
                        </div>
                        <div className="flex items-center px-1 text-zinc-800">
                          <span className="w-6 text-right pr-3 text-emerald-600">+6</span>
                          <span className="pl-4">
                            if (!ok) <span className="text-[#B91C1C]">throw new</span>{' '}
                            PkceMismatchError(<span className="text-[#15803D]">&apos;S256_MISMATCH&apos;</span>);
                          </span>
                        </div>
                      </div>

                      {/* Slice #2 Box (Streaming Ghost Text -> Chained Open PR #142) */}
                      <div
                        className={`mt-2 rounded-xl border p-2 space-y-0.5 transition-all ${
                          step === 0
                            ? 'border-sky-300/90 bg-sky-50/40 opacity-80'
                            : 'border-indigo-300/90 bg-indigo-50/35 opacity-100'
                        }`}
                      >
                        <div className="flex items-center justify-between text-[10px] text-indigo-900 font-semibold pb-1">
                          <span>
                            ⑂ Slice #2 · fix(cookie): enforce SameSite lax &amp; 7d maxAge bounds (34 LOC)
                          </span>
                          <PrStatusBadge status="pr_open" prNumber={142} />
                        </div>
                        <div className="flex items-center px-1 text-zinc-800">
                          <span className="w-6 text-right pr-3 text-indigo-600">+11</span>
                          <span className="pl-4">
                            return enforceSameSiteCookie(req.session, &#123; sameSite:{' '}
                            <span className="text-[#15803D]">&apos;lax&apos;</span>, maxAge: 604800 &#125;);
                          </span>
                        </div>
                        <div className="flex items-center px-1 text-zinc-800">
                          <span className="w-6 text-right pr-3 text-indigo-600">+12</span>
                          <span>&#125;</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Bottom Antigravity Status Bar */}
                  <div className="px-4 py-2 bg-[#FAFAFA] border-t border-zinc-200/70 flex flex-wrap items-center justify-between gap-2 text-[11px] font-mono text-zinc-600">
                    <div className="flex items-center gap-3">
                      <span className="inline-flex items-center gap-1 text-indigo-600 font-semibold">
                        <GitBranch className="w-3.5 h-3.5" />
                        <span>main ← atomik/02-fix-cookie</span>
                      </span>
                      <span>All slices ≤ 80 LOC</span>
                    </div>
                    <span className="text-emerald-700 font-semibold">
                      ✓ 0 uncommitted bloat · 3 PRs stacked
                    </span>
                  </div>
                </div>
              </div>

              {/* Right 4 Cols: Antigravity Agent Prompt + New Worktree Isolation + PR Stack */}
              <div className="lg:col-span-4 bg-[#F1F0EC] p-4 flex flex-col justify-between space-y-3">
                <div className="space-y-2.5">
                  <div className="flex items-center justify-between text-xs font-semibold text-zinc-800">
                    <span className="inline-flex items-center gap-1.5">
                      <Folder className="w-3.5 h-3.5 text-zinc-600" />
                      <span>antigravity-core-platform</span>
                    </span>
                    <span className="text-[10px] font-mono text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">
                      Gemini 3.5 Pro
                    </span>
                  </div>

                  {/* Antigravity Prompt Card + Worktree Selector */}
                  <div className="rounded-2xl bg-[#E5E4E0] p-1.5 space-y-1.5">
                    <div className="rounded-xl bg-white border border-black/[0.06] p-3 space-y-2">
                      <div className="text-[11px] text-zinc-500">Active prompt:</div>
                      <p className="text-xs font-medium text-zinc-900 leading-snug">
                        &ldquo;Add OAuth 2.1 PKCE S256 verifier, fix cookie SameSite bounds, and isolate unit tests into stacked PRs.&rdquo;
                      </p>
                    </div>

                    {/* Interactive Local vs New Worktree Switcher */}
                    <div className="px-2 py-1 flex items-center justify-between text-[11px]">
                      <div className="inline-flex items-center gap-1 bg-white/80 p-0.5 rounded-lg border border-black/[0.06]">
                        <button
                          type="button"
                          onClick={() => setWorktreeMode('local')}
                          className={`px-2 py-0.5 rounded-md font-medium flex items-center gap-1 cursor-pointer ${
                            worktreeMode === 'local'
                              ? 'bg-zinc-900 text-white'
                              : 'text-zinc-600'
                          }`}
                        >
                          <Laptop className="w-3 h-3" />
                          <span>Local</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => setWorktreeMode('worktree')}
                          className={`px-2 py-0.5 rounded-md font-medium flex items-center gap-1 cursor-pointer ${
                            worktreeMode === 'worktree'
                              ? 'bg-zinc-900 text-white'
                              : 'text-zinc-600'
                          }`}
                        >
                          <GitBranch className="w-3 h-3" />
                          <span>New Worktree</span>
                        </button>
                      </div>
                      <span className="font-mono text-[10px] text-zinc-600">
                        base: main
                      </span>
                    </div>
                  </div>
                </div>

                {/* Live Stacked PR Queue */}
                <div className="rounded-2xl bg-white border border-black/[0.07] p-3 space-y-2 shadow-2xs">
                  <div className="flex items-center justify-between text-[10px] font-mono uppercase tracking-wider text-zinc-500">
                    <span>AtomikGit Worktree PR Stack</span>
                    <span className="text-emerald-700 font-semibold">3 / 3 Synced</span>
                  </div>
                  <div className="space-y-1.5 text-[11px] font-mono">
                    <div className="p-2 rounded-xl bg-[#FAF8F5] border border-black/[0.05] flex items-center justify-between gap-2">
                      <span className="truncate font-semibold text-zinc-900">
                        feat(auth): PKCE S256 verifier
                      </span>
                      <PrStatusBadge status="merged" prNumber={141} />
                    </div>
                    <div className="p-2 rounded-xl bg-[#FAF8F5] border border-black/[0.05] flex items-center justify-between gap-2">
                      <span className="truncate font-semibold text-zinc-900">
                        fix(cookie): SameSite lax bounds
                      </span>
                      <PrStatusBadge status="pr_open" prNumber={142} />
                    </div>
                    <div className="p-2 rounded-xl bg-[#FAF8F5] border border-black/[0.05] flex items-center justify-between gap-2">
                      <span className="truncate font-semibold text-zinc-900">
                        test(auth): PKCE mismatch spec
                      </span>
                      <PrStatusBadge status="draft" prNumber={143} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          2. CLAUDE CODE DESKTOP APP
          Anthropic's dark #141415 multi-pane desktop shell with [💬 | </>]
          mode toggle, Pinned Worktrees, tool-call trace, inline unified diff
          slicer, and right-hand AtomikGit Stacked PR ledger.
         ===================================================================== */}
      {agentId === 'claude-code' && (
        <div className="rounded-[24px] bg-[#141415] text-zinc-200 border border-white/15 shadow-2xl overflow-hidden grid grid-cols-1 lg:grid-cols-12 min-h-[430px]">
          {/* Left Sidebar */}
          <div className="lg:col-span-3 bg-[#111112] p-3.5 border-b lg:border-b-0 lg:border-r border-white/[0.08] flex flex-col justify-between text-xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
                  <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                  <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
                  <PanelLeft className="w-3.5 h-3.5 text-zinc-500 ml-1.5" />
                </div>
                <div className="inline-flex rounded-lg bg-white/[0.06] p-0.5 border border-white/[0.08] text-[10px]">
                  <span className="px-1.5 py-0.5 text-zinc-400">💬</span>
                  <span className="px-1.5 py-0.5 rounded bg-white/15 text-white font-mono">
                    &lt;/&gt;
                  </span>
                </div>
              </div>

              <div className="space-y-1 pt-1">
                <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-500">
                  Active Worktree Sessions
                </div>
                <div className="px-2.5 py-2 rounded-lg bg-white/[0.09] text-white font-medium flex items-center gap-2 border border-white/10">
                  <GitBranch className="w-3.5 h-3.5 text-[#D97757] shrink-0" />
                  <span className="truncate text-[11px]">
                    Stripe webhook idempotency &amp; retry
                  </span>
                </div>
                <div className="px-2.5 py-1.5 rounded-lg text-zinc-400 flex items-center gap-2">
                  <GitBranch className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                  <span className="truncate text-[11px]">
                    OAuth 2.1 PKCE S256 verifier
                  </span>
                </div>
              </div>

              {/* AtomikGit Hook Status in Sidebar */}
              <div className="rounded-xl bg-[#1A1A1D] border border-white/[0.08] p-2.5 space-y-2">
                <div className="flex items-center justify-between text-[10px] font-mono text-zinc-400">
                  <span>CLAUDE POST-EDIT HOOK</span>
                  <span className="text-emerald-400">● ACTIVE</span>
                </div>
                <div className="space-y-1 text-[11px] font-mono">
                  <div className="flex items-center justify-between">
                    <span className="text-zinc-300 truncate">01-feat-idempotency</span>
                    <PrStatusBadge status="merged" prNumber={141} />
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-zinc-300 truncate">02-fix-retry-jitter</span>
                    <PrStatusBadge status="pr_open" prNumber={142} />
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-zinc-300 truncate">03-test-webhook-spec</span>
                    <PrStatusBadge status="draft" prNumber={143} />
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-3 border-t border-white/[0.07] flex items-center justify-between text-[11px] text-zinc-400">
              <span className="font-mono text-[#D97757]">✻ Claude Code v1.4</span>
              <button
                type="button"
                onClick={() => onSimulateEdit('claude-code')}
                className="px-2 py-1 rounded bg-white/10 hover:bg-white/15 text-white font-semibold cursor-pointer"
              >
                + Slice edit
              </button>
            </div>
          </div>

          {/* Right Main Claude Code Session + Multi-Slice Diff */}
          <div className="lg:col-span-9 bg-[#161618] p-5 flex flex-col justify-between space-y-3.5">
            <div className="space-y-3">
              <div className="flex flex-wrap items-center justify-between gap-2 border-b border-white/[0.07] pb-2.5">
                <div className="text-xs flex items-center gap-2">
                  <strong className="text-white">antigravity-core-platform</strong>
                  <span className="text-zinc-600">/</span>
                  <span className="font-mono text-zinc-300">
                    worktree: atomik/02-fix-retry-jitter
                  </span>
                </div>
                <span className="px-2.5 py-0.5 rounded-full bg-[#D97757]/20 border border-[#D97757]/40 text-[#FDBA74] font-mono text-[10px]">
                  AtomikGit MCP Slicer · Max 80 LOC/commit
                </span>
              </div>

              {/* Prompt Bubble */}
              <div className="p-3 rounded-2xl bg-[#16243E] border border-blue-400/20 text-[#93C5FD] text-xs leading-relaxed">
                Add deterministic SHA-256 idempotency keys to webhook retries, cap exponential backoff jitter, and write property-based unit specs.
              </div>

              {/* Claude Agent Tool Call Trace */}
              <div className="flex flex-wrap items-center gap-2 text-[11px] font-mono text-zinc-400">
                <span className="px-2 py-0.5 rounded bg-white/[0.05] text-zinc-300">
                  ✓ Read 4 files in src/payment/
                </span>
                <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300">
                  ✓ AtomikGit split 146 LOC edit into 3 chained commits
                </span>
              </div>

              {/* Edited File Diff Card #1 & #2 */}
              <div className="rounded-xl bg-[#1C1C1F] border border-white/10 overflow-hidden font-mono text-[11px]">
                <div className="px-3.5 py-2 border-b border-white/[0.07] bg-white/[0.02] flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-zinc-400">Edited</span>
                    <strong className="text-white">src/payment/idempotency.ts</strong>
                    <span className="text-emerald-400">+54</span>
                    <span className="text-rose-400">-9</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-emerald-400 text-[10.5px]">
                      ⑂ feat(payment): SHA-256 idempotency key (63 LOC)
                    </span>
                    <PrStatusBadge status="merged" prNumber={141} />
                  </div>
                </div>

                <div className="p-3 space-y-1 leading-relaxed">
                  <div className="text-zinc-400">
                    <span className="inline-block w-7 text-zinc-600">18</span>
                    <span className="text-rose-400">export function</span>{' '}
                    <span className="text-purple-300">deriveIdempotencyKey</span>
                    (event: WebhookPayload): string &#123;
                  </div>
                  <div className="bg-[#132A20] text-emerald-300 px-2 py-0.5 rounded">
                    <span className="inline-block w-7 text-emerald-500">19 +</span>
                    const digest = createHash(&apos;sha256&apos;).update(`$&#123;event.accountId&#125;:$&#123;event.nonce&#125;`).digest(&apos;hex&apos;);
                  </div>
                  <div className="bg-[#132A20] text-emerald-300 px-2 py-0.5 rounded">
                    <span className="inline-block w-7 text-emerald-500">20 +</span>
                    return `idem_v2_$&#123;digest.slice(0, 32)&#125;`;
                  </div>
                  <div className="text-zinc-400">
                    <span className="inline-block w-7 text-zinc-600">21</span>
                    &#125;
                  </div>
                </div>

                <div className="px-3.5 py-2 border-t border-white/[0.07] bg-white/[0.03] flex flex-wrap items-center justify-between gap-2 text-[10.5px]">
                  <span className="text-sky-300">
                    Next Slice #2: src/payment/retryBackoff.ts (+38 -6 LOC) → fix(payment): cap retry jitter
                  </span>
                  <PrStatusBadge status="pr_open" prNumber={142} />
                </div>
              </div>
            </div>

            {/* Bottom Composer Bar */}
            <div className="flex items-center justify-between rounded-xl bg-[#222225] border border-white/10 px-3.5 py-2 text-xs text-zinc-400">
              <span>Ask Claude Code or type /atomik to configure slice rules…</span>
              <div className="flex items-center gap-2 text-[11px]">
                <strong className="text-white">Claude Opus 4.6</strong>
                <span className="text-zinc-500">·</span>
                <span className="text-emerald-400 font-mono">Auto-Stack ON</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          3. CURSOR DESKTOP ("MISSION CONTROL") + DOCKED CURSOR CLI
          3-column Cursor workspace: Parallel Agent Queue on left, Composer
          multi-file atomic slicer in center, live localhost preview + docked
          Cursor CLI daemon terminal on right.
         ===================================================================== */}
      {agentId === 'cursor' && (
        <div className="rounded-[24px] bg-[#181818] text-zinc-200 border border-white/15 shadow-2xl overflow-hidden min-h-[430px] flex flex-col">
          {/* Cursor Desktop Header */}
          <div className="px-4 py-2 bg-[#121212] border-b border-white/[0.08] flex items-center justify-between text-xs">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
              <span className="ml-2 font-semibold text-zinc-200">
                Cursor Mission Control — antigravity-core-platform
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[11px] font-mono text-emerald-400">
                3 Parallel Agents → 3 Stacked PRs
              </span>
              <button
                type="button"
                onClick={() => onSimulateEdit('cursor')}
                className="px-2.5 py-1 rounded-lg bg-white/10 hover:bg-white/15 text-white font-semibold text-[11px] cursor-pointer"
              >
                + Slice edit
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 flex-1">
            {/* Col 1: Mission Control Parallel Agent Queue */}
            <div className="lg:col-span-3 bg-[#141414] p-3.5 border-b lg:border-b-0 lg:border-r border-white/[0.08] space-y-3 text-xs">
              <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-500">
                IN PROGRESS · COMPOSER AGENTS
              </div>
              <div className="p-2.5 rounded-xl bg-white/[0.07] border border-white/10 space-y-1">
                <div className="text-white font-medium flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-amber-400" />
                    <span>Webhook SSE Stream</span>
                  </span>
                  <span className="text-[10px] font-mono text-emerald-400">67 LOC</span>
                </div>
                <div className="text-[10.5px] font-mono text-zinc-400">
                  ⑂ atomik/01-feat-replay-sse
                </div>
              </div>

              <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-500 pt-1">
                STACKED &amp; READY FOR REVIEW (3)
              </div>
              <div className="space-y-1.5 text-[11px]">
                <div className="p-2.5 rounded-xl bg-white/[0.04] border border-white/[0.06] space-y-1">
                  <div className="flex items-center justify-between text-zinc-200 font-medium">
                    <span className="truncate">1. SSE Replay Stream</span>
                    <PrStatusBadge status="merged" prNumber={141} />
                  </div>
                  <div className="text-[10px] font-mono text-zinc-400">
                    src/payment/replayStream.ts (+58 -9)
                  </div>
                </div>

                <div className="p-2.5 rounded-xl bg-white/[0.04] border border-white/[0.06] space-y-1">
                  <div className="flex items-center justify-between text-zinc-200 font-medium">
                    <span className="truncate">2. JWT Exp Claim Guard</span>
                    <PrStatusBadge status="pr_open" prNumber={142} />
                  </div>
                  <div className="text-[10px] font-mono text-zinc-400">
                    src/auth/jwtClaims.ts (+34 -11)
                  </div>
                </div>

                <div className="p-2.5 rounded-xl bg-white/[0.04] border border-white/[0.06] space-y-1">
                  <div className="flex items-center justify-between text-zinc-200 font-medium">
                    <span className="truncate">3. Replay Unit Specs</span>
                    <PrStatusBadge status="draft" prNumber={143} />
                  </div>
                  <div className="text-[10px] font-mono text-zinc-400">
                    src/payment/replayStream.test.ts (+44 -0)
                  </div>
                </div>
              </div>
            </div>

            {/* Col 2: Center Composer Thread with Atomic Hunk Cards */}
            <div className="lg:col-span-5 p-4 border-b lg:border-b-0 lg:border-r border-white/[0.08] flex flex-col justify-between space-y-3 text-xs">
              <div className="space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-white">
                    Composer · Multi-File Atomic Slicer
                  </span>
                  <span className="font-mono text-[10px] text-indigo-300 bg-indigo-500/15 px-2 py-0.5 rounded">
                    ≤80 LOC Rule Enforced
                  </span>
                </div>

                <div className="p-2.5 rounded-xl bg-white/[0.05] border border-white/10 text-zinc-200 text-xs">
                  Stream webhook replay progress over SSE, guard null JWT exp claims, and isolate tests.
                </div>

                {/* File Diff Pills Mapped to Stacked PRs */}
                <div className="space-y-2 pt-1">
                  <div className="p-2.5 rounded-xl bg-[#141416] border border-emerald-500/30 space-y-1 font-mono text-[11px]">
                    <div className="flex items-center justify-between">
                      <span className="flex items-center gap-1.5 text-white font-semibold">
                        <FileCode2 className="w-3.5 h-3.5 text-emerald-400" />
                        <span>src/payment/replayStream.ts</span>
                        <span className="text-emerald-400">+58</span>
                        <span className="text-rose-400">-9</span>
                      </span>
                      <PrStatusBadge status="merged" prNumber={141} />
                    </div>
                    <div className="text-[10px] text-zinc-400">
                      feat(payment): stream live webhook replay progress over SSE
                    </div>
                  </div>

                  <div className="p-2.5 rounded-xl bg-[#141416] border border-sky-500/30 space-y-1 font-mono text-[11px]">
                    <div className="flex items-center justify-between">
                      <span className="flex items-center gap-1.5 text-white font-semibold">
                        <FileCode2 className="w-3.5 h-3.5 text-sky-400" />
                        <span>src/auth/jwtClaims.ts</span>
                        <span className="text-emerald-400">+34</span>
                        <span className="text-rose-400">-11</span>
                      </span>
                      <PrStatusBadge status="pr_open" prNumber={142} />
                    </div>
                    <div className="text-[10px] text-zinc-400">
                      fix(auth): guard malformed JWT exp claim on refresh
                    </div>
                  </div>

                  <div className="p-2.5 rounded-xl bg-[#141416] border border-amber-500/30 space-y-1 font-mono text-[11px]">
                    <div className="flex items-center justify-between">
                      <span className="flex items-center gap-1.5 text-white font-semibold">
                        <FileCode2 className="w-3.5 h-3.5 text-amber-400" />
                        <span>src/payment/replayStream.test.ts</span>
                        <span className="text-emerald-400">+44</span>
                        <span className="text-rose-400">-0</span>
                      </span>
                      <PrStatusBadge status="draft" prNumber={143} />
                    </div>
                    <div className="text-[10px] text-zinc-400">
                      test(payment): verify SSE reconnect &amp; JWT guard
                    </div>
                  </div>
                </div>
              </div>

              <div className="rounded-xl bg-white/[0.04] border border-white/10 px-3 py-2 flex items-center justify-between text-[11px] text-zinc-400">
                <span>∞ Composer Agent · Claude 3.7 Sonnet</span>
                <span className="text-emerald-400 font-mono">0 manual git commands</span>
              </div>
            </div>

            {/* Col 3: Right Inspector + Docked Cursor CLI Terminal */}
            <div className="lg:col-span-4 bg-[#151517] p-4 flex flex-col justify-between space-y-3">
              <div className="space-y-2">
                <div className="flex items-center justify-between text-[11px] text-zinc-400 border-b border-white/[0.08] pb-2 font-mono">
                  <span>Stack Dependency Graph</span>
                  <Globe className="w-3.5 h-3.5 text-zinc-500" />
                </div>
                <div className="p-3 rounded-xl bg-[#1C1C1F] border border-white/10 font-mono text-[11px] space-y-1.5">
                  <div className="flex items-center justify-between text-zinc-300">
                    <span>main</span>
                    <span className="text-zinc-500">base</span>
                  </div>
                  <div className="pl-3 border-l-2 border-purple-500/60 flex items-center justify-between text-purple-300">
                    <span>↳ #141 feat(payment)</span>
                    <span>67 LOC · Merged</span>
                  </div>
                  <div className="pl-6 border-l-2 border-emerald-500/60 flex items-center justify-between text-emerald-300">
                    <span>↳ #142 fix(auth)</span>
                    <span>45 LOC · Open</span>
                  </div>
                  <div className="pl-9 border-l-2 border-amber-500/60 flex items-center justify-between text-amber-300">
                    <span>↳ #143 test(payment)</span>
                    <span>44 LOC · Draft</span>
                  </div>
                </div>
              </div>

              {/* Docked Cursor CLI + AtomikGit Terminal */}
              <div className="rounded-xl bg-[#0E0E10] border border-white/15 shadow-xl p-3 font-mono text-[10.5px] space-y-1.5">
                <div className="flex items-center justify-between border-b border-white/10 pb-1.5 text-zinc-400">
                  <span>Cursor CLI · Background Daemon</span>
                  <span className="text-emerald-400">● Live Rebase</span>
                </div>
                <div className="text-zinc-300 space-y-1 leading-relaxed">
                  <div>
                    <span className="text-sky-400">$</span> atomik watch --cursor-composer
                  </div>
                  <div className="text-emerald-400">
                    ✓ Auto-rebased #142 &amp; #143 onto main after #141 merged
                  </div>
                  <div className="text-zinc-400">
                    ✓ CI checks green across all 3 stacked branches
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          4. KIRO IDE (Spec-Driven Development `.kiro/specs/` -> Stacked PRs)
          Deep aubergine #131217 Kiro workspace: Requirements | Design | Tasks
          spec editor mapped 1-to-1 to atomic commits and GitHub PR checks.
         ===================================================================== */}
      {agentId === 'kiro' && (
        <div className="rounded-[24px] bg-[#131217] text-zinc-200 border border-purple-400/20 shadow-2xl overflow-hidden min-h-[430px] flex flex-col">
          {/* Kiro Top Bar */}
          <div className="px-4 py-2 bg-[#181620] border-b border-white/[0.08] flex flex-wrap items-center justify-between gap-2 text-xs">
            <div className="flex items-center gap-2">
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
              </div>
              <span className="px-2 py-0.5 rounded bg-white/[0.07] text-zinc-200 font-medium">
                🏠 Local
              </span>
              <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300 font-mono text-[11px]">
                ● Kiro Spec Engine
              </span>
            </div>

            <div className="px-4 py-1 rounded-lg bg-white/[0.05] border border-white/10 text-zinc-400 text-[11px] font-mono">
              ⌘K — .kiro/specs/oauth-pkce/tasks.md
            </div>

            <button
              type="button"
              onClick={() => onSimulateEdit('kiro')}
              className="px-2.5 py-1 rounded-lg bg-[#9333EA] hover:bg-[#7E22CE] text-white font-semibold text-[11px] cursor-pointer"
            >
              + Run Spec Slice
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 flex-1">
            {/* Left Col: Kiro Specs & Stacked PR Sessions */}
            <div className="lg:col-span-3 bg-[#15131B] p-3.5 border-b lg:border-b-0 lg:border-r border-white/[0.08] space-y-3 text-xs">
              <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-400">
                .KIRO / SPECS / OAUTH-PKCE
              </div>
              <div className="space-y-1 font-mono text-[11px]">
                <div className="px-2.5 py-1.5 rounded-lg text-zinc-400 flex items-center justify-between">
                  <span>📄 requirements.md</span>
                  <span className="text-emerald-400">EARS ✓</span>
                </div>
                <div className="px-2.5 py-1.5 rounded-lg text-zinc-400 flex items-center justify-between">
                  <span>📐 design.md</span>
                  <span className="text-emerald-400">Synced</span>
                </div>
                <div className="px-2.5 py-1.5 rounded-lg bg-purple-500/20 border border-purple-400/30 text-white font-semibold flex items-center justify-between">
                  <span>☑ tasks.md</span>
                  <span className="text-purple-300">3 PRs</span>
                </div>
              </div>

              <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-400 pt-2">
                SPEC-LINKED PR STACK
              </div>
              <div className="space-y-1.5 text-[11px]">
                <div className="p-2 rounded-lg bg-white/[0.04] flex items-center justify-between">
                  <span className="truncate text-zinc-200">Task 1 · PKCE S256</span>
                  <PrStatusBadge status="merged" prNumber={141} />
                </div>
                <div className="p-2 rounded-lg bg-purple-500/15 border border-purple-400/30 flex items-center justify-between">
                  <span className="truncate text-white font-medium">Task 2 · Cookie Lax</span>
                  <PrStatusBadge status="pr_open" prNumber={142} />
                </div>
                <div className="p-2 rounded-lg bg-white/[0.04] flex items-center justify-between">
                  <span className="truncate text-zinc-200">Task 3 · Unit Specs</span>
                  <PrStatusBadge status="draft" prNumber={143} />
                </div>
              </div>
            </div>

            {/* Center Col: Requirements | Design | Tasks Spec Editor */}
            <div className="lg:col-span-5 bg-[#191721] p-4 border-b lg:border-b-0 lg:border-r border-white/[0.08] space-y-3 text-xs">
              <div className="flex items-center justify-between border-b border-white/[0.08] pb-2.5">
                <div className="flex items-center gap-1 bg-white/[0.05] p-0.5 rounded-lg">
                  {(['Requirements', 'Design', 'Tasks'] as const).map((tab) => (
                    <button
                      key={tab}
                      type="button"
                      onClick={() => setKiroActiveTab(tab)}
                      className={`px-2.5 py-1 rounded-md text-[11px] font-medium cursor-pointer transition-colors ${
                        kiroActiveTab === tab
                          ? 'bg-purple-600 text-white'
                          : 'text-zinc-400 hover:text-white'
                      }`}
                    >
                      {tab}
                    </button>
                  ))}
                </div>
                <span className="text-[10.5px] font-mono text-purple-300">
                  1 Task = 1 Atomic PR
                </span>
              </div>

              <div className="space-y-2.5">
                <div className="p-3 rounded-xl bg-[#211E2B] border border-emerald-500/30 space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-white flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-emerald-400" />
                      <span>Task 1.1: Implement PKCE S256 Challenge Verifier</span>
                    </span>
                    <span className="font-mono text-[10px] text-emerald-400">54 LOC · PR #141</span>
                  </div>
                  <p className="text-[11px] text-zinc-400 pl-5">
                    AtomikGit committed <code className="text-purple-300">feat(auth): implement PKCE S256 verifier</code> and merged cleanly.
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-[#211E2B] border border-purple-400/40 space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-white flex items-center gap-1.5">
                      <Sparkles className="w-3.5 h-3.5 text-purple-400" />
                      <span>Task 1.2: Enforce Cookie SameSite=Lax &amp; MaxAge</span>
                    </span>
                    <span className="font-mono text-[10px] text-sky-400">34 LOC · PR #142</span>
                  </div>
                  <p className="text-[11px] text-zinc-400 pl-5">
                    Sliced into <code className="text-purple-300">atomik/02-fix-cookie-bounds</code> (≤80 LOC cap verified).
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-[#211E2B] border border-white/10 space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-zinc-200 flex items-center gap-1.5">
                      <Clock className="w-3.5 h-3.5 text-amber-400" />
                      <span>Task 1.3: Property-Based PKCE &amp; Cookie Specs</span>
                    </span>
                    <span className="font-mono text-[10px] text-amber-400">44 LOC · PR #143</span>
                  </div>
                  <p className="text-[11px] text-zinc-400 pl-5">
                    Isolated test suite into stacked Draft PR #143 awaiting Task 1.2 merge.
                  </p>
                </div>
              </div>
            </div>

            {/* Right Col: Kiro Changes & GitHub PR Checks */}
            <div className="lg:col-span-4 bg-[#15131B] p-4 flex flex-col justify-between space-y-3 text-xs">
              <div className="space-y-2.5">
                <div className="flex items-center justify-between border-b border-white/[0.08] pb-2">
                  <span className="font-semibold text-white">⑂ Spec Changes &amp; CI</span>
                  <PrStatusBadge status="pr_open" prNumber={142} />
                </div>

                <div className="rounded-xl bg-[#1E1B26] border border-white/10 p-3 space-y-2">
                  <div className="font-mono text-[11px] text-white font-semibold">
                    fix(cookie): enforce SameSite lax and 7d maxAge bounds
                  </div>
                  <div className="text-[11px] text-emerald-400 flex items-center justify-between font-mono">
                    <span>✓ All spec invariants passed</span>
                    <span>42 / 42 checks</span>
                  </div>
                </div>

                <div className="space-y-1.5 font-mono text-[11px] text-zinc-300">
                  <div className="flex items-center justify-between px-2 py-1 rounded bg-white/[0.04]">
                    <span>TS src/auth/pkceCallback.ts</span>
                    <span className="text-emerald-400">+54 -9 (#141)</span>
                  </div>
                  <div className="flex items-center justify-between px-2 py-1 rounded bg-purple-500/15 border border-purple-400/30">
                    <span>TS src/auth/cookieJar.ts</span>
                    <span className="text-sky-300">+26 -8 (#142)</span>
                  </div>
                  <div className="flex items-center justify-between px-2 py-1 rounded bg-white/[0.04]">
                    <span>TS src/auth/pkceCallback.test.ts</span>
                    <span className="text-amber-300">+44 -0 (#143)</span>
                  </div>
                </div>
              </div>

              <div className="rounded-xl bg-[#1E1B26] border border-white/10 px-3 py-2 flex items-center justify-between text-[11px] font-mono text-zinc-400">
                <span>.kiro/hooks/atomikgit.hook</span>
                <span className="text-emerald-400">Auto-Push ON</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          5. OPENAI CODEX DESKTOP + PR SITTER WORKSPACE
          Matte dark #171717 OpenAI Codex app actively slicing a multi-file
          monorepo diff into 3 stacked PRs with live terminal & PR Sitter review.
         ===================================================================== */}
      {agentId === 'codex-cli' && (
        <div className="rounded-[24px] bg-[#171717] text-zinc-200 border border-white/15 shadow-2xl overflow-hidden grid grid-cols-1 lg:grid-cols-12 min-h-[430px]">
          {/* Left Codex Sidebar */}
          <div className="lg:col-span-3 bg-[#121212] p-3.5 border-b lg:border-b-0 lg:border-r border-white/[0.08] flex flex-col justify-between text-xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
                  <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                  <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
                  <span className="ml-1.5 font-semibold text-white">Codex Desktop ⌄</span>
                </div>
                <span className="font-mono text-[10px] px-1.5 py-0.5 rounded bg-white/10 text-zinc-300">
                  o3-pro
                </span>
              </div>

              <div className="space-y-1 pt-1">
                <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-500">
                  PR Sitter · Active Worktrees
                </div>
                <div className="p-2 rounded-lg bg-white/[0.08] border border-white/10 space-y-0.5">
                  <div className="text-white font-medium truncate">
                    Ledger Minor-Unit Rounding
                  </div>
                  <div className="text-[10px] font-mono text-emerald-400">
                    3 Atomic PRs Stacked · 0 Bloat
                  </div>
                </div>
                <div className="p-2 rounded-lg text-zinc-400 space-y-0.5">
                  <div className="truncate">Prevent duplicate checkout orders</div>
                  <div className="text-[10px] font-mono text-zinc-500">
                    PR #140 Merged
                  </div>
                </div>
              </div>

              <div className="space-y-1.5 pt-2 border-t border-white/[0.07] text-[11px] font-mono">
                <div className="text-[10px] text-zinc-500 uppercase">
                  Monorepo Targets
                </div>
                <div className="flex items-center justify-between text-zinc-300">
                  <span>📁 packages/ledger</span>
                  <span className="text-emerald-400">≤80 LOC</span>
                </div>
                <div className="flex items-center justify-between text-zinc-400">
                  <span>📁 packages/checkout</span>
                  <span>Synced</span>
                </div>
              </div>
            </div>

            <button
              type="button"
              onClick={() => onSimulateEdit('codex-cli')}
              className="w-full py-2 rounded-xl bg-white text-black font-semibold text-xs hover:bg-zinc-200 transition-colors cursor-pointer"
            >
              + Simulate Codex Edit
            </button>
          </div>

          {/* Center + Right Codex Active Execution & PR Sitter Stack */}
          <div className="lg:col-span-9 bg-[#1B1B1B] p-5 flex flex-col justify-between space-y-3.5">
            <div className="space-y-3">
              {/* Header */}
              <div className="flex flex-wrap items-center justify-between gap-2 border-b border-white/[0.08] pb-2.5">
                <div className="flex items-center gap-2">
                  <span className="w-6 h-6 rounded-lg border border-white/30 inline-flex items-center justify-center font-mono text-xs font-bold text-white">
                    &gt;_
                  </span>
                  <div>
                    <div className="text-xs font-semibold text-white">
                      Extract Banker&apos;s Rounding Math &amp; Currency Specs
                    </div>
                    <div className="text-[10.5px] font-mono text-zinc-400">
                      $ codex --full-auto &quot;Extract JPY/USD/EUR minor-unit rounding&quot;
                    </div>
                  </div>
                </div>
                <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/15 border border-emerald-400/30 text-emerald-300 font-mono text-[10.5px]">
                  ⑂ AtomikGit PR Sitter: Active
                </span>
              </div>

              {/* Split View: Diff Hunk on Left + Stacked PR Sitter on Right */}
              <div className="grid grid-cols-1 md:grid-cols-12 gap-3.5">
                <div className="md:col-span-7 rounded-xl bg-[#121212] border border-white/10 overflow-hidden font-mono text-[11px]">
                  <div className="px-3 py-1.5 border-b border-white/[0.07] flex items-center justify-between text-zinc-300">
                    <span>src/ledger/currencyMath.ts</span>
                    <span className="text-emerald-400">+46 -14 (60 LOC)</span>
                  </div>
                  <div className="p-3 space-y-1 leading-relaxed">
                    <div className="text-zinc-500">
                      @@ -12,6 +12,18 @@ export function roundMinorUnits
                    </div>
                    <div className="bg-[#3A1D1E] text-rose-300 px-2 py-0.5 rounded">
                      - return Math.round(amount * 100) / 100;
                    </div>
                    <div className="bg-[#132A20] text-emerald-300 px-2 py-0.5 rounded">
                      + const factor = CURRENCY_DECIMALS[currency] ?? 2;
                    </div>
                    <div className="bg-[#132A20] text-emerald-300 px-2 py-0.5 rounded">
                      + return bankersRoundHalfEven(amount, factor);
                    </div>
                    <div className="text-zinc-400 pt-1">
                      // AtomikGit capped hunk at 60 LOC &amp; pushed PR #141
                    </div>
                  </div>
                </div>

                {/* Right PR Sitter Stack */}
                <div className="md:col-span-5 rounded-xl bg-[#141414] border border-white/10 p-3 space-y-2">
                  <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-400 flex justify-between">
                    <span>Codex Stacked PRs</span>
                    <span className="text-emerald-400">3 Chained</span>
                  </div>
                  <div className="space-y-1.5 text-[11px] font-mono">
                    <div className="p-2 rounded-lg bg-white/[0.04] flex items-center justify-between gap-2">
                      <span className="truncate text-zinc-200">
                        refactor(ledger): currencyMath
                      </span>
                      <PrStatusBadge status="merged" prNumber={141} />
                    </div>
                    <div className="p-2 rounded-lg bg-white/[0.06] border border-white/10 flex items-center justify-between gap-2">
                      <span className="truncate text-white">
                        feat(checkout): minor-unit tax
                      </span>
                      <PrStatusBadge status="pr_open" prNumber={142} />
                    </div>
                    <div className="p-2 rounded-lg bg-white/[0.04] flex items-center justify-between gap-2">
                      <span className="truncate text-zinc-200">
                        test(ledger): JPY/EUR rounding
                      </span>
                      <PrStatusBadge status="draft" prNumber={143} />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Bottom Codex Composer Bar */}
            <div className="rounded-xl bg-[#121212] border border-white/10 px-3.5 py-2 flex flex-wrap items-center justify-between gap-2 text-[11px] text-zinc-400">
              <div className="flex items-center gap-3 font-mono">
                <span>📁 openai/monorepo ⌄</span>
                <span>⑂ worktree/ledger-rounding</span>
              </div>
              <div className="flex items-center gap-2">
                <strong className="text-white">Codex o3-pro</strong>
                <span>·</span>
                <span className="text-emerald-400 font-mono">Auto-Slice ≤80 LOC</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          6. VISUAL STUDIO CODE (Workbench + Next Edit `7 ↳|` + Terminal)
          Full VS Code dark #1E1E1E workbench with Explorer tree, Monaco editor
          with `7 ↳|` Next Edit Suggestion inline diff, integrated Terminal,
          and right-side GitHub Copilot + AtomikGit Stack Sessions pane.
         ===================================================================== */}
      {agentId === 'vscode' && (
        <div className="rounded-[24px] bg-[#1E1E1E] text-zinc-200 border border-white/15 shadow-2xl overflow-hidden grid grid-cols-1 lg:grid-cols-12 min-h-[430px]">
          {/* Left Explorer Sidebar */}
          <div className="lg:col-span-3 bg-[#181818] p-3.5 border-b lg:border-b-0 lg:border-r border-white/[0.08] font-mono text-[11px] flex flex-col justify-between">
            <div className="space-y-2.5">
              <div className="flex items-center gap-1.5 pb-1">
                <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
                <span className="ml-1 text-[10.5px] text-zinc-300 font-sans font-semibold">
                  VS Code — antigravity-core
                </span>
              </div>
              <div className="text-[10px] text-zinc-500 uppercase tracking-wider">
                EXPLORER: WORKSPACE
              </div>
              <div className="space-y-1 text-zinc-400">
                <div>⌄ 📂 src</div>
                <div className="pl-3">⌄ 📂 types</div>
                <div className="pl-6 text-white bg-[#2A2D2E] px-2 py-1 rounded flex items-center justify-between">
                  <span>
                    <span className="text-sky-400">TS</span> billingContract.ts
                  </span>
                  <span className="text-[9.5px] text-emerald-400">46 LOC</span>
                </div>
                <div className="pl-3">⌄ 📂 payment</div>
                <div className="pl-6 px-2 py-0.5">
                  <span className="text-sky-400">TS</span> webhookHandler.ts
                </div>
                <div className="pl-6 px-2 py-0.5">
                  <span className="text-amber-400">TS</span> billingContract.test.ts
                </div>
              </div>
            </div>

            <button
              type="button"
              onClick={() => onSimulateEdit('vscode')}
              className="w-full py-1.5 rounded-lg bg-[#007ACC] hover:bg-[#0062A3] text-white font-sans font-semibold text-xs cursor-pointer"
            >
              + Trigger Next Edit Slice
            </button>
          </div>

          {/* Center Editor + Integrated Terminal */}
          <div className="lg:col-span-6 bg-[#1E1E1E] border-b lg:border-b-0 lg:border-r border-white/[0.08] flex flex-col justify-between font-mono text-[11px]">
            <div>
              {/* Editor Tab Bar */}
              <div className="flex items-center justify-between bg-[#181818] border-b border-white/[0.08] px-3 py-1.5 text-[11px]">
                <div className="flex items-center gap-3">
                  <span className="text-white font-semibold border-t-2 border-[#007ACC] pt-0.5">
                    <span className="text-sky-400">TS</span> billingContract.ts
                  </span>
                  <span className="text-zinc-500">webhookHandler.ts</span>
                </div>
                <span className="text-[10px] text-emerald-400">
                  ⑂ AtomikGit CodeLens: 46 / 80 LOC
                </span>
              </div>

              {/* Editor Code with `7 ↳|` Next Edit Suggestion */}
              <div className="p-3.5 space-y-1 leading-relaxed">
                <div className="flex gap-3 text-zinc-500">
                  <span className="w-6 text-right">6</span>
                  <span>// Discriminated union for billing webhook acks</span>
                </div>

                <div className="flex items-center gap-2 bg-[#3A1D1E] border border-rose-500/30 rounded px-1.5 py-0.5">
                  <span className="px-1.5 py-0.2 rounded bg-[#0D4754] border border-cyan-400 text-cyan-200 font-bold text-[10px]">
                    7 ↳|
                  </span>
                  <span className="text-zinc-200 truncate">
                    <span className="text-rose-400">export type</span>{' '}
                    <span className="text-emerald-300">WebhookAck</span> = &#123; status: string &#125;;
                  </span>
                </div>

                <div className="flex items-center gap-2 bg-[#163622] border border-emerald-500/40 px-2 py-1 rounded">
                  <span className="w-6 text-right text-emerald-400">+8</span>
                  <span className="text-emerald-200 truncate">
                    <span className="text-rose-300">export type</span>{' '}
                    <span className="text-emerald-300">WebhookAck</span> =
                    | &#123; ok: <span className="text-sky-300">true</span>; receiptId: string &#125;
                  </span>
                </div>

                <div className="flex items-center gap-2 bg-[#163622] border border-emerald-500/40 px-2 py-1 rounded">
                  <span className="w-6 text-right text-emerald-400">+9</span>
                  <span className="text-emerald-200 truncate">
                    &nbsp;&nbsp;| &#123; ok: <span className="text-sky-300">false</span>; retryAfterSec: number &#125;;
                  </span>
                </div>
              </div>
            </div>

            {/* Bottom VS Code Integrated Terminal */}
            <div className="bg-[#181818] border-t border-white/[0.08] p-3 space-y-1 text-[10.5px]">
              <div className="flex items-center gap-4 text-zinc-500 pb-1">
                <span className="text-white border-b border-[#007ACC] pb-0.5">
                  TERMINAL
                </span>
                <span>OUTPUT</span>
                <span>PROBLEMS (0)</span>
              </div>
              <div className="text-zinc-300">
                $ atomikgit watch --vscode-nes --max-loc 80
              </div>
              <div className="text-emerald-400">
                ✓ Sliced billingContract.ts (+39 -7 LOC) → Committed &amp; opened PR #142
              </div>
            </div>
          </div>

          {/* Right Copilot Edits & Stacked PRs Pane */}
          <div className="lg:col-span-3 bg-[#181818] p-3.5 flex flex-col justify-between text-xs">
            <div className="space-y-2.5">
              <div className="font-semibold text-white border-b border-white/[0.08] pb-2 flex items-center justify-between">
                <span>Agent Sessions · Stack</span>
                <span className="text-[10px] font-mono text-sky-400">Synced</span>
              </div>

              <div className="space-y-2 text-[11px] font-mono">
                <div className="p-2 rounded-lg bg-white/[0.04] space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-zinc-200 truncate">1. Type Contract</span>
                    <PrStatusBadge status="merged" prNumber={141} />
                  </div>
                  <div className="text-[10px] text-zinc-400">
                    refactor(billing): +39 -7 LOC
                  </div>
                </div>

                <div className="p-2 rounded-lg bg-[#007ACC]/15 border border-[#007ACC]/40 space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-white font-semibold truncate">2. Handler Guard</span>
                    <PrStatusBadge status="pr_open" prNumber={142} />
                  </div>
                  <div className="text-[10px] text-sky-300">
                    feat(billing): +42 -5 LOC
                  </div>
                </div>

                <div className="p-2 rounded-lg bg-white/[0.04] space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-zinc-200 truncate">3. Contract Tests</span>
                    <PrStatusBadge status="draft" prNumber={143} />
                  </div>
                  <div className="text-[10px] text-zinc-400">
                    test(billing): +36 -0 LOC
                  </div>
                </div>
              </div>
            </div>

            <div className="rounded-lg bg-[#222222] border border-white/10 p-2 text-[10px] text-zinc-400 font-mono">
              VS Code status: ⑂ atomik/02-feat-handler
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          7. WINDSURF IDE + CASCADE AGENT FLOW
          Authentic Codeium Windsurf IDE (#121619) with left File Explorer,
          center Monaco editor featuring Windsurf's signature `Tab →|`
          Supercomplete inline diff & AtomikGit Hunk Guard, and right-hand
          Windsurf Cascade (`Write` | `Chat`) multi-step flow panel!
         ===================================================================== */}
      {agentId === 'windsurf' && (
        <div className="rounded-[24px] bg-[#121619] text-zinc-100 border border-teal-400/20 shadow-2xl overflow-hidden min-h-[430px] flex flex-col">
          {/* Windsurf Top Title Bar */}
          <div className="px-4 py-2 bg-[#0E1114] border-b border-white/[0.08] flex flex-wrap items-center justify-between gap-2 text-xs">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
              <span className="ml-2 font-semibold text-teal-300 flex items-center gap-1.5">
                <span>〰</span>
                <span>Windsurf IDE — Cascade Flow + AtomikGit</span>
              </span>
            </div>
            <div className="flex items-center gap-2.5">
              <span className="px-2 py-0.5 rounded bg-teal-500/15 border border-teal-400/30 text-teal-300 font-mono text-[10.5px]">
                ↳| Flow Eagerness: Atomic ≤80 LOC
              </span>
              <button
                type="button"
                onClick={() => onSimulateEdit('windsurf')}
                className="px-2.5 py-1 rounded-lg bg-teal-500 hover:bg-teal-400 text-black font-semibold text-[11px] cursor-pointer"
              >
                + Cascade Slice
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 flex-1">
            {/* Col 1: Windsurf File Explorer */}
            <div className="lg:col-span-3 bg-[#0F1316] p-3.5 border-b lg:border-b-0 lg:border-r border-white/[0.08] font-mono text-[11px] space-y-3">
              <div className="text-[10px] text-zinc-500 uppercase tracking-wider">
                EXPLORER · MIDDLEWARE
              </div>
              <div className="space-y-1.5 text-zinc-400">
                <div className="px-2 py-1.5 rounded bg-teal-500/15 border border-teal-400/30 text-white flex items-center justify-between gap-2">
                  <span className="truncate">
                    <span className="text-teal-400">TS</span> rateLimitHeaders.ts
                  </span>
                  <span className="text-teal-300 text-[10px] whitespace-nowrap shrink-0">
                    +52 -8
                  </span>
                </div>
                <div className="px-2 py-1 rounded text-zinc-300 flex items-center justify-between gap-2">
                  <span className="truncate">
                    <span className="text-sky-400">TS</span> tokenBucket.ts
                  </span>
                  <span className="text-emerald-400 text-[10px] whitespace-nowrap shrink-0">
                    +34 -4
                  </span>
                </div>
                <div className="px-2 py-1 rounded text-zinc-400 flex items-center justify-between gap-2">
                  <span className="truncate">
                    <span className="text-amber-400">TS</span> rateLimit.test.ts
                  </span>
                  <span className="text-amber-300 text-[10px] whitespace-nowrap shrink-0">
                    +41 -0
                  </span>
                </div>
              </div>

              <div className="pt-2 border-t border-white/[0.07] space-y-1.5">
                <div className="text-[10px] text-zinc-500 uppercase">
                  CASCADE COMMIT CADENCE
                </div>
                <div className="p-2 rounded-lg bg-white/[0.04] text-[10.5px] text-zinc-300 space-y-1">
                  <div className="flex justify-between">
                    <span>Max Hunk Size:</span>
                    <span className="text-teal-300 font-semibold">80 LOC</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Auto-Stack PRs:</span>
                    <span className="text-emerald-400 font-semibold">Enabled</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Col 2: Center Windsurf Editor with Supercomplete `→|` Inline Diff */}
            <div className="lg:col-span-5 bg-[#121619] p-4 border-b lg:border-b-0 lg:border-r border-white/[0.08] flex flex-col justify-between font-mono text-[11px]">
              <div className="space-y-2.5">
                <div className="flex items-center justify-between gap-2 border-b border-white/[0.08] pb-2">
                  <span className="text-white font-semibold truncate">
                    src/middleware/rateLimitHeaders.ts
                  </span>
                  <span className="px-2 py-0.5 rounded bg-[#0D4754] border border-cyan-400 text-cyan-200 text-[10px] font-bold whitespace-nowrap shrink-0">
                    Tab →| Next Hunk
                  </span>
                </div>

                <div className="space-y-1 leading-relaxed">
                  <div className="text-zinc-500 truncate">
                    14 &nbsp;export function attachRateLimitHeaders(res: Response, bucket: Bucket) &#123;
                  </div>
                  <div className="bg-[#132A20] border border-emerald-500/30 px-2 py-1 rounded text-emerald-300 truncate">
                    15 + &nbsp;&nbsp;res.setHeader(&apos;X-RateLimit-Limit&apos;, String(bucket.capacity));
                  </div>
                  <div className="bg-[#132A20] border border-emerald-500/30 px-2 py-1 rounded text-emerald-300 truncate">
                    16 + &nbsp;&nbsp;res.setHeader(&apos;X-RateLimit-Remaining&apos;, String(Math.max(0, bucket.remaining)));
                  </div>
                  <div className="bg-[#0D4754]/50 border border-teal-400/40 px-2 py-1 rounded text-teal-200 flex items-center justify-between gap-2">
                    <span className="truncate">
                      17 + &nbsp;&nbsp;res.setHeader(&apos;Retry-After&apos;, String(bucket.resetInSeconds));
                    </span>
                    <span className="px-1.5 py-0.5 rounded bg-teal-400 text-black font-bold text-[9.5px] whitespace-nowrap shrink-0">
                      →| 60 LOC
                    </span>
                  </div>
                  <div className="text-zinc-500">18 &nbsp;&#125;</div>
                </div>
              </div>

              <div className="rounded-xl bg-[#0E1114] border border-white/10 p-2.5 flex items-center justify-between text-[10.5px] text-zinc-400">
                <span>⑂ atomik/02-feat-ratelimit-headers</span>
                <span className="text-teal-300">✓ Hunk isolated &amp; pushed</span>
              </div>
            </div>

            {/* Col 3: Right Windsurf Cascade (`Write` / `Chat`) Panel */}
            <div className="lg:col-span-4 bg-[#0F1316] p-4 flex flex-col justify-between space-y-3 text-xs">
              <div className="space-y-2.5">
                <div className="flex items-center justify-between border-b border-white/[0.08] pb-2">
                  <span className="font-semibold text-white flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-teal-400" />
                    <span>Cascade Flow</span>
                  </span>
                  <div className="inline-flex rounded-lg bg-white/[0.06] p-0.5 text-[10.5px]">
                    {(['Write', 'Chat'] as const).map((m) => (
                      <button
                        key={m}
                        type="button"
                        onClick={() => setWindsurfMode(m)}
                        className={`px-2 py-0.5 rounded-md font-medium cursor-pointer ${
                          windsurfMode === m
                            ? 'bg-teal-500 text-black font-semibold'
                            : 'text-zinc-400'
                        }`}
                      >
                        {m}
                      </button>
                    ))}
                  </div>
                </div>

                <p className="text-[11px] text-zinc-400 leading-relaxed">
                  Cascade edited 3 files (139 LOC total). AtomikGit automatically split the flow into 3 reviewable stacked PRs:
                </p>

                <div className="space-y-1.5 font-mono text-[11px]">
                  <div className="p-2 rounded-xl bg-white/[0.04] border border-white/[0.06] flex items-center justify-between gap-2">
                    <span className="truncate text-zinc-200">
                      1. feat(limit): tokenBucket core
                    </span>
                    <PrStatusBadge status="merged" prNumber={141} />
                  </div>
                  <div className="p-2 rounded-xl bg-teal-500/15 border border-teal-400/30 flex items-center justify-between gap-2">
                    <span className="truncate text-white font-semibold">
                      2. feat(headers): RFC Retry-After
                    </span>
                    <PrStatusBadge status="pr_open" prNumber={142} />
                  </div>
                  <div className="p-2 rounded-xl bg-white/[0.04] border border-white/[0.06] flex items-center justify-between gap-2">
                    <span className="truncate text-zinc-200">
                      3. test(limit): burst window spec
                    </span>
                    <PrStatusBadge status="draft" prNumber={143} />
                  </div>
                </div>
              </div>

              <div className="rounded-xl bg-[#161B20] border border-white/10 px-3 py-2 flex items-center justify-between text-[11px] text-zinc-400">
                <span>Continue Cascade flow…</span>
                <span className="font-mono text-teal-300">⌘I</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          8. GOOGLE GEMINI CLI (`@google/gemini-cli`) TERMINAL WORKSPACE
          Authentic Google Gemini CLI terminal interface (#0D1117):
          - Iconic blue-purple-pink `✦ GEMINI CLI` header frame
          - `gemini-2.5-pro` + MCP Server `@atomikgit/mcp-daemon [CONNECTED]`
          - Boxed tool-call execution cards (`WriteFile`, `atomikgit_slice_stack`)
          - Side-by-side unified diff & live GitHub PR Stack table
          - Bottom Gemini CLI prompt box (`> /atomik stack --auto-push`)
         ===================================================================== */}
      {agentId === 'gemini-cli' && (
        <div className="rounded-[24px] bg-[#0B0E14] p-4 sm:p-5 border border-white/15 shadow-2xl min-h-[430px] flex flex-col justify-between font-mono text-xs text-zinc-100">
          {/* Terminal Window Bar */}
          <div className="flex flex-wrap items-center justify-between gap-2 pb-3 border-b border-white/10">
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-[#FF5F56]" />
              <span className="w-3 h-3 rounded-full bg-[#FFBD2E]" />
              <span className="w-3 h-3 rounded-full bg-[#27C93F]" />
              <span className="ml-2 text-zinc-300 text-[11px]">
                gemini — ~/antigravity-core-platform — zsh (120×38)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="px-2 py-0.5 rounded bg-sky-500/15 border border-sky-400/30 text-sky-300 text-[10.5px]">
                MCP: @atomikgit/daemon ●
              </span>
              <button
                type="button"
                onClick={() => onSimulateEdit('gemini-cli')}
                className="px-2.5 py-1 rounded-lg bg-gradient-to-r from-sky-500 to-indigo-500 text-white font-sans font-semibold text-[11px] cursor-pointer"
              >
                + Run CLI Slice
              </button>
            </div>
          </div>

          {/* Authentic Gemini CLI Banner Box */}
          <div className="my-3 rounded-xl border border-[#60A5FA]/40 bg-gradient-to-r from-[#1E293B]/70 via-[#1E1B4B]/70 to-[#31102F]/60 px-4 py-2.5 flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <span className="text-lg bg-gradient-to-r from-[#60A5FA] via-[#A855F7] to-[#EC4899] bg-clip-text text-transparent font-black">
                ✦ GEMINI CLI
              </span>
              <span className="text-[11px] text-zinc-300">
                v0.3.4 · <strong className="text-white">gemini-2.5-pro</strong> (1M context)
              </span>
            </div>
            <div className="text-[10.5px] text-emerald-300">
              ✓ Loaded 4 tools from <span className="underline">atomikgit-mcp</span> (max 80 LOC/commit)
            </div>
          </div>

          {/* Main CLI Output: Tool Call + Diff on Left, Stacked PR Table on Right */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 my-auto">
            {/* Left 7 Cols: Prompt + Gemini Tool Execution Box */}
            <div className="lg:col-span-7 space-y-2.5">
              <div className="text-[11.5px]">
                <span className="text-[#60A5FA] font-bold">&gt; </span>
                <span className="text-white">
                  Validate RFC 7636 PKCE S256 code_verifier entropy and push stacked PRs
                </span>
              </div>

              {/* Gemini CLI Boxed Tool Call */}
              <div className="rounded-xl border border-white/15 bg-[#131722] p-3 space-y-1.5 text-[11px]">
                <div className="flex items-center justify-between gap-2 text-sky-300 border-b border-white/10 pb-1.5">
                  <span className="truncate">
                    ╭─ ✔ WriteFile src/auth/pkceVerifier.ts (+48 -6 LOC)
                  </span>
                  <span className="text-emerald-400 whitespace-nowrap shrink-0">
                    54 LOC ≤ 80 LOC
                  </span>
                </div>
                <div className="space-y-0.5 pt-0.5 leading-relaxed">
                  <div className="text-zinc-400 truncate">
                    <span className="inline-block w-6 text-zinc-600">14</span>
                    export function assertValidPkceVerifier(v: string): void &#123;
                  </div>
                  <div className="bg-[#3A1D1E] text-rose-200 px-2 py-0.5 rounded truncate">
                    <span className="inline-block w-6 text-rose-400">15</span>- if (v.length &lt; 32) throw new Error(&apos;short&apos;);
                  </div>
                  <div className="bg-[#163824] text-emerald-200 px-2 py-0.5 rounded truncate">
                    <span className="inline-block w-6 text-emerald-400">15</span>+ if (v.length &lt; 43 || v.length &gt; 128) &#123;
                  </div>
                  <div className="bg-[#163824] text-emerald-200 px-2 py-0.5 rounded truncate">
                    <span className="inline-block w-6 text-emerald-400">16</span>+ &nbsp;&nbsp;throw new PkceEntropyError(&apos;RFC7636_BOUNDS&apos;);
                  </div>
                  <div className="bg-[#163824] text-emerald-200 px-2 py-0.5 rounded">
                    <span className="inline-block w-6 text-emerald-400">17</span>+ &#125;
                  </div>
                </div>
              </div>
            </div>

            {/* Right 5 Cols: MCP @atomikgit/daemon Stack Output */}
            <div className="lg:col-span-5 rounded-xl border border-indigo-400/30 bg-[#131722] p-3 flex flex-col justify-between space-y-2 text-[11px]">
              <div className="space-y-2">
                <div className="text-indigo-300 border-b border-white/10 pb-1.5 flex items-center justify-between gap-2">
                  <span className="truncate">╭─ ✔ MCP: atomikgit_slice_stack</span>
                  <span className="text-emerald-400 whitespace-nowrap shrink-0">
                    0 clicks
                  </span>
                </div>

                <div className="space-y-1.5">
                  <div className="p-2 rounded-lg bg-white/[0.04] flex items-center justify-between gap-2">
                    <div className="truncate">
                      <div className="text-white font-semibold truncate">
                        feat(auth): RFC 7636 S256 verifier
                      </div>
                      <div className="text-[10px] text-zinc-400">
                        atomik/01-feat-pkce · +48 -6 LOC
                      </div>
                    </div>
                    <PrStatusBadge status="merged" prNumber={141} />
                  </div>

                  <div className="p-2 rounded-lg bg-white/[0.06] border border-sky-400/30 flex items-center justify-between gap-2">
                    <div className="truncate">
                      <div className="text-white font-semibold truncate">
                        fix(cookie): SameSite lax bounds
                      </div>
                      <div className="text-[10px] text-sky-300">
                        atomik/02-fix-cookie · +26 -8 LOC
                      </div>
                    </div>
                    <PrStatusBadge status="pr_open" prNumber={142} />
                  </div>

                  <div className="p-2 rounded-lg bg-white/[0.04] flex items-center justify-between gap-2">
                    <div className="truncate">
                      <div className="text-white font-semibold truncate">
                        test(auth): entropy boundary spec
                      </div>
                      <div className="text-[10px] text-zinc-400">
                        atomik/03-test-pkce · +44 -0 LOC
                      </div>
                    </div>
                    <PrStatusBadge status="draft" prNumber={143} />
                  </div>
                </div>
              </div>

              <div className="text-[10px] text-emerald-400 pt-1 border-t border-white/10">
                ╰─ All 3 branches pushed to origin &amp; linked on GitHub
              </div>
            </div>
          </div>

          {/* Bottom Gemini CLI Input Box + Status Line */}
          <div className="pt-3 space-y-1.5">
            <div className="rounded-lg border border-[#60A5FA]/50 bg-[#131722] px-3 py-2 flex items-center justify-between text-[11.5px]">
              <span>
                <span className="text-[#A855F7] font-bold">&gt; </span>
                <span className="text-zinc-300">
                  /atomik status --branch main←atomik/02-fix-cookie
                </span>
              </span>
              <span className="text-[10px] text-zinc-500">Enter ↵</span>
            </div>
            <div className="flex flex-wrap items-center justify-between text-[10px] text-zinc-500 px-1">
              <span>~/antigravity-core-platform (atomik/02-fix-cookie*)</span>
              <span>gemini-2.5-pro · /mcp (atomikgit) · Sandbox: Seatbelt</span>
            </div>
          </div>
        </div>
      )}

      {/* Choreographed Floating Moonjar-Style Pointer Arrow + Purple Action Pill */}
      <div
        style={{
          left: activeCursor.x,
          top: activeCursor.y,
        }}
        className="pointer-events-none absolute z-30 transition-all duration-700 ease-out hidden sm:flex items-start gap-1"
      >
        <svg
          width="16"
          height="16"
          viewBox="0 0 16 16"
          fill="none"
          className="drop-shadow-md -mt-1 -ml-1 shrink-0"
        >
          <path
            d="M2.5 2L7.2 13.5L9.3 8.8L14 6.7L2.5 2Z"
            fill="#6366F1"
            stroke="white"
            strokeWidth="1.5"
            strokeLinejoin="round"
          />
        </svg>
        <span className="px-3 py-1 rounded-full bg-[#6366F1] text-white text-xs font-semibold shadow-xl whitespace-nowrap border border-white/20">
          {meta.shortName} · {activeCursor.text}
        </span>
      </div>
    </div>
  );
};
