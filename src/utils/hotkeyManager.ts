import { IdeHostId } from '../types/git';

export type HotkeyActionId =
  | 'trigger_quick_atomic_commit'
  | 'toggle_overlay_queue'
  | 'push_all_staged_stack'
  | 'simulate_agent_slice'
  | 'toggle_autopilot_daemon'
  | 'open_hotkey_manager';

export interface HotkeyBinding {
  actionId: HotkeyActionId;
  label: string;
  description: string;
  category: 'Atomic Commits' | 'Overlay Queue' | 'Daemon & Config';
  /** Normalized combo string, e.g. "Alt+Shift+C" or "Ctrl+Shift+Q" */
  combo: string;
  ideCommand: string;
}

export type HotkeyPresetId = 'default_alt_shift' | 'ctrl_shift' | 'alt_single';

export const DEFAULT_HOTKEY_BINDINGS: HotkeyBinding[] = [
  {
    actionId: 'trigger_quick_atomic_commit',
    label: 'Quick Atomic Commit & PR (Top Slice)',
    description:
      'Immediately commits the top ≤80 LOC staged slice and opens a chained PR on GitHub.',
    category: 'Atomic Commits',
    combo: 'Alt+Shift+C',
    ideCommand: 'atomikgit.quickAtomicCommit',
  },
  {
    actionId: 'toggle_overlay_queue',
    label: 'Toggle IDE Overlay Queue HUD',
    description:
      'Opens or closes the floating IDE Overlay Queue to inspect staged slices and pushed PRs.',
    category: 'Overlay Queue',
    combo: 'Alt+Shift+Q',
    ideCommand: 'atomikgit.toggleOverlayQueue',
  },
  {
    actionId: 'push_all_staged_stack',
    label: 'Sync & Push All Staged PRs',
    description:
      'Commits and pushes all staged atomic slices in the queue as a chained PR stack.',
    category: 'Atomic Commits',
    combo: 'Alt+Shift+P',
    ideCommand: 'atomikgit.pushStagedStack',
  },
  {
    actionId: 'simulate_agent_slice',
    label: 'Capture & Slice Active Agent Diff',
    description:
      'Captures the active IDE agent working tree diff and slices it into ≤80 LOC atomic units.',
    category: 'Atomic Commits',
    combo: 'Alt+Shift+S',
    ideCommand: 'atomikgit.captureAndSliceDiff',
  },
  {
    actionId: 'toggle_autopilot_daemon',
    label: 'Toggle Zero-Click Auto-Pilot Daemon',
    description:
      'Switches background zero-click auto-commit and PR stacking ON or OFF.',
    category: 'Daemon & Config',
    combo: 'Alt+Shift+A',
    ideCommand: 'atomikgit.toggleAutoPilot',
  },
  {
    actionId: 'open_hotkey_manager',
    label: 'Open Centralized Hotkey Manager',
    description:
      'Opens the global keyboard shortcut customizer and IDE keybindings exporter.',
    category: 'Daemon & Config',
    combo: 'Alt+Shift+K',
    ideCommand: 'atomikgit.openHotkeyManager',
  },
];

export function applyHotkeyPreset(preset: HotkeyPresetId): HotkeyBinding[] {
  const prefix =
    preset === 'ctrl_shift'
      ? 'Ctrl+Shift+'
      : preset === 'alt_single'
      ? 'Alt+'
      : 'Alt+Shift+';

  const keySuffixMap: Record<HotkeyActionId, string> = {
    trigger_quick_atomic_commit: 'C',
    toggle_overlay_queue: 'Q',
    push_all_staged_stack: 'P',
    simulate_agent_slice: 'S',
    toggle_autopilot_daemon: 'A',
    open_hotkey_manager: 'K',
  };

  return DEFAULT_HOTKEY_BINDINGS.map((b) => ({
    ...b,
    combo: `${prefix}${keySuffixMap[b.actionId]}`,
  }));
}

/**
 * Formats a normalized combo string like "Alt+Shift+C" into readable Mac/PC keycap tokens
 */
export function formatComboKeycaps(combo: string): string[] {
  return combo
    .split('+')
    .map((part) => part.trim())
    .filter(Boolean)
    .map((token) => {
      const lower = token.toLowerCase();
      if (lower === 'alt' || lower === 'option') return '⌥ Alt';
      if (lower === 'shift') return '⇧ Shift';
      if (lower === 'ctrl' || lower === 'control') return '⌃ Ctrl';
      if (lower === 'meta' || lower === 'cmd' || lower === 'command') return '⌘ Cmd';
      return token.toUpperCase();
    });
}

/**
 * Compact badge string for navbar/buttons, e.g. "⌥⇧Q"
 */
export function formatCompactShortcut(combo: string): string {
  return combo
    .split('+')
    .map((part) => {
      const lower = part.trim().toLowerCase();
      if (lower === 'alt' || lower === 'option') return '⌥';
      if (lower === 'shift') return '⇧';
      if (lower === 'ctrl' || lower === 'control') return '⌃';
      if (lower === 'meta' || lower === 'cmd') return '⌘';
      return part.trim().toUpperCase();
    })
    .join('');
}

/**
 * Converts a browser KeyboardEvent into a normalized combo string (e.g., "Alt+Shift+C").
 * Returns null if only modifier keys were pressed.
 */
export function serializeKeyboardEvent(e: {
  key: string;
  code?: string;
  altKey: boolean;
  ctrlKey: boolean;
  metaKey: boolean;
  shiftKey: boolean;
}): string | null {
  const ignoredModifierKeys = new Set([
    'Shift',
    'Control',
    'Alt',
    'Meta',
    'CapsLock',
    'Tab',
  ]);
  if (ignoredModifierKeys.has(e.key)) {
    return null;
  }

  const mods: string[] = [];
  if (e.ctrlKey) mods.push('Ctrl');
  if (e.altKey) mods.push('Alt');
  if (e.shiftKey) mods.push('Shift');
  if (e.metaKey) mods.push('Meta');

  // Use physical key code for letters/digits so Option/Alt on macOS doesn't produce special chars like "ç"
  let baseKey = e.key;
  if (e.code && e.code.startsWith('Key') && e.code.length === 4) {
    baseKey = e.code.slice(3).toUpperCase();
  } else if (e.code && e.code.startsWith('Digit') && e.code.length === 6) {
    baseKey = e.code.slice(5);
  } else if (baseKey.length === 1) {
    baseKey = baseKey.toUpperCase();
  }

  if (mods.length === 0) {
    return null;
  }

  return [...mods, baseKey].join('+');
}

/**
 * Matches a KeyboardEvent against the configured bindings.
 */
export function matchKeyboardEventToAction(
  e: {
    key: string;
    code?: string;
    altKey: boolean;
    ctrlKey: boolean;
    metaKey: boolean;
    shiftKey: boolean;
    target?: EventTarget | null;
  },
  bindings: HotkeyBinding[]
): HotkeyActionId | null {
  // Check if user is typing in an input/textarea without Alt/Ctrl/Meta modifiers
  const targetEl = e.target as HTMLElement | null;
  const isEditable =
    targetEl &&
    (targetEl.tagName === 'INPUT' ||
      targetEl.tagName === 'TEXTAREA' ||
      targetEl.tagName === 'SELECT' ||
      targetEl.isContentEditable);

  if (isEditable && !e.altKey && !e.ctrlKey && !e.metaKey) {
    return null;
  }

  const pressedCombo = serializeKeyboardEvent(e);
  if (!pressedCombo) return null;

  const matched = bindings.find(
    (b) => b.combo.toLowerCase() === pressedCombo.toLowerCase()
  );
  return matched ? matched.actionId : null;
}

/**
 * Generates exportable IDE keybindings JSON for Antigravity, Cursor, VS Code, Windsurf, Kiro, or CLI agents
 */
export function generateIdeKeybindingsConfig(
  bindings: HotkeyBinding[],
  ide: IdeHostId = 'antigravity'
): string {
  const entries = bindings.map((b) => ({
    key: b.combo.toLowerCase(),
    command: b.ideCommand,
    when: 'editorTextFocus || terminalFocus || workbenchState != empty',
    args: {
      hostIde: ide,
      maxLocCap: 80,
      zeroClickPush: true,
    },
  }));
  return JSON.stringify(entries, null, 2);
}
