import React, { useEffect, useState } from 'react';
import {
  AtomicCommitUnit,
  GitHubConnectionConfig,
  IdeHostId,
} from '../types/git';
import {
  applyHotkeyPreset,
  DEFAULT_HOTKEY_BINDINGS,
  formatComboKeycaps,
  formatCompactShortcut,
  generateIdeKeybindingsConfig,
  HotkeyActionId,
  HotkeyBinding,
  HotkeyPresetId,
  serializeKeyboardEvent,
} from '../utils/hotkeyManager';
import { AgentIcon, OttoLogo } from './AgentIcon';
import { PrStatusBadge } from './PrStatusBadge';
import { NavbarGitHubSyncStatus } from './NavbarGitHubSyncStatus';
import { Check, Copy, GitCommit, RotateCcw, Zap } from 'lucide-react';

interface IdeHotkeyOverlayShowcaseProps {
  bindings: HotkeyBinding[];
  onUpdateBindings: (next: HotkeyBinding[]) => void;
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  githubConfig: GitHubConnectionConfig;
  daemonActive: boolean;
  lastTriggeredShortcut: {
    actionLabel: string;
    combo: string;
    timestamp: string;
  } | null;
  onTriggerHotkeyAction: (actionId: HotkeyActionId) => void;
  onPushSingleCommit: (commitId: string) => void;
  onPushAllStaged: () => void;
  onPromoteDraftPr?: (commitId: string) => void;
  onChangeBaseBranch?: (branch: string) => void;
}

const IDE_TARGETS: { id: IdeHostId; label: string; configPath: string }[] = [
  {
    id: 'antigravity',
    label: 'Antigravity',
    configPath: '~/.antigravity/keybindings.json',
  },
  { id: 'cursor', label: 'Cursor', configPath: '.cursor/keybindings.json' },
  {
    id: 'claude-code',
    label: 'Claude Code',
    configPath: '~/.claude/keybindings.json',
  },
  { id: 'vscode', label: 'VS Code', configPath: '.vscode/keybindings.json' },
  {
    id: 'windsurf',
    label: 'Windsurf',
    configPath: '.windsurf/keybindings.json',
  },
  { id: 'kiro', label: 'Kiro', configPath: '.kiro/keybindings.json' },
  { id: 'codex-cli', label: 'Codex', configPath: '~/.codex/keybindings.json' },
  {
    id: 'gemini-cli',
    label: 'Gemini CLI',
    configPath: '~/.gemini/keybindings.json',
  },
];

const SHORT_TILE_LABELS: Record<HotkeyActionId, string> = {
  trigger_quick_atomic_commit: 'Quick Commit',
  toggle_overlay_queue: 'Overlay Queue',
  push_all_staged_stack: 'Push PR Stack',
  simulate_agent_slice: 'Slice Diff',
  toggle_autopilot_daemon: 'Auto-Pilot',
  open_hotkey_manager: 'Keymap HUD',
};

export const IdeHotkeyOverlayShowcase: React.FC<
  IdeHotkeyOverlayShowcaseProps
> = ({
  bindings,
  onUpdateBindings,
  stagedAtomicStack,
  pushedStack,
  githubConfig,
  daemonActive,
  lastTriggeredShortcut,
  onTriggerHotkeyAction,
  onPushSingleCommit,
  onPushAllStaged,
  onPromoteDraftPr,
  onChangeBaseBranch,
}) => {
  const [recordingActionId, setRecordingActionId] =
    useState<HotkeyActionId | null>(null);
  const [selectedIde, setSelectedIde] = useState<IdeHostId>('antigravity');
  const [activePreset, setActivePreset] =
    useState<HotkeyPresetId>('default_alt_shift');
  const [copiedConfig, setCopiedConfig] = useState(false);

  useEffect(() => {
    if (!recordingActionId) return;

    const handleRecordKeyDown = (e: KeyboardEvent) => {
      e.preventDefault();
      e.stopPropagation();

      if (e.key === 'Escape') {
        setRecordingActionId(null);
        return;
      }

      const serialized = serializeKeyboardEvent(e);
      if (!serialized) return;

      const existingConflict = bindings.find(
        (b) =>
          b.actionId !== recordingActionId &&
          b.combo.toLowerCase() === serialized.toLowerCase()
      );
      if (existingConflict) return;

      const updated = bindings.map((b) =>
        b.actionId === recordingActionId ? { ...b, combo: serialized } : b
      );
      onUpdateBindings(updated);
      setRecordingActionId(null);
    };

    window.addEventListener('keydown', handleRecordKeyDown, true);
    return () =>
      window.removeEventListener('keydown', handleRecordKeyDown, true);
  }, [recordingActionId, bindings, onUpdateBindings]);

  const handleSelectPreset = (preset: HotkeyPresetId) => {
    setActivePreset(preset);
    setRecordingActionId(null);
    onUpdateBindings(applyHotkeyPreset(preset));
  };

  const handleResetDefaults = () => {
    setActivePreset('default_alt_shift');
    setRecordingActionId(null);
    onUpdateBindings(DEFAULT_HOTKEY_BINDINGS);
  };

  const handleCopyIdeConfig = () => {
    const json = generateIdeKeybindingsConfig(bindings, selectedIde);
    navigator.clipboard?.writeText(json).catch(() => {});
    setCopiedConfig(true);
    setTimeout(() => setCopiedConfig(false), 2000);
  };

  const quickCommitBinding =
    bindings.find((b) => b.actionId === 'trigger_quick_atomic_commit') ||
    DEFAULT_HOTKEY_BINDINGS[0];
  const overlayQueueBinding =
    bindings.find((b) => b.actionId === 'toggle_overlay_queue') ||
    DEFAULT_HOTKEY_BINDINGS[1];

  const activeIdeMeta =
    IDE_TARGETS.find((t) => t.id === selectedIde) || IDE_TARGETS[0];

  const queueItems =
    stagedAtomicStack.length > 0
      ? stagedAtomicStack.slice(0, 3)
      : pushedStack.slice(0, 3);

  return (
    <div className="rounded-[28px] bg-[#EFECE6] p-5 sm:p-7 border border-black/[0.05] space-y-5">
      {/* Compact Header + Single-Line IDE Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h3 className="text-xl sm:text-2xl font-semibold text-[#1D1D1F] tracking-tight">
            One shortcut. Instant slice.
          </h3>
          <p className="text-xs sm:text-sm text-[#71717A]">
            Press{' '}
            <kbd className="px-1.5 py-0.5 rounded bg-white border border-black/10 font-mono text-xs text-[#1D1D1F]">
              {formatCompactShortcut(quickCommitBinding.combo)}
            </kbd>{' '}
            to commit the top slice or{' '}
            <kbd className="px-1.5 py-0.5 rounded bg-white border border-black/10 font-mono text-xs text-[#1D1D1F]">
              {formatCompactShortcut(overlayQueueBinding.combo)}
            </kbd>{' '}
            to summon Otto’s HUD inside {activeIdeMeta.label}.
          </p>
        </div>

        {/* Preset Switcher + Copy Keymap */}
        <div className="flex items-center gap-2 shrink-0">
          <div className="inline-flex items-center gap-0.5 p-1 rounded-full bg-white border border-black/[0.06] text-xs">
            {(
              [
                { id: 'default_alt_shift', label: '⌥⇧ Mac' },
                { id: 'ctrl_shift', label: '⌃⇧ Win/Linux' },
                { id: 'alt_single', label: '⌥ Fast' },
              ] as const
            ).map((preset) => (
              <button
                key={preset.id}
                type="button"
                onClick={() => handleSelectPreset(preset.id)}
                className={`px-2.5 py-1 rounded-full text-[11px] font-medium transition-colors cursor-pointer whitespace-nowrap ${
                  activePreset === preset.id
                    ? 'bg-[#1D1D1F] text-white'
                    : 'text-zinc-600 hover:text-zinc-900'
                }`}
              >
                {preset.label}
              </button>
            ))}
          </div>

          <button
            type="button"
            onClick={handleCopyIdeConfig}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white hover:bg-zinc-50 border border-black/[0.08] text-xs font-medium text-[#1D1D1F] shadow-2xs cursor-pointer whitespace-nowrap"
          >
            {copiedConfig ? (
              <>
                <Check className="w-3.5 h-3.5 text-emerald-600" />
                <span>Copied</span>
              </>
            ) : (
              <>
                <Copy className="w-3.5 h-3.5 text-zinc-500" />
                <span>{activeIdeMeta.configPath.split('/').pop()}</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Native IDE Host Switcher Pills */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-0.5">
        {IDE_TARGETS.map((ide) => (
          <button
            key={ide.id}
            type="button"
            onClick={() => setSelectedIde(ide.id)}
            className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-all shrink-0 cursor-pointer whitespace-nowrap ${
              selectedIde === ide.id
                ? 'bg-[#1D1D1F] text-white shadow-2xs'
                : 'bg-white/85 text-zinc-600 hover:text-zinc-900 border border-black/[0.06]'
            }`}
          >
            <AgentIcon
              agentId={ide.id}
              sizeClass="w-4 h-4"
              roundedClass="rounded"
            />
            <span>{ide.label}</span>
          </button>
        ))}
      </div>

      {/* Authentic Native IDE Window + Floating Otto Raycast/Cursor-Style Command HUD */}
      <div className="rounded-2xl bg-[#131418] border border-black/20 shadow-xl overflow-hidden text-zinc-100">
        {/* Native IDE Top Titlebar with Live GitHub Sync Indicator */}
        <div className="px-4 py-2.5 bg-[#1A1B21] border-b border-white/[0.07] flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="flex items-center gap-1.5 shrink-0">
              <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
            </div>
            <div className="flex items-center gap-1.5 pl-2 border-l border-white/10 text-xs text-zinc-300 truncate">
              <AgentIcon
                agentId={selectedIde}
                sizeClass="w-4 h-4"
                roundedClass="rounded-xs"
              />
              <span className="font-medium text-white truncate">
                {activeIdeMeta.label}
              </span>
              <span className="text-zinc-500">·</span>
              <span className="font-mono text-[11px] text-zinc-400 truncate">
                pkceCallback.ts
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="bg-white rounded-full px-1 py-0.5">
              <NavbarGitHubSyncStatus
                githubConfig={githubConfig}
                stagedAtomicStack={stagedAtomicStack}
                pushedStack={pushedStack}
                daemonActive={daemonActive}
                onPushAllStaged={onPushAllStaged}
                onPromoteDraftPr={onPromoteDraftPr || (() => {})}
                onChangeBaseBranch={onChangeBaseBranch || (() => {})}
                onNavigateToStack={() => {}}
              />
            </div>
          </div>
        </div>

        {/* IDE Editor Backdrop + Floating Glassmorphic Otto Shortcut HUD */}
        <div className="relative p-4 sm:p-6 bg-gradient-to-b from-[#131418] via-[#161821] to-[#131418]">
          {/* Subtle Ambient Code Lines Behind the Floating HUD */}
          <div
            aria-hidden="true"
            className="hidden sm:block font-mono text-[11px] text-zinc-600/60 space-y-1 mb-3 select-none"
          >
            <div>
              <span className="text-zinc-700 mr-4">14</span>
              <span className="text-purple-400/50">export async function</span>{' '}
              <span className="text-blue-300/50">verifyPkceChallenge</span>
              (verifier: string) &#123;
            </div>
            <div className="bg-emerald-500/10 text-emerald-300/60 px-2 py-0.5 rounded">
              <span className="text-emerald-600/60 mr-2">+15</span>
              const digest = await crypto.subtle.digest(&apos;SHA-256&apos;,
              encode(verifier));
            </div>
          </div>

          {/* Floating Native Otto Command & Queue HUD */}
          <div className="rounded-2xl bg-[#1E2029]/95 backdrop-blur-xl border border-white/[0.12] shadow-2xl p-4 sm:p-5 space-y-4">
            {/* HUD Top Bar */}
            <div className="flex flex-wrap items-center justify-between gap-2 pb-3 border-b border-white/[0.08]">
              <div className="flex items-center gap-2.5">
                <OttoLogo
                  sizeClass="w-7 h-7"
                  roundedClass="rounded-lg"
                  gradientClass="bg-[#FAF8F5]"
                />
                <div className="flex items-center gap-2">
                  <span className="text-sm font-semibold text-white tracking-tight">
                    otto
                  </span>
                  <span className="text-xs text-zinc-400">
                    {activeIdeMeta.label} HUD
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                {lastTriggeredShortcut && (
                  <span className="px-2.5 py-1 rounded-full bg-indigo-500/20 border border-indigo-400/30 text-[11px] font-mono text-indigo-200">
                    ✓ {lastTriggeredShortcut.combo}
                  </span>
                )}
                <button
                  type="button"
                  onClick={handleResetDefaults}
                  title="Reset shortcuts to default"
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white/[0.06] hover:bg-white/[0.12] text-[11px] text-zinc-300 cursor-pointer"
                >
                  <RotateCcw className="w-3 h-3" />
                  <span>Reset</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    onTriggerHotkeyAction('trigger_quick_atomic_commit')
                  }
                  className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-white text-[#131418] hover:bg-zinc-100 text-xs font-semibold cursor-pointer whitespace-nowrap"
                >
                  <Zap className="w-3 h-3 fill-current" />
                  <span>
                    Quick Commit (
                    {formatCompactShortcut(quickCommitBinding.combo)})
                  </span>
                </button>
              </div>
            </div>

            {/* 4 Tactile Physical Keycap Tiles (Visual & Scannable, Zero Text Clutter) */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
              {bindings.slice(0, 4).map((binding) => {
                const isRecording = recordingActionId === binding.actionId;
                const keycaps = formatComboKeycaps(binding.combo);

                return (
                  <div
                    key={binding.actionId}
                    className={`rounded-xl p-3 border transition-all flex flex-col justify-between gap-2.5 ${
                      isRecording
                        ? 'bg-indigo-500/20 border-indigo-400'
                        : 'bg-[#15171E] border-white/[0.08] hover:border-white/20'
                    }`}
                  >
                    <div className="flex items-center justify-between gap-1">
                      <span className="text-xs font-medium text-zinc-200 truncate">
                        {SHORT_TILE_LABELS[binding.actionId]}
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          setRecordingActionId(
                            isRecording ? null : binding.actionId
                          )
                        }
                        className="text-[10px] font-mono text-zinc-400 hover:text-white underline cursor-pointer shrink-0"
                      >
                        {isRecording ? 'Esc' : 'Edit'}
                      </button>
                    </div>

                    {isRecording ? (
                      <div className="py-1.5 px-2 rounded-lg bg-indigo-500/30 text-center text-[11px] font-mono text-indigo-200 animate-pulse">
                        Press keys…
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => onTriggerHotkeyAction(binding.actionId)}
                        className="w-full flex items-center justify-between gap-1 pt-0.5 cursor-pointer group"
                      >
                        <span className="inline-flex items-center gap-1 flex-wrap">
                          {keycaps.map((cap, idx) => (
                            <kbd
                              key={`${binding.actionId}-${idx}`}
                              className="px-1.5 py-0.5 rounded-md bg-[#262936] group-hover:bg-[#313546] border border-white/15 border-b-2 text-[11px] font-mono font-semibold text-white shadow-xs transition-colors"
                            >
                              {cap.replace(' Alt', '').replace(' Shift', '').replace(' Ctrl', '').replace(' Cmd', '')}
                            </kbd>
                          ))}
                        </span>
                        <span className="text-[10px] font-mono text-zinc-500 group-hover:text-zinc-300">
                          Run →
                        </span>
                      </button>
                    )}
                  </div>
                );
              })}
            </div>

            {/* Compact 3-Row Live Overlay Queue Strip */}
            <div className="space-y-1.5 pt-1">
              {queueItems.map((slice, idx) => (
                <div
                  key={slice.id}
                  className="px-3 py-2 rounded-xl bg-[#15171E]/90 border border-white/[0.06] flex items-center justify-between gap-3"
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <span className="text-[11px] font-mono text-zinc-500 tabular-nums shrink-0">
                      0{idx + 1}
                    </span>
                    <span className="text-xs font-mono font-medium text-zinc-100 truncate">
                      {slice.conventionalHeader}
                    </span>
                    <span className="hidden md:inline text-[11px] font-mono text-emerald-400 shrink-0 tabular-nums">
                      +{slice.totalAdditions}/-{slice.totalDeletions}
                    </span>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <PrStatusBadge
                      status={slice.status}
                      prNumber={slice.prNumber || 141 + idx}
                      size="sm"
                    />
                    {slice.status === 'staged' && (
                      <button
                        type="button"
                        onClick={() => onPushSingleCommit(slice.id)}
                        className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white/10 hover:bg-white/20 text-white text-[11px] font-medium cursor-pointer whitespace-nowrap"
                      >
                        <GitCommit className="w-3 h-3" />
                        <span>Commit</span>
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
  );
};
