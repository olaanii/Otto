import React, { useState } from 'react';
import { AntigravityPromptEvent } from '../types/git';
import { parseRawPatchOrPromptInput } from '../utils/atomicEngine';
import { Terminal, Zap, CheckCircle2, AlertCircle } from 'lucide-react';

interface PromptStreamViewProps {
  promptStream: AntigravityPromptEvent[];
  daemonActive: boolean;
  onToggleDaemon: () => void;
  onInjectPromptChanges: (payload: {
    promptText: string;
    category: 'feature' | 'bugfix' | 'brainstorm' | 'refactor' | 'plan';
    rawFilesInput: string;
    autoPushImmediately: boolean;
  }) => void;
}

const PRESET_SCENARIOS = [
  {
    label: 'Feature + Bugfix + Brainstorm Burst',
    promptText:
      'Add rate-limiter middleware for API routes, fix off-by-one token bucket bug, and document Q4 scaling brainstorm notes',
    category: 'feature' as const,
    rawFilesInput: [
      'src/middleware/rateLimiter.ts | +64 -8 | Implement sliding window Redis rate limiter',
      'src/middleware/tokenBucket.ts | +28 -11 | Fix off-by-one refill timestamp bug',
      'src/middleware/rateLimiter.test.ts | +52 -0 | Verify 429 burst header behavior',
      'docs/scaling-brainstorm.md | +41 -3 | Brainstorm multi-region rate limit sync goals',
    ].join('\n'),
  },
  {
    label: 'Database Refactor + Coupled Spec',
    promptText:
      'Extract tenant isolation query builder and add unit tests for cross-tenant guard',
    category: 'refactor' as const,
    rawFilesInput: [
      'src/db/tenantQuery.ts | +58 -19 | Extract strict tenantId scoping wrapper',
      'src/db/tenantQuery.test.ts | +46 -4 | Assert missing tenantId throws TenantIsolationError',
    ].join('\n'),
  },
  {
    label: 'Pure Brainstorming & Product Roadmap',
    promptText:
      'Brainstorm next-gen webhook observability goals and milestone breakdown',
    category: 'brainstorm' as const,
    rawFilesInput: [
      'docs/roadmap-observability.md | +68 -5 | Outline OpenTelemetry trace propagation goals',
      'docs/rfc-009-metrics.md | +44 -0 | Draft latency histogram bucket specification',
    ].join('\n'),
  },
];

export const PromptStreamView: React.FC<PromptStreamViewProps> = ({
  promptStream,
  daemonActive,
  onToggleDaemon,
  onInjectPromptChanges,
}) => {
  const [promptText, setPromptText] = useState('');
  const [category, setCategory] = useState<
    'feature' | 'bugfix' | 'brainstorm' | 'refactor' | 'plan'
  >('feature');
  const [rawFilesInput, setRawFilesInput] = useState('');
  const [autoPushImmediately, setAutoPushImmediately] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);
  const [lastSuccessBanner, setLastSuccessBanner] = useState<string | null>(null);

  const handleLoadPreset = (preset: (typeof PRESET_SCENARIOS)[number]) => {
    setPromptText(preset.promptText);
    setCategory(preset.category);
    setRawFilesInput(preset.rawFilesInput);
    setValidationError(null);
    setLastSuccessBanner(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const parsed = parseRawPatchOrPromptInput({
      promptText,
      rawFilesInput,
      category,
    });

    if (!parsed.valid) {
      setValidationError(parsed.error || 'Invalid input');
      setLastSuccessBanner(null);
      return;
    }

    setValidationError(null);
    onInjectPromptChanges({
      promptText: promptText.trim(),
      category,
      rawFilesInput: rawFilesInput.trim(),
      autoPushImmediately,
    });

    setLastSuccessBanner(
      `Intercepted ${parsed.hunks.length} file changes from IDE prompt and ${
        autoPushImmediately
          ? 'pushed atomic slices directly to GitHub PR stack.'
          : 'sliced them into your staged atomic commit queue.'
      }`
    );
    setPromptText('');
    setRawFilesInput('');
  };

  return (
    <div className="space-y-8">
      {/* Top Daemon Status Bar */}
      <section
        aria-label="Autonomous Antigravity Watcher Mode"
        className="border border-slate-800 bg-slate-900/70 rounded-xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-6"
      >
        <div className="space-y-1.5 max-w-3xl">
          <div className="flex items-center gap-2 text-xs font-mono text-slate-400">
            <span>Under-the-Hood Agent Mode:</span>
            <span className={daemonActive ? 'text-emerald-400 font-semibold' : 'text-amber-400 font-semibold'}>
              {daemonActive ? 'Active (Intercepting Antigravity File Events)' : 'Paused (Manual Approval Mode)'}
            </span>
          </div>
          <h2 className="text-xl font-semibold text-slate-100">
            Keep prompting your IDE for features, bugfixes, or brainstorms — AtomikGit commits &amp; pushes progressively
          </h2>
          <p className="text-sm text-slate-400">
            When you jump from a feature prompt to a quick bugfix or a roadmap brainstorm without committing, the watcher separates each intent into its own branch and atomic commit under the hood.
          </p>
        </div>

        <button
          type="button"
          onClick={onToggleDaemon}
          className={`px-4 py-2 text-xs font-semibold rounded-lg transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
            daemonActive
              ? 'bg-slate-800 text-slate-200 hover:bg-slate-700 border border-slate-700'
              : 'bg-sky-400 text-slate-950 hover:bg-sky-300'
          }`}
        >
          {daemonActive ? 'Pause Background Watcher' : 'Resume Background Watcher'}
        </button>
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left Form: Simulate or Feed Live Antigravity Prompt & File Changes */}
        <section
          aria-label="Inject Antigravity Prompt Changes"
          className="lg:col-span-6 border border-slate-800 bg-slate-900/50 rounded-xl p-6 space-y-5"
        >
          <div className="border-b border-slate-800 pb-4 space-y-2">
            <h3 className="text-base font-semibold text-slate-100 flex items-center gap-2">
              <Terminal className="w-4 h-4 text-sky-400" />
              <span>Simulate / Feed Antigravity Prompt Session</span>
            </h3>
            <p className="text-xs text-slate-400">
              Test how the autonomous agent decomposes mixed file changes generated while you prompt your IDE.
            </p>
            <div className="flex flex-wrap items-center gap-2 pt-1">
              <span className="text-xs text-slate-400">Quick Presets:</span>
              {PRESET_SCENARIOS.map((preset) => (
                <button
                  key={preset.label}
                  type="button"
                  onClick={() => handleLoadPreset(preset)}
                  className="px-2.5 py-1 text-xs font-medium text-sky-300 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-md transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                >
                  {preset.label}
                </button>
              ))}
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4" noValidate>
            <div>
              <label
                htmlFor="ide-prompt-input"
                className="block text-xs font-medium text-slate-300 mb-1.5"
              >
                What did you just prompt in Antigravity / IDE?
              </label>
              <input
                id="ide-prompt-input"
                type="text"
                value={promptText}
                onChange={(e) => setPromptText(e.target.value)}
                placeholder="e.g., Add Stripe webhook retry handler, fix auth timeout bug, and update roadmap.md"
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3.5 py-2 text-sm text-slate-100 placeholder:text-slate-500 focus:outline-none focus:border-sky-400"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label
                  htmlFor="prompt-category-select"
                  className="block text-xs font-medium text-slate-300 mb-1.5"
                >
                  Primary Prompt Category
                </label>
                <select
                  id="prompt-category-select"
                  value={category}
                  onChange={(e) =>
                    setCategory(
                      e.target.value as
                        | 'feature'
                        | 'bugfix'
                        | 'brainstorm'
                        | 'refactor'
                        | 'plan'
                    )
                  }
                  className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-sky-400"
                >
                  <option value="feature">Feature Implementation</option>
                  <option value="bugfix">Bugfix / Hotfix</option>
                  <option value="refactor">Architecture Refactor</option>
                  <option value="brainstorm">Brainstorming / Exploration</option>
                  <option value="plan">Sprint Plan / Goals</option>
                </select>
              </div>

              <div className="flex items-end pb-1">
                <label className="inline-flex items-center gap-2.5 text-xs text-slate-300 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={autoPushImmediately}
                    onChange={(e) => setAutoPushImmediately(e.target.checked)}
                    className="rounded border-slate-700 bg-slate-950 text-sky-400 focus:ring-sky-400"
                  />
                  <span>Zero-Click Auto-Commit &amp; Push to GitHub</span>
                </label>
              </div>
            </div>

            <div>
              <label
                htmlFor="modified-files-textarea"
                className="block text-xs font-medium text-slate-300 mb-1.5"
              >
                Modified Files &amp; Diff Summary (one file per line: <code>path | +add -del | summary</code>)
              </label>
              <textarea
                id="modified-files-textarea"
                rows={4}
                value={rawFilesInput}
                onChange={(e) => setRawFilesInput(e.target.value)}
                placeholder={`src/auth/passkey.ts | +64 -10 | Add WebAuthn challenge verifier\nsrc/auth/passkey.test.ts | +42 -0 | Verify attestation signature\ndocs/passkey-plan.md | +30 -0 | Brainstorm recovery flow`}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3.5 py-2 text-xs font-mono text-slate-100 placeholder:text-slate-500 focus:outline-none focus:border-sky-400"
              />
            </div>

            {validationError && (
              <div
                role="alert"
                className="flex items-center gap-2 text-xs text-rose-400 bg-rose-950/40 border border-rose-900/60 rounded-lg px-3 py-2"
              >
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{validationError}</span>
              </div>
            )}

            {lastSuccessBanner && (
              <div
                role="status"
                className="flex items-center gap-2 text-xs text-emerald-300 bg-emerald-950/40 border border-emerald-900/60 rounded-lg px-3 py-2"
              >
                <CheckCircle2 className="w-4 h-4 shrink-0" />
                <span>{lastSuccessBanner}</span>
              </div>
            )}

            <div className="pt-1">
              <button
                type="submit"
                className="inline-flex items-center gap-2 px-4 py-2.5 text-xs font-semibold text-slate-950 bg-sky-400 hover:bg-sky-300 rounded-lg transition-colors whitespace-nowrap shrink-0 cursor-pointer"
              >
                <Zap className="w-3.5 h-3.5" />
                <span>Intercept &amp; Slice IDE Changes</span>
              </button>
            </div>
          </form>
        </section>

        {/* Right Column: Chronological Antigravity Prompt & Autonomous Action Ledger */}
        <section
          aria-label="Antigravity Prompt Interception Log"
          className="lg:col-span-6 border border-slate-800 bg-slate-900/50 rounded-xl p-6 space-y-5"
        >
          <div className="border-b border-slate-800 pb-4">
            <h3 className="text-base font-semibold text-slate-100">
              Autonomous Prompt-to-Commit Interception Log ({promptStream.length})
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Every prompt in your IDE is analyzed so features, bugfixes, and brainstorms never collide in a single PR
            </p>
          </div>

          <div className="divide-y divide-slate-800">
            {promptStream.map((evt) => (
              <article key={evt.id} className="py-4 first:pt-0 last:pb-0 space-y-2">
                <div className="flex flex-wrap items-center justify-between gap-2 text-xs font-mono text-slate-400 tabular-nums">
                  <div className="flex items-center gap-2">
                    <span className="text-sky-400 font-medium capitalize">
                      {evt.category}
                    </span>
                    <span aria-hidden="true">·</span>
                    <span>{evt.filesTouched.length} files</span>
                    <span aria-hidden="true">·</span>
                    <span className="text-slate-300">{evt.locDelta} LOC</span>
                  </div>
                  <span>{evt.timestamp}</span>
                </div>

                <p className="text-sm font-medium text-slate-100">
                  “{evt.promptText}”
                </p>

                <div className="text-xs text-slate-400 font-mono truncate">
                  Files: {evt.filesTouched.join(', ')}
                </div>

                <p className="text-xs text-emerald-400">
                  Agent Action: {evt.agentAction}
                </p>
              </article>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
};
