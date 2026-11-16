import React, { useState } from 'react';
import {
  AtomicCommitUnit,
  IdeAgentProfile,
  IdeHostId,
} from '../types/git';
import { AgentIcon, OttoLogo } from './AgentIcon';
import { Check, Smartphone, Laptop, Sparkles, Layers, Monitor, Terminal, ShieldCheck } from 'lucide-react';

interface WhyThisExistsViewProps {
  ideProfiles: IdeAgentProfile[];
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  onSimulateLiveAgentTick: (ide: IdeHostId) => void;
  onNavigateToFeatures: () => void;
  onNavigateToHome: () => void;
  onOpenInstallModal?: (tab: 'desktop' | 'ide' | 'daemon') => void;
}

const GALLERY_SHOTS = [
  {
    title: 'feat(auth): PKCE verifier exchange',
    sub: 'Antigravity · +54/-9 LOC · Desktop IDE',
    device: 'mac',
    tint: 'from-[#DBEAFE] via-[#E0E7FF] to-[#EDE9FE]',
    tag: 'PR #141 · Merged',
  },
  {
    title: 'fix(cookie): SameSite lax maxAge',
    sub: 'Claude Code · +26/-8 LOC · Mobile Review',
    device: 'iphone',
    tint: 'from-[#EDE9FE] via-[#F3E8FF] to-[#FCE7F3]',
    tag: 'PR #142 · 1m review',
  },
  {
    title: 'docs(plans): Q4 settlement architecture',
    sub: 'Codex CLI · +52/-6 LOC · Isolated note',
    device: 'mac',
    tint: 'from-[#E4E9E2] via-[#EFECE6] to-[#F5EBE1]',
    tag: 'PR #143 · Auto-split',
  },
  {
    title: 'test(payment): HMAC replay specs',
    sub: 'Cursor · +62/-4 LOC · Zero-click push',
    device: 'iphone',
    tint: 'from-[#E0F2FE] via-[#DBEAFE] to-[#EDE9FE]',
    tag: 'PR #144 · Passing',
  },
  {
    title: 'refactor(db): composite ledger index',
    sub: 'Antigravity · +76/-12 LOC · Base branch',
    device: 'mac',
    tint: 'from-[#FEF3C7] via-[#FDE68A]/50 to-[#F3E8FF]',
    tag: 'PR #145 · Stacked',
  },
  {
    title: 'feat(mobile): iOS push approval sheet',
    sub: 'Claude Code · +48/-11 LOC · iPhone & Mac',
    device: 'iphone',
    tint: 'from-[#CCFBF1] via-[#E0F2FE] to-[#DBEAFE]',
    tag: 'PR #146 · Ready',
  },
  {
    title: 'fix(webhook): idempotency collision',
    sub: 'Windsurf · +19/-4 LOC · Hotfix isolated',
    device: 'mac',
    tint: 'from-[#FCE7F3] via-[#F3E8FF] to-[#E0E7FF]',
    tag: 'PR #147 · Urgent',
  },
  {
    title: 'feat(api): sliding window limiter',
    sub: 'VS Code · +52/-6 LOC · Guardrail 100%',
    device: 'iphone',
    tint: 'from-[#E0E7FF] via-[#EDE9FE] to-[#DBEAFE]',
    tag: 'PR #148 · Clean',
  },
];

export const WhyThisExistsView: React.FC<WhyThisExistsViewProps> = ({
  stagedAtomicStack,
  pushedStack,
  onSimulateLiveAgentTick,
  onNavigateToFeatures,
  onNavigateToHome,
  onOpenInstallModal,
}) => {
  const [selectedSessionIdx, setSelectedSessionIdx] = useState(0);
  const allUnits = [...stagedAtomicStack, ...pushedStack];
  const activeUnit = allUnits[selectedSessionIdx] || allUnits[0];

  return (
    <div className="max-w-4xl mx-auto space-y-24 py-6 sm:py-12">
      {/* Screen 2: WHY I MADE THIS */}
      <section className="space-y-12">
        <div className="space-y-5">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            WHY THIS EXISTS
          </div>
          <h1 className="text-3xl sm:text-[52px] font-semibold tracking-[-0.035em] text-[#1D1D1F] leading-[1.08]">
            I ship faster with coding agents than I can commit and review.
          </h1>
          <div className="pt-2 flex items-center gap-3.5">
            <div className="w-14 h-14 rounded-full bg-gradient-to-tr from-[#FDBA74] via-[#FCA5A5] to-[#C4B5FD] p-0.5 shadow-sm">
              <div className="w-full h-full rounded-full bg-[#1D1D1F] text-white flex items-center justify-center text-sm font-bold">
                AG
              </div>
            </div>
            <div className="text-xs text-zinc-500">
              <div className="font-semibold text-[#1D1D1F] text-sm">
                Built for daily AI-native builders
              </div>
              <div>Desktop IDE Overlay + iOS &amp; Android Companion</div>
            </div>
          </div>
        </div>

        {/* I ship across four environments */}
        <div className="space-y-5 pt-4">
          <h2 className="text-2xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            I build across four environments.
          </h2>
          <div className="flex flex-wrap items-center gap-3.5">
            {(
              [
                'antigravity',
                'claude-code',
                'cursor',
                'codex-cli',
                'vscode',
                'windsurf',
                'gemini-cli',
                'kiro',
              ] as IdeHostId[]
            ).map((agentId) => (
              <button
                key={agentId}
                type="button"
                onClick={() => onSimulateLiveAgentTick(agentId)}
                className="p-1.5 rounded-2xl bg-white border border-black/[0.08] shadow-xs hover:scale-105 transition-transform cursor-pointer"
                title={`Simulate ${agentId} commit slice`}
              >
                <AgentIcon
                  agentId={agentId}
                  sizeClass="w-12 h-12"
                  roundedClass="rounded-xl"
                  className="border-0 shadow-none"
                />
              </button>
            ))}
          </div>
        </div>

        {/* Screen 3: I make a lot of commits for them + Visual Gallery Grid */}
        <div className="space-y-6 pt-4">
          <div className="space-y-2">
            <h2 className="text-2xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
              My agents touch dozens of files every hour.
            </h2>
            <p className="text-base sm:text-lg text-[#71717A] max-w-xl leading-relaxed">
              Features, bugfixes, brainstorm notes, and tests. Stopping to stage hunks and write PRs by hand is super time consuming.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
            {GALLERY_SHOTS.map((shot, idx) => (
              <div
                key={idx}
                className={`rounded-2xl bg-gradient-to-br ${shot.tint} p-3.5 border border-black/[0.05] flex flex-col justify-between h-44 shadow-2xs`}
              >
                <div className="flex items-center justify-between text-[10px] font-mono text-zinc-600">
                  <span className="inline-flex items-center gap-1 font-semibold">
                    {shot.device === 'iphone' ? (
                      <Smartphone className="w-3 h-3" />
                    ) : (
                      <Laptop className="w-3 h-3" />
                    )}
                    {shot.device === 'iphone' ? 'Mobile PR' : 'Desktop IDE'}
                  </span>
                  <span className="bg-white/80 px-1.5 py-0.5 rounded text-zinc-800">
                    {shot.tag}
                  </span>
                </div>

                {/* Mini device frame inside gallery tile */}
                <div className="bg-white/95 rounded-xl p-2.5 border border-black/[0.06] shadow-2xs space-y-1">
                  <div className="text-[11px] font-mono font-semibold text-[#1D1D1F] truncate">
                    {shot.title}
                  </div>
                  <div className="text-[10px] text-zinc-500 truncate">
                    {shot.sub}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Screen 4: Current Git GUIs are great, but I don't have time anymore */}
      <section className="space-y-12">
        <div className="space-y-4">
          <h2 className="text-2xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F] max-w-2xl leading-tight">
            Current Git GUIs and IDE source tabs are great, but I don’t have time anymore.
          </h2>
          <p className="text-base sm:text-lg text-[#71717A] max-w-xl leading-relaxed">
            They are made for people who want to stage every line and click commit by hand. I used to have time for that. When prompting Antigravity, I do not now.
          </p>
          <div className="flex items-center gap-3 pt-1">
            <span className="w-12 h-12 rounded-2xl bg-[#27272A] text-white inline-flex items-center justify-center text-xs font-mono font-bold shadow-xs">
              git
            </span>
            <span className="w-12 h-12 rounded-2xl bg-[#0284C7] text-white inline-flex items-center justify-center text-xs font-mono font-bold shadow-xs">
              GUI
            </span>
            <span className="w-12 h-12 rounded-2xl bg-[#0D9488] text-white inline-flex items-center justify-center text-xs font-mono font-bold shadow-xs">
              CLI
            </span>
          </div>
        </div>

        <div className="space-y-5 pt-4">
          <h2 className="text-2xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            So I built one my agents can use.
          </h2>
          <p className="text-base sm:text-lg text-[#71717A]">
            Otto was built for Antigravity, Claude Code, Cursor, and Codex—on desktop and mobile.
          </p>
          <div className="flex flex-wrap items-center gap-3 pt-1">
            <OttoLogo
              sizeClass="w-14 h-14"
              roundedClass="rounded-2xl"
              gradientClass="bg-gradient-to-b from-[#60A5FA] via-[#BAE6FD] to-[#86EFAC]"
            />
            <span className="text-2xl px-1" aria-hidden="true">
              🤝
            </span>
            <AgentIcon
              agentId="antigravity"
              sizeClass="w-14 h-14"
              roundedClass="rounded-2xl"
            />
            <AgentIcon
              agentId="claude-code"
              sizeClass="w-14 h-14"
              roundedClass="rounded-2xl"
            />
            <AgentIcon
              agentId="codex-cli"
              sizeClass="w-14 h-14"
              roundedClass="rounded-2xl"
            />
            <AgentIcon
              agentId="gemini-cli"
              sizeClass="w-14 h-14"
              roundedClass="rounded-2xl"
            />
            <AgentIcon
              agentId="kiro"
              sizeClass="w-14 h-14"
              roundedClass="rounded-2xl"
            />
          </div>
        </div>

        {/* Screen 5: Full 3-Pane Studio Session Window (Desktop + Mobile Preview) */}
        <div className="space-y-2">
          <div className="p-3 sm:p-5 rounded-[28px] bg-gradient-to-br from-[#DBEAFE]/70 via-[#EDE9FE]/60 to-[#FEF3C7]/50 border border-black/[0.05]">
            <div className="bg-[#F6F5F0] rounded-2xl border border-black/[0.08] shadow-lg overflow-hidden grid grid-cols-1 lg:grid-cols-12">
              {/* Left Sidebar: Working on + Completed */}
              <div className="lg:col-span-3 p-4 border-b lg:border-b-0 lg:border-r border-black/[0.06] space-y-4 bg-[#FAF9F5]">
                <div className="p-2.5 rounded-xl bg-white border border-black/[0.06] flex items-center gap-2.5 shadow-2xs">
                  <AgentIcon
                    agentId="antigravity"
                    sizeClass="w-7 h-7"
                    roundedClass="rounded-lg"
                  />
                  <div className="text-xs">
                    <div className="font-semibold text-[#1D1D1F]">Antigravity</div>
                    <div className="text-[10px] text-indigo-600 font-medium">
                      ● Working
                    </div>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <div className="flex items-center justify-between text-[11px] text-zinc-400 font-medium px-1">
                    <span>Working on</span>
                    <span>{stagedAtomicStack.length} in progress</span>
                  </div>
                  {allUnits.slice(0, 4).map((unit, idx) => (
                    <button
                      key={unit.id}
                      type="button"
                      onClick={() => setSelectedSessionIdx(idx)}
                      className={`w-full text-left p-2.5 rounded-xl border text-xs transition-all cursor-pointer ${
                        selectedSessionIdx === idx
                          ? 'bg-white border-indigo-500/60 ring-2 ring-indigo-500/10 shadow-2xs'
                          : 'bg-white/60 hover:bg-white border-black/[0.05]'
                      }`}
                    >
                      <div className="font-mono font-semibold text-[#1D1D1F] truncate text-[11px]">
                        {unit.conventionalHeader}
                      </div>
                      <div className="text-[10px] text-indigo-600 font-mono mt-0.5">
                        ∷ Slicing {unit.totalLoc} LOC
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Center Canvas: Live Desktop + iPhone Mobile Frame */}
              <div className="lg:col-span-6 p-5 flex flex-col justify-between space-y-4 bg-[#F3F1EC]">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-mono text-zinc-500">
                    ∷ Desktop IDE + iOS Companion
                  </span>
                  <div className="inline-flex rounded-full bg-black/[0.06] p-0.5 text-[11px] font-medium">
                    <span className="px-2.5 py-0.5 rounded-full bg-white text-[#1D1D1F] shadow-2xs">
                      Sliced PR
                    </span>
                    <span className="px-2.5 py-0.5 text-zinc-500">Raw Diff</span>
                  </div>
                </div>

                {/* Visual Meadow/Sky Stage with iPhone + Desktop Card */}
                <div className="relative rounded-2xl bg-gradient-to-br from-[#93C5FD]/40 via-[#C4B5FD]/35 to-[#86EFAC]/40 p-5 border border-black/[0.06] flex flex-col items-center justify-center min-h-[250px]">
                  <div className="w-full max-w-xs bg-white rounded-3xl border-4 border-[#1D1D1F] p-4 shadow-xl space-y-2.5">
                    <div className="w-12 h-1.5 bg-[#1D1D1F] rounded-full mx-auto" />
                    <div className="flex items-center justify-between text-[10px] font-mono text-zinc-400">
                      <span>9:41 AM · iOS Companion</span>
                      <span className="text-emerald-700 font-semibold">
                        ≤{activeUnit?.totalLoc || 54} LOC
                      </span>
                    </div>
                    <div className="p-2.5 rounded-xl bg-[#FAF9F5] border border-black/[0.06] space-y-1">
                      <div className="text-xs font-mono font-bold text-[#1D1D1F]">
                        {activeUnit?.conventionalHeader ||
                          'feat(payment): verify HMAC signatures'}
                      </div>
                      <div className="text-[11px] text-zinc-500 font-mono">
                        Branch: {activeUnit?.branchName || 'atomik/feat-payment'}
                      </div>
                    </div>
                  </div>

                  {/* Floating Purple Agent Cursor Bubble */}
                  <div className="mt-3 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#6366F1] text-white text-xs font-medium shadow-md">
                    <span>Antigravity · Slicing &amp; stacking PR</span>
                  </div>
                </div>

                <div className="bg-white rounded-xl p-3 border border-black/[0.06] flex items-center justify-between text-xs">
                  <span className="text-zinc-600 truncate">
                    Activity: Auto-sliced into atomic commit &amp; synced to mobile
                  </span>
                  <button
                    type="button"
                    onClick={() => onSimulateLiveAgentTick('antigravity')}
                    className="text-indigo-600 font-semibold hover:underline shrink-0 ml-2 cursor-pointer"
                  >
                    Simulate tick →
                  </button>
                </div>
              </div>

              {/* Right Sidebar: Time Machine */}
              <div className="lg:col-span-3 p-4 bg-[#FAF9F5] space-y-3">
                <div className="text-xs font-semibold text-[#1D1D1F]">
                  Time Machine
                </div>
                <div className="p-2.5 rounded-xl bg-white border-2 border-indigo-500/70 space-y-1 shadow-2xs">
                  <div className="text-[10px] font-mono text-indigo-600 font-semibold">
                    Now · Atomic Stack
                  </div>
                  <div className="text-[11px] font-mono text-[#1D1D1F] truncate">
                    {activeUnit?.branchName}
                  </div>
                  <div className="text-[10px] text-zinc-400">
                    +{activeUnit?.totalAdditions || 54} / -{activeUnit?.totalDeletions || 9} LOC
                  </div>
                </div>
                <div className="text-[11px] text-zinc-500 leading-relaxed">
                  Every file edit is checkpointed before slicing so you can restore any hunk in one tap.
                </div>
              </div>
            </div>
          </div>
          <p className="text-[11px] font-mono text-zinc-400">
            A real Antigravity + Claude Code session in Otto across Desktop and iOS.
          </p>
        </div>
      </section>

      {/* Screen 6: AGENT FIRST — What does agent-first mean? */}
      <section className="space-y-6">
        <div className="space-y-3">
          <div className="text-[11px] font-mono uppercase tracking-[0.2em] text-zinc-400">
            AGENT FIRST
          </div>
          <h2 className="text-2xl sm:text-4xl font-semibold tracking-[-0.03em] text-[#1D1D1F]">
            What does agent-first mean?
          </h2>
          <p className="text-base sm:text-lg text-[#71717A] max-w-2xl leading-relaxed">
            Otto gives your coding agent the commit, hunk-splitting, and PR-stacking controls. Keep prompting features in your IDE, and review clean PRs on desktop or mobile.{' '}
            <button
              type="button"
              onClick={onNavigateToFeatures}
              className="text-indigo-600 hover:underline font-medium cursor-pointer"
            >
              See the atomic slicing workflow →
            </button>
          </p>
          <p className="text-sm text-[#71717A]">
            A manual Git client would need all the controls on the left. Here is the same workflow through your coding agent.
          </p>
        </div>

        {/* 2-Column Comparison Card with Dark Floating Pill */}
        <div className="relative rounded-3xl border border-black/[0.08] bg-white overflow-hidden shadow-sm grid grid-cols-1 md:grid-cols-2">
          {/* Left: Overwhelming Manual Git GUI Controls */}
          <div className="p-5 bg-[#F4F3EF] border-b md:border-b-0 md:border-r border-black/[0.06] space-y-2.5 text-[10px] font-mono text-zinc-500 select-none opacity-80">
            <div className="font-bold text-zinc-700 uppercase">▾ MANUAL GIT STAGING</div>
            <div className="grid grid-cols-2 gap-2">
              <div className="bg-white p-1.5 rounded border border-black/10">git add -p hunk 1/14</div>
              <div className="bg-white p-1.5 rounded border border-black/10">git stash --keep-index</div>
              <div className="bg-white p-1.5 rounded border border-black/10">git checkout -b stack/01</div>
              <div className="bg-white p-1.5 rounded border border-black/10">git commit -m &quot;feat...&quot;</div>
              <div className="bg-white p-1.5 rounded border border-black/10">git rebase -i --onto</div>
              <div className="bg-white p-1.5 rounded border border-black/10">gh pr create --base</div>
            </div>
            <div className="font-bold text-zinc-700 uppercase pt-2">▾ BRANCH &amp; REBASE MATRIX</div>
            <div className="space-y-1.5">
              <div className="bg-white p-1.5 rounded border border-black/10">Parent branch: main ← stack-1 ← stack-2</div>
              <div className="bg-white p-1.5 rounded border border-black/10">Conflict resolution: manual 3-way merge</div>
              <div className="bg-white p-1.5 rounded border border-black/10">Separate markdown notes from code: manual</div>
            </div>
          </div>

          {/* Right: What You Actually Do */}
          <div className="p-6 sm:p-8 flex flex-col justify-center space-y-4 bg-white">
            <p className="text-base sm:text-lg font-medium text-[#1D1D1F] leading-snug">
              “Add OAuth PKCE callback, fix the cookie expiry bug, and update our architecture notes.”
            </p>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-xs font-semibold text-[#1D1D1F]">
                <OttoLogo sizeClass="w-5 h-5" roundedClass="rounded-md" />
                <span>Otto is working</span>
              </div>
              <ul className="space-y-1.5 text-xs text-zinc-600 pl-1">
                <li className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-indigo-600" />
                  <span>Separating brainstorm .md notes from TypeScript</span>
                </li>
                <li className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-indigo-600" />
                  <span>Slicing 3 atomic commits under 80 LOC each</span>
                </li>
                <li className="flex items-center gap-2">
                  <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                  <span>Pushing stacked PRs #141 → #142 → #143 to GitHub</span>
                </li>
              </ul>
            </div>
          </div>

          {/* Floating Bottom Comparison Pill */}
          <div className="md:col-span-2 py-3 bg-[#FAF9F5] border-t border-black/[0.05] flex justify-center">
            <div className="px-4 py-1.5 rounded-full bg-[#232325] text-white text-[11px] font-mono tracking-wider uppercase">
              🛠️ IF THERE WERE A MANUAL UI → ⚡ WHAT YOU ACTUALLY DO
            </div>
          </div>
        </div>
      </section>

      {/* Screen 7: Bottom CTA with Universal Multi-Platform Installer */}
      <section className="text-center py-12 space-y-6">
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-b from-[#1E1B4B] via-[#312E81] to-[#F59E0B] text-white mx-auto flex items-center justify-center text-2xl font-bold shadow-md">
          ✦
        </div>
        <h2 className="text-3xl sm:text-5xl font-semibold tracking-[-0.03em] text-[#1D1D1F] max-w-lg mx-auto leading-tight">
          This is for builders who ship all day with AI.
        </h2>
        <p className="text-sm sm:text-base text-zinc-500 max-w-md mx-auto">
          Ultra-fast Go daemon (&lt;4ms), Clerk verified authentication, and seamless integration across all 8 agentic IDE environments.
        </p>

        {/* 3 Prominent Sleek CTA Buttons */}
        <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
          <button
            type="button"
            onClick={() => onOpenInstallModal ? onOpenInstallModal('ide') : onNavigateToHome()}
            className="inline-flex items-center gap-2 px-5 py-3 rounded-full bg-[#1D1D1F] hover:bg-black text-white text-xs sm:text-sm font-semibold shadow-xs hover:shadow-md transition-all cursor-pointer group"
          >
            <Layers className="w-4 h-4 text-indigo-400 group-hover:scale-110 transition-transform" />
            <span>Install IDE Extension (.vsix for Cursor, VS Code, Windsurf, Kiro, Antigravity)</span>
          </button>

          <button
            type="button"
            onClick={() => onOpenInstallModal ? onOpenInstallModal('desktop') : onNavigateToHome()}
            className="inline-flex items-center gap-2 px-5 py-3 rounded-full bg-white hover:bg-zinc-50 border border-black/[0.1] text-zinc-900 text-xs sm:text-sm font-medium shadow-2xs transition-all cursor-pointer"
          >
            <Monitor className="w-4 h-4 text-zinc-600" />
            <span>Download Desktop (Flutter Windows / Mac / Linux)</span>
          </button>

          <button
            type="button"
            onClick={() => onOpenInstallModal ? onOpenInstallModal('daemon') : onNavigateToHome()}
            className="inline-flex items-center gap-2 px-4 py-3 rounded-full bg-zinc-100 hover:bg-zinc-200 border border-black/[0.08] text-zinc-800 text-xs sm:text-sm font-mono font-medium transition-all cursor-pointer"
          >
            <Terminal className="w-3.5 h-3.5 text-zinc-500" />
            <span>Run Native Go Daemon (<code className="text-indigo-600 font-semibold">go run cmd/daemon/main.go</code>)</span>
          </button>
        </div>

        <div className="pt-2">
          <button
            type="button"
            onClick={onNavigateToHome}
            className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 hover:underline cursor-pointer"
          >
            ← Or return to Live Studio Workspace
          </button>
        </div>
      </section>
    </div>
  );
};
