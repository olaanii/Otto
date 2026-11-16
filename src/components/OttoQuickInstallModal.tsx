import React, { useState, useEffect } from 'react';
import {
  Check,
  ChevronRight,
  Copy,
  Download,
  ExternalLink,
  Laptop,
  Layers,
  Monitor,
  Package,
  Play,
  Shield,
  Sparkles,
  Terminal,
  X,
} from 'lucide-react';

interface OttoQuickInstallModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialTab?: 'desktop' | 'ide' | 'daemon';
}

export const OttoQuickInstallModal: React.FC<OttoQuickInstallModalProps> = ({
  isOpen,
  onClose,
  initialTab = 'ide',
}) => {
  const [activeTab, setActiveTab] = useState<'desktop' | 'ide' | 'daemon'>(initialTab);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setActiveTab(initialTab);
    }
  }, [initialTab, isOpen]);

  if (!isOpen) return null;

  const copySnippet = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-md animate-in fade-in duration-200">
      <div className="relative w-full max-w-2xl bg-white border border-black/[0.08] rounded-3xl shadow-2xl overflow-hidden text-zinc-900">
        {/* Modal Header */}
        <div className="px-6 py-5 border-b border-black/[0.06] flex items-center justify-between bg-zinc-50/50">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-bold text-sm shadow-xs">
              🐙
            </div>
            <div>
              <h3 className="text-base font-semibold text-zinc-900 tracking-tight">
                Install Otto · Universal Developer Stack
              </h3>
              <p className="text-xs text-zinc-500">
                Go Daemon · Clerk Security · 8 IDE Environments · Flutter Desktop
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-full hover:bg-black/[0.05] text-zinc-400 hover:text-zinc-700 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="flex border-b border-black/[0.06] bg-zinc-100/50 px-6 pt-2">
          <button
            type="button"
            onClick={() => setActiveTab('ide')}
            className={`pb-3 px-3 text-xs font-medium border-b-2 transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === 'ide'
                ? 'border-indigo-600 text-indigo-600 font-semibold'
                : 'border-transparent text-zinc-500 hover:text-zinc-800'
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            Universal IDE Extension (.vsix)
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('desktop')}
            className={`pb-3 px-3 text-xs font-medium border-b-2 transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === 'desktop'
                ? 'border-indigo-600 text-indigo-600 font-semibold'
                : 'border-transparent text-zinc-500 hover:text-zinc-800'
            }`}
          >
            <Monitor className="w-3.5 h-3.5" />
            Flutter Desktop App
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('daemon')}
            className={`pb-3 px-3 text-xs font-medium border-b-2 transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === 'daemon'
                ? 'border-indigo-600 text-indigo-600 font-semibold'
                : 'border-transparent text-zinc-500 hover:text-zinc-800'
            }`}
          >
            <Terminal className="w-3.5 h-3.5" />
            Native Go Daemon
          </button>
        </div>

        {/* Tab Body */}
        <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
          {/* TAB 1: IDE EXTENSION */}
          {activeTab === 'ide' && (
            <div className="space-y-5">
              <div>
                <h4 className="text-sm font-semibold text-zinc-900 mb-1">
                  Install in Cursor, VS Code, Windsurf, Kiro, or Antigravity
                </h4>
                <p className="text-xs text-zinc-600">
                  Otto runs a single universal VSIX bundle. Press <kbd className="px-1.5 py-0.5 rounded bg-zinc-100 border border-zinc-300 font-mono text-[11px]">Ctrl+Shift+K</kbd> (Mac: <kbd className="px-1.5 py-0.5 rounded bg-zinc-100 border border-zinc-300 font-mono text-[11px]">Cmd+Shift+K</kbd>) to pop open the HUD anytime.
                </p>
              </div>

              {/* Install Commands */}
              <div className="space-y-3">
                <div className="bg-zinc-900 rounded-xl p-3.5 text-zinc-100 font-mono text-xs">
                  <div className="flex items-center justify-between pb-2 mb-2 border-b border-zinc-800 text-[11px] text-zinc-400">
                    <span>CLI One-Liner (Auto-installs into detected IDEs)</span>
                    <button
                      type="button"
                      onClick={() =>
                        copySnippet(
                          'code --install-extension ide_extension/otto-ide-extension.vsix || cursor --install-extension ide_extension/otto-ide-extension.vsix',
                          'cli-install'
                        )
                      }
                      className="inline-flex items-center gap-1 hover:text-white transition-colors cursor-pointer"
                    >
                      {copiedKey === 'cli-install' ? (
                        <>
                          <Check className="w-3 h-3 text-emerald-400" /> Copied
                        </>
                      ) : (
                        <>
                          <Copy className="w-3 h-3" /> Copy
                        </>
                      )}
                    </button>
                  </div>
                  <code>code --install-extension ide_extension/otto-ide-extension.vsix</code>
                  <div className="text-zinc-500 text-[11px] mt-1"># For Cursor: cursor --install-extension ide_extension/otto-ide-extension.vsix</div>
                  <div className="text-zinc-500 text-[11px]"># For Windsurf: windsurf --install-extension ide_extension/otto-ide-extension.vsix</div>
                </div>

                {/* Build from source instructions */}
                <div className="border border-zinc-200 rounded-xl p-3.5 bg-zinc-50/60 text-xs text-zinc-700 space-y-2">
                  <div className="font-semibold text-zinc-900 flex items-center justify-between">
                    <span>Build &amp; package from source</span>
                    <button
                      type="button"
                      onClick={() =>
                        copySnippet(
                          'cd ide_extension && npm install && npm run compile',
                          'npm-compile'
                        )
                      }
                      className="text-indigo-600 hover:text-indigo-700 inline-flex items-center gap-1 font-mono text-[11px] cursor-pointer"
                    >
                      {copiedKey === 'npm-compile' ? <Check className="w-3 h-3 text-emerald-500" /> : <Copy className="w-3 h-3" />}
                      Copy Command
                    </button>
                  </div>
                  <code className="block font-mono bg-white p-2 rounded border border-zinc-200 text-zinc-800">
                    cd ide_extension && npm install && npm run compile
                  </code>
                </div>
              </div>

              {/* Supported Environments Pill Matrix */}
              <div>
                <div className="text-[11px] font-mono uppercase tracking-wider text-zinc-400 mb-2">
                  Verified Across 8 Agent Environments
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {[
                    'Cursor Composer',
                    'VS Code + Copilot',
                    'Windsurf Cascade',
                    'Kiro Spec IDE',
                    'Google Antigravity',
                    'Claude Code CLI',
                    'OpenAI Codex CLI',
                    'Gemini CLI',
                  ].map((env) => (
                    <div
                      key={env}
                      className="px-2.5 py-1.5 rounded-lg bg-zinc-50 border border-black/[0.06] text-[11px] font-medium text-zinc-700 flex items-center gap-1.5"
                    >
                      <Check className="w-3 h-3 text-emerald-600 shrink-0" />
                      <span className="truncate">{env}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: FLUTTER DESKTOP */}
          {activeTab === 'desktop' && (
            <div className="space-y-5">
              <div>
                <h4 className="text-sm font-semibold text-zinc-900 mb-1">
                  Otto Native Desktop App (Flutter Windows / macOS / Linux)
                </h4>
                <p className="text-xs text-zinc-600">
                  Hardware-accelerated Impeller rendering engine, 60fps glassmorphic diff visualizer, and local Git ledger manager.
                </p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <a
                  href="/app"
                  onClick={(e) => {
                    e.preventDefault();
                    window.location.href = '/app';
                  }}
                  className="p-4 rounded-2xl border border-zinc-200 bg-zinc-50/50 hover:bg-white hover:border-indigo-400 hover:shadow-md transition-all text-left flex flex-col justify-between group cursor-pointer"
                >
                  <div className="space-y-1">
                    <span className="text-lg">🪟</span>
                    <div className="font-semibold text-xs text-zinc-900 group-hover:text-indigo-600 transition-colors">
                      Windows Desktop
                    </div>
                    <div className="text-[11px] text-zinc-500">x64 / ARM64 MSIX installer</div>
                  </div>
                  <div className="mt-4 inline-flex items-center gap-1 text-[11px] font-semibold text-indigo-600">
                    Open In-App <ChevronRight className="w-3 h-3" />
                  </div>
                </a>

                <a
                  href="/app"
                  onClick={(e) => {
                    e.preventDefault();
                    window.location.href = '/app';
                  }}
                  className="p-4 rounded-2xl border border-zinc-200 bg-zinc-50/50 hover:bg-white hover:border-indigo-400 hover:shadow-md transition-all text-left flex flex-col justify-between group cursor-pointer"
                >
                  <div className="space-y-1">
                    <span className="text-lg">🍎</span>
                    <div className="font-semibold text-xs text-zinc-900 group-hover:text-indigo-600 transition-colors">
                      macOS Desktop
                    </div>
                    <div className="text-[11px] text-zinc-500">Apple Silicon DMG &amp; Intel</div>
                  </div>
                  <div className="mt-4 inline-flex items-center gap-1 text-[11px] font-semibold text-indigo-600">
                    Open In-App <ChevronRight className="w-3 h-3" />
                  </div>
                </a>

                <a
                  href="/app"
                  onClick={(e) => {
                    e.preventDefault();
                    window.location.href = '/app';
                  }}
                  className="p-4 rounded-2xl border border-zinc-200 bg-zinc-50/50 hover:bg-white hover:border-indigo-400 hover:shadow-md transition-all text-left flex flex-col justify-between group cursor-pointer"
                >
                  <div className="space-y-1">
                    <span className="text-lg">🐧</span>
                    <div className="font-semibold text-xs text-zinc-900 group-hover:text-indigo-600 transition-colors">
                      Linux Desktop
                    </div>
                    <div className="text-[11px] text-zinc-500">AppImage / Flatpak / Deb</div>
                  </div>
                  <div className="mt-4 inline-flex items-center gap-1 text-[11px] font-semibold text-indigo-600">
                    Open In-App <ChevronRight className="w-3 h-3" />
                  </div>
                </a>
              </div>

              <div className="p-3.5 bg-indigo-50/70 border border-indigo-100 rounded-xl text-xs text-indigo-950 flex items-start gap-2.5">
                <Sparkles className="w-4 h-4 text-indigo-600 shrink-0 mt-0.5" />
                <div>
                  <strong>Live Web Studio Preview:</strong> You can also run the full Otto Desktop experience directly in your browser at <a href="/app" className="underline font-semibold text-indigo-700">/app</a> with simulated AST slicing and real-time GitHub sync.
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: GO DAEMON */}
          {activeTab === 'daemon' && (
            <div className="space-y-5">
              <div>
                <h4 className="text-sm font-semibold text-zinc-900 mb-1">
                  Native Go Daemon (Ultra-Low Latency &lt;4ms Engine)
                </h4>
                <p className="text-xs text-zinc-600">
                  Written in pure Go with zero external dependencies. Watches file systems via kernel inotify/FSEvents, executes fast AST diff slicing, and verifies Clerk JWT auth headers.
                </p>
              </div>

              <div className="space-y-3">
                <div className="bg-zinc-900 rounded-xl p-3.5 text-zinc-100 font-mono text-xs">
                  <div className="flex items-center justify-between pb-2 mb-2 border-b border-zinc-800 text-[11px] text-zinc-400">
                    <span>Run Native Go Daemon</span>
                    <button
                      type="button"
                      onClick={() => copySnippet('go run cmd/daemon/main.go', 'go-run')}
                      className="inline-flex items-center gap-1 hover:text-white transition-colors cursor-pointer"
                    >
                      {copiedKey === 'go-run' ? (
                        <>
                          <Check className="w-3 h-3 text-emerald-400" /> Copied
                        </>
                      ) : (
                        <>
                          <Copy className="w-3 h-3" /> Copy
                        </>
                      )}
                    </button>
                  </div>
                  <code>go run cmd/daemon/main.go</code>
                  <div className="text-emerald-400 text-[11px] mt-2">
                    # Output: 🐙 Otto Native Go Daemon listening on http://localhost:3000
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  <div className="p-3 rounded-xl border border-zinc-200 bg-zinc-50/50">
                    <div className="font-semibold text-zinc-900 mb-1">Clerk JWT Verification</div>
                    <p className="text-zinc-600 text-[11px]">
                      Daemon inspects <code className="text-indigo-600 font-mono">Authorization: Bearer &lt;token&gt;</code> against Clerk RS256 JWKs before creating GitHub PRs.
                    </p>
                  </div>

                  <div className="p-3 rounded-xl border border-zinc-200 bg-zinc-50/50">
                    <div className="font-semibold text-zinc-900 mb-1">Real-time SSE Streams</div>
                    <p className="text-zinc-600 text-[11px]">
                      Provides Server-Sent Events at <code className="text-indigo-600 font-mono">/api/events</code> so all 8 IDE extensions stay in sync simultaneously.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-4 border-t border-black/[0.06] bg-zinc-50/80 flex items-center justify-between">
          <span className="text-[11px] text-zinc-500 font-mono">
            Otto Architecture Plan v2.4 · All platforms supported
          </span>
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-xs font-semibold text-zinc-700 hover:text-zinc-950 bg-white hover:bg-zinc-100 border border-black/[0.1] rounded-full transition-colors cursor-pointer"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
