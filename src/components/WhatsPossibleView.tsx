import React from 'react';
import { IdeHostId } from '../types/git';
import { AgentIcon, OttoLogo } from './AgentIcon';
import { Laptop, Smartphone, Watch, Wifi, Battery, Search } from 'lucide-react';

interface WhatsPossibleViewProps {
  onSimulateLiveAgentTick: (ide: IdeHostId) => void;
  onNavigateToHome: () => void;
}

const WORKFLOW_SHOWCASE: {
  title: string;
  agent: IdeHostId;
  agentLabel: string;
  prompt: string;
  branch: string;
  header: string;
  loc: string;
  tint: string;
  caption: string;
}[] = [
  {
    title: 'Hotfix isolation during refactor',
    agent: 'antigravity',
    agentLabel: 'Antigravity IDE',
    prompt:
      'Fix the null exp claim crash in jwtClaims.ts while refactoring the billing webhook.',
    branch: 'atomik/fix-auth-jwt',
    header: 'fix(auth): guard against malformed JWT exp claim',
    loc: '+34 / -11 LOC',
    tint: 'from-[#FEF3C7] via-[#FDE68A]/50 to-[#FCA5A5]/40',
    caption: 'Auto-extracted hotfix into PR #141 for immediate merge',
  },
  {
    title: 'Zero-click test suite pairing',
    agent: 'claude-code',
    agentLabel: 'Claude Code CLI',
    prompt:
      'Write property-based unit specs for SHA-256 idempotency key collision resistance.',
    branch: 'atomik/test-payment-specs',
    header: 'test(payment): verify deterministic SHA-256 key resistance',
    loc: '+64 / -4 LOC',
    tint: 'from-[#18181B] via-[#27272A] to-[#3F3F46] text-white',
    caption: 'Paired automatically behind parent implementation branch',
  },
  {
    title: 'Brainstorm markdown separation',
    agent: 'codex-cli',
    agentLabel: 'OpenAI Codex CLI',
    prompt:
      'Draft Q4 multi-currency ledger settlement notes in docs/ while updating currencyMath.ts.',
    branch: 'atomik/docs-ledger-plan',
    header: 'docs(plans): document multi-currency settlement roadmap',
    loc: '+52 / -6 LOC',
    tint: 'from-[#DCFCE7] via-[#BBF7D0]/60 to-[#DBEAFE]',
    caption: 'Kept brainstorm notes out of production TypeScript PR',
  },
  {
    title: 'Schema → Helper → UI stack',
    agent: 'cursor',
    agentLabel: 'Cursor Composer',
    prompt:
      'Add minor currency columns, extract banker rounding helper, and wire receipt card.',
    branch: 'atomik/feat-ledger-stack',
    header: 'refactor(ledger): extract banker rounding for minor units',
    loc: '+46 / -14 LOC',
    tint: 'from-[#E0E7FF] via-[#EDE9FE] to-[#FCE7F3]',
    caption: 'Chained 3 dependent PRs in topological build order',
  },
  {
    title: 'Strict contract extraction',
    agent: 'vscode',
    agentLabel: 'VS Code + Copilot',
    prompt:
      'Define discriminated union contract for Stripe webhook acknowledgement payloads.',
    branch: 'atomik/refactor-billing-types',
    header: 'refactor(billing): define webhook ack union contract',
    loc: '+39 / -7 LOC',
    tint: 'from-[#BAE6FD] via-[#E0F2FE] to-[#FDE68A]/40',
    caption: 'Isolated pure TypeScript types into 1-minute review PR',
  },
  {
    title: 'Rate-limit burst headers',
    agent: 'windsurf',
    agentLabel: 'Windsurf Cascade',
    prompt:
      'Attach RFC-compliant X-RateLimit-Remaining and Retry-After headers to API gateway.',
    branch: 'atomik/feat-middleware-limit',
    header: 'feat(middleware): attach RFC rate-limit burst headers',
    loc: '+52 / -8 LOC',
    tint: 'from-[#F3E8FF] via-[#E9D5FF]/60 to-[#DBEAFE]',
    caption: 'Verified 100% senior guardrail compliance before push',
  },
  {
    title: 'PKCE S256 challenge verifier',
    agent: 'gemini-cli',
    agentLabel: 'Gemini CLI',
    prompt:
      'Validate RFC 7636 S256 code_verifier challenge length and entropy in auth callback.',
    branch: 'atomik/feat-auth-pkce',
    header: 'feat(auth): validate S256 code_verifier entropy bounds',
    loc: '+48 / -6 LOC',
    tint: 'from-[#E0E7FF] via-[#FCE7F3] to-[#FEF3C7]',
    caption: 'Sliced from terminal session and synced to GitHub',
  },
  {
    title: 'Spec-driven checkout receipt',
    agent: 'kiro',
    agentLabel: 'Kiro Spec IDE',
    prompt:
      'Generate localized minor-unit tax and subtotal receipt rows from checkout spec.',
    branch: 'atomik/feat-checkout-receipt',
    header: 'feat(checkout): render localized minor-unit receipt breakdown',
    loc: '+51 / -9 LOC',
    tint: 'from-[#EDE9FE] via-[#DDD6FE] to-[#F3E8FF]',
    caption: 'Linked Kiro spec directly to atomic PR description',
  },
];

export const WhatsPossibleView: React.FC<WhatsPossibleViewProps> = ({
  onSimulateLiveAgentTick,
  onNavigateToHome,
}) => {
  return (
    <div className="max-w-5xl mx-auto space-y-24 py-6 sm:py-10">
      {/* Hero */}
      <section className="text-center space-y-4 max-w-2xl mx-auto">
        <h1 className="text-4xl sm:text-[56px] font-semibold tracking-[-0.035em] text-[#1D1D1F] leading-[1.08]">
          What’s possible
        </h1>
        <p className="text-base sm:text-lg text-[#71717A] leading-relaxed">
          Every atomic commit, stacked PR, and mobile companion sheet below was created automatically by Otto while an agent was coding. No manual staging, no git flags.
        </p>
      </section>

      {/* 1. One sentence, a whole set (Branching Tree from Screen 22) */}
      <section className="space-y-8">
        <div className="space-y-2 max-w-xl">
          <h2 className="text-2xl sm:text-3xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            One prompt, a whole PR stack
          </h2>
          <p className="text-sm sm:text-base text-[#71717A]">
            One request to your coding agent comes back as a complete, ordered stack: types, core logic, unit tests, and mobile review cards.
          </p>
        </div>

        <div className="space-y-6">
          {/* Top Prompt Card */}
          <div className="max-w-lg mx-auto bg-white rounded-2xl p-4 border border-black/[0.08] shadow-xs flex items-center gap-3">
            <AgentIcon
              agentId="claude-code"
              sizeClass="w-9 h-9"
              roundedClass="rounded-xl"
            />
            <div className="text-xs">
              <div className="font-mono text-zinc-400">You, to Claude Code</div>
              <div className="font-semibold text-[#1D1D1F] text-sm">
                Build webhook HMAC verification, retry queue, unit tests, and architecture notes.
              </div>
            </div>
          </div>

          {/* 4 Branching Output Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              {
                step: '01 · Base Types',
                branch: 'stack/01-refactor-payment',
                header: 'refactor(payment): extract strict idempotency contracts',
                loc: '54 LOC · 1m',
              },
              {
                step: '02 · Core Feature',
                branch: 'stack/02-feat-hmac',
                header: 'feat(payment): verify HMAC-SHA256 signatures',
                loc: '100 LOC · 2m',
              },
              {
                step: '03 · Unit Specs',
                branch: 'stack/03-test-hmac',
                header: 'test(payment): cover stale replay timestamps',
                loc: '66 LOC · 1m',
              },
              {
                step: '04 · Plan Docs',
                branch: 'stack/04-docs-plans',
                header: 'docs(plans): record Q4 settlement architecture',
                loc: '58 LOC · 1m',
              },
            ].map((item, idx) => (
              <div key={idx} className="space-y-2 text-center">
                <div className="rounded-2xl bg-gradient-to-br from-[#DCE7D9] via-[#E6ECE2] to-[#DBEAFE] p-3.5 border border-black/[0.06] shadow-2xs text-left space-y-2">
                  <div className="bg-white rounded-xl p-3 border border-black/[0.05] space-y-1.5">
                    <div className="flex justify-between text-[10px] font-mono text-zinc-400">
                      <span>{item.branch}</span>
                      <span className="text-emerald-700 font-semibold">
                        {item.loc}
                      </span>
                    </div>
                    <div className="text-xs font-mono font-bold text-[#1D1D1F] line-clamp-2">
                      {item.header}
                    </div>
                  </div>
                </div>
                <div className="text-xs font-medium text-zinc-500">
                  {item.step}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 2. Agent Workflows (3-Column Grid with Blue Bubbles Underneath — Screen 22 & 23) */}
      <section className="space-y-6">
        <div className="space-y-2 max-w-xl">
          <h2 className="text-2xl sm:text-3xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Real agent prompts, sliced automatically
          </h2>
          <p className="text-sm sm:text-base text-[#71717A]">
            Click any card below to simulate that exact agent edit and watch Otto slice and push it.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {WORKFLOW_SHOWCASE.map((item, idx) => (
            <div key={idx} className="space-y-3 flex flex-col justify-between">
              <div className="space-y-2.5">
                {/* Visual Stage Card */}
                <button
                  type="button"
                  onClick={() => onSimulateLiveAgentTick(item.agent)}
                  className={`w-full text-left rounded-2xl bg-gradient-to-br ${item.tint} p-5 border border-black/[0.06] h-52 flex flex-col justify-between shadow-xs hover:scale-[1.01] transition-transform cursor-pointer`}
                >
                  <div className="flex items-center justify-between text-[10px] font-mono opacity-90">
                    <span className="inline-flex items-center gap-1.5 font-semibold">
                      <AgentIcon
                        agentId={item.agent}
                        sizeClass="w-5 h-5"
                        roundedClass="rounded-md"
                      />
                      <span>{item.agentLabel}</span>
                    </span>
                    <span>{item.loc}</span>
                  </div>

                  <div className="bg-white text-[#1D1D1F] rounded-xl p-3.5 border border-black/[0.07] shadow-sm space-y-1">
                    <div className="text-[10px] font-mono text-indigo-600 font-semibold">
                      {item.branch}
                    </div>
                    <div className="text-xs font-mono font-bold leading-snug">
                      {item.header}
                    </div>
                  </div>

                  <div className="text-[11px] font-medium flex items-center justify-between">
                    <span>✓ Auto-sliced &amp; stacked</span>
                    <span className="underline">Run live →</span>
                  </div>
                </button>

                <div className="text-xs font-semibold text-[#1D1D1F] px-0.5">
                  {item.title}
                </div>

                {/* Blue iMessage Prompt Bubble Underneath */}
                <div className="bg-[#007AFF] text-white text-xs leading-relaxed px-4 py-3 rounded-2xl rounded-br-xs shadow-2xs">
                  {item.prompt}
                </div>
              </div>

              <div className="text-[11px] text-zinc-400 px-0.5">
                {item.caption}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 3. Devices and frames: Desktop IDE, iPhone, iPad & Watch (Screen 23) */}
      <section className="space-y-6">
        <div className="space-y-2 max-w-xl">
          <h2 className="text-2xl sm:text-3xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Desktop IDE, Mobile &amp; Watch companion
          </h2>
          <p className="text-sm sm:text-base text-[#71717A]">
            Mac IDE overlay, iPhone PR approval sheet, iPad stack board, and Apple Watch live commit complication—all synced in real time so you never block your team.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Scene 1: Mac IDE + iPhone */}
          <div className="space-y-3">
            <div className="rounded-2xl bg-gradient-to-br from-[#FDE68A]/50 via-[#FCA5A5]/40 to-[#C4B5FD]/50 p-5 border border-black/[0.06] h-56 flex items-end gap-2.5 overflow-hidden">
              <div className="flex-1 bg-white rounded-xl p-3 border border-black/10 shadow-md space-y-1.5 h-40">
                <div className="flex items-center gap-1 text-[10px] font-mono text-zinc-400">
                  <Laptop className="w-3 h-3 text-indigo-600" />
                  <span>Mac IDE Overlay</span>
                </div>
                <div className="text-xs font-mono font-bold text-[#1D1D1F]">
                  Antigravity · 3 slices
                </div>
                <div className="text-[10px] font-mono text-zinc-500 bg-zinc-50 p-1.5 rounded">
                  +54 / -9 LOC · PR #141
                </div>
              </div>
              <div className="w-28 bg-[#1D1D1F] text-white rounded-2xl p-2.5 shadow-xl space-y-1.5 h-36 flex flex-col justify-between">
                <div className="text-[9px] font-mono text-zinc-400 flex items-center gap-1">
                  <Smartphone className="w-2.5 h-2.5" />
                  <span>iPhone</span>
                </div>
                <div className="text-[10px] font-semibold">
                  Approve PR #141
                </div>
                <div className="text-[9px] bg-indigo-500 text-white text-center py-1 rounded-full font-semibold">
                  Merged ✓
                </div>
              </div>
            </div>
            <div className="text-xs font-semibold text-[#1D1D1F]">
              Mac IDE and iPhone companion
            </div>
            <div className="bg-[#007AFF] text-white text-xs leading-relaxed px-4 py-2.5 rounded-2xl rounded-br-xs">
              Keep slicing Antigravity edits on my MacBook and push 1-tap PR approvals to my iPhone.
            </div>
          </div>

          {/* Scene 2: iPhone + Apple Watch */}
          <div className="space-y-3">
            <div className="rounded-2xl bg-gradient-to-br from-[#CCFBF1] via-[#BAE6FD]/60 to-[#EDE9FE] p-5 border border-black/[0.06] h-56 flex items-center justify-center gap-3 overflow-hidden">
              <div className="w-36 bg-white rounded-2xl p-3 border-2 border-zinc-800 shadow-md space-y-1.5">
                <div className="text-[9px] font-mono text-zinc-400">iOS Stack</div>
                <div className="text-[11px] font-mono font-bold text-[#1D1D1F]">
                  6 Slices Clean
                </div>
                <div className="text-[10px] text-emerald-700 font-semibold">
                  100% Compliant
                </div>
              </div>
              <div className="w-24 h-28 bg-[#18181B] text-white rounded-3xl border-4 border-zinc-700 p-2.5 flex flex-col justify-between shadow-xl">
                <div className="flex items-center justify-between text-[9px] text-amber-400 font-mono">
                  <Watch className="w-3 h-3" />
                  <span>PR #143</span>
                </div>
                <div className="text-[10px] font-bold leading-tight">
                  Claude Code pushed 64 LOC
                </div>
                <div className="text-[8px] bg-[#007AFF] text-center py-0.5 rounded-full">
                  CI Passing
                </div>
              </div>
            </div>
            <div className="text-xs font-semibold text-[#1D1D1F]">
              Phone and Watch live activity
            </div>
            <div className="bg-[#007AFF] text-white text-xs leading-relaxed px-4 py-2.5 rounded-2xl rounded-br-xs">
              Notify my Apple Watch whenever Claude Code finishes slicing and pushing a stacked PR.
            </div>
          </div>

          {/* Scene 3: Mac, iPad & iPhone */}
          <div className="space-y-3">
            <div className="rounded-2xl bg-gradient-to-br from-[#EDE9FE] via-[#DBEAFE] to-[#E4E9E2] p-5 border border-black/[0.06] h-56 flex items-end justify-between gap-2 overflow-hidden">
              <div className="flex-1 bg-white rounded-xl p-2.5 border border-black/10 shadow-sm h-36 space-y-1">
                <div className="text-[9px] font-mono text-zinc-400">Mac CLI</div>
                <div className="text-[10px] font-mono font-bold text-[#1D1D1F]">
                  codex-cli active
                </div>
                <div className="text-[9px] font-mono text-emerald-700">
                  ✓ 3 branches synced
                </div>
              </div>
              <div className="w-28 bg-white rounded-xl p-2.5 border border-black/10 shadow-md h-40 space-y-1">
                <div className="text-[9px] font-mono text-zinc-400">iPad Board</div>
                <div className="text-[10px] font-mono font-bold text-[#1D1D1F]">
                  PR Dependency Graph
                </div>
                <div className="text-[9px] font-mono text-indigo-600">
                  #141 → #142 → #143
                </div>
              </div>
            </div>
            <div className="text-xs font-semibold text-[#1D1D1F]">
              Mac, iPad and iPhone in one scene
            </div>
            <div className="bg-[#007AFF] text-white text-xs leading-relaxed px-4 py-2.5 rounded-2xl rounded-br-xs">
              Sync my Codex CLI session across Mac, iPad architecture board, and iPhone PR review.
            </div>
          </div>
        </div>
      </section>

      {/* 4. Menu bar shots (Screen 24 macOS Menu Bar Popover) */}
      <section className="space-y-6">
        <div className="space-y-2 max-w-xl">
          <h2 className="text-2xl sm:text-3xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            Menu bar &amp; tray overlay
          </h2>
          <p className="text-sm sm:text-base text-[#71717A]">
            Lives quietly in your macOS menu bar, Windows system tray, or iOS Dynamic Island—showing live LOC budgets and recent agent commits without covering your code editor.
          </p>
        </div>

        <div className="rounded-[28px] bg-gradient-to-br from-[#E9D5FF]/70 via-[#F3E8FF]/60 to-[#FED7AA]/50 border border-black/[0.06] overflow-hidden shadow-sm">
          {/* Simulated macOS Top Menu Bar */}
          <div className="px-6 py-2.5 bg-white/60 backdrop-blur-md border-b border-black/[0.05] flex items-center justify-end gap-4 text-xs font-medium text-[#1D1D1F]">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-black/[0.08] font-mono text-[11px] font-semibold">
              <OttoLogo sizeClass="w-4 h-4" roundedClass="rounded" />
              <span>Otto · 3 slices ready</span>
            </span>
            <Wifi className="w-3.5 h-3.5" />
            <Battery className="w-4 h-4" />
            <Search className="w-3.5 h-3.5" />
            <span className="font-mono text-[11px]">Thu Nov 6 9:41 AM</span>
          </div>

          {/* Dropdown Menu Card */}
          <div className="p-8 flex justify-center">
            <div className="w-full max-w-sm bg-white/95 backdrop-blur-md rounded-2xl border border-black/10 shadow-xl p-3 space-y-2 text-xs">
              <div className="px-2.5 py-1 text-[11px] font-semibold text-zinc-400">
                Active Agent Stream · Antigravity IDE
              </div>
              <div className="px-3 py-2 rounded-xl bg-[#007AFF] text-white font-medium flex items-center justify-between">
                <span>⚡ Commit &amp; Open Stacked PR #143</span>
                <span className="font-mono text-[10px] opacity-90">⌘⇧P</span>
              </div>
              <div className="px-3 py-1.5 text-zinc-700 font-mono text-[11px] flex justify-between">
                <span>feat(payment): HMAC verification</span>
                <span className="text-emerald-700">+54/-9</span>
              </div>
              <div className="px-3 py-1.5 text-zinc-700 font-mono text-[11px] flex justify-between">
                <span>fix(cookie): SameSite lax maxAge</span>
                <span className="text-emerald-700">+26/-8</span>
              </div>
              <div className="border-t border-zinc-100 pt-2 px-3 py-1 flex justify-between text-zinc-500">
                <span>Sync to iOS Companion App</span>
                <span>⌘M</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Bottom CTA */}
      <section className="text-center py-10 space-y-5">
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-b from-[#FDE68A] via-[#FCA5A5] to-[#86EFAC] border border-black/10 text-[#1D1D1F] mx-auto flex items-center justify-center text-2xl font-bold shadow-sm">
          ✦
        </div>
        <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
          One prompt away
        </h2>
        <div>
          <button
            type="button"
            onClick={onNavigateToHome}
            className="px-6 py-3 rounded-full bg-[#232325] hover:bg-black text-white text-sm font-semibold shadow-sm transition-colors cursor-pointer"
          >
            Open Live Studio
          </button>
        </div>
      </section>
    </div>
  );
};
