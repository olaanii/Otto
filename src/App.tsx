import React, { useEffect, useState } from 'react';
import {
  AntigravityPromptEvent,
  AtomicCommitUnit,
  DailyCadenceDay,
  DiffHunk,
  GitHubConnectionConfig,
  GuardrailPolicy,
  IdeAgentProfile,
  IdeHostId,
} from './types/git';
import {
  ensurePushedStackItems,
  ensureThirtyDayCadence,
  INITIAL_DAILY_CADENCE,
  INITIAL_GITHUB_CONFIG,
  INITIAL_IDE_PROFILES,
  INITIAL_POLICY,
  INITIAL_PROMPT_STREAM,
  INITIAL_PUSHED_STACK,
  INITIAL_WORKING_TREE_HUNKS,
} from './utils/seedData';
import {
  parseRawPatchOrPromptInput,
  resolveCommitRealHunks,
  sliceHunksIntoAtomicCommits,
  splitAtomicCommit,
  synthesizeCodeDiffSnippet,
} from './utils/atomicEngine';
import { IdeExtensionOverlayView } from './components/IdeExtensionOverlayView';
import { WhyThisExistsView } from './components/WhyThisExistsView';
import { FeaturesView } from './components/FeaturesView';
import { WhatsPossibleView } from './components/WhatsPossibleView';
import { OttoDesktopAppView } from './components/OttoDesktopAppView';
import { OttoLogo } from './components/AgentIcon';
import {
  DEFAULT_HOTKEY_BINDINGS,
  HotkeyActionId,
  HotkeyBinding,
  matchKeyboardEventToAction,
} from './utils/hotkeyManager';

type ActiveView = 'home' | 'why' | 'features' | 'possible';

const LOCAL_STORAGE_KEY = 'atomikgit_workspace_state_v2';
const HOTKEY_STORAGE_KEY = 'atomikgit_hotkey_bindings_v1';

interface WorkspaceState {
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  ideProfiles: IdeAgentProfile[];
  workingTreeHunks: DiffHunk[];
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  promptStream: AntigravityPromptEvent[];
  dailyCadence: DailyCadenceDay[];
  daemonActive: boolean;
}

const LIVE_SIMULATION_SCENARIOS: Record<
  IdeHostId,
  {
    promptText: string;
    filePath: string;
    summary: string;
    additions: number;
    deletions: number;
    intent: 'feat' | 'fix' | 'refactor' | 'test';
    scope: string;
  }
> = {
  antigravity: {
    promptText: 'Antigravity: Add real-time SSE progress stream for webhook replay job',
    filePath: 'src/payment/replayStream.ts',
    summary: 'Stream live webhook replay progress over Server-Sent Events',
    additions: 58,
    deletions: 9,
    intent: 'feat',
    scope: 'payment',
  },
  cursor: {
    promptText: 'Cursor Composer: Fix null pointer when session cookie lacks exp claim',
    filePath: 'src/auth/jwtClaims.ts',
    summary: 'Guard against malformed JWT exp claim during background refresh',
    additions: 34,
    deletions: 11,
    intent: 'fix',
    scope: 'auth',
  },
  'claude-code': {
    promptText: 'Claude Code CLI: Add property-based unit specs for idempotency key hashing',
    filePath: 'src/payment/idempotency.test.ts',
    summary: 'Verify deterministic SHA-256 idempotency key collision resistance',
    additions: 64,
    deletions: 4,
    intent: 'test',
    scope: 'payment',
  },
  'codex-cli': {
    promptText: 'OpenAI Codex CLI: Extract ledger currency rounding math into pure helper',
    filePath: 'src/ledger/currencyMath.ts',
    summary: 'Extract banker rounding for minor currency units (JPY, USD, EUR)',
    additions: 46,
    deletions: 14,
    intent: 'refactor',
    scope: 'ledger',
  },
  vscode: {
    promptText: 'VS Code + Copilot: Add strict TypeScript return contract to billing webhook',
    filePath: 'src/types/billingContract.ts',
    summary: 'Define discriminated union for webhook acknowledgement responses',
    additions: 39,
    deletions: 7,
    intent: 'refactor',
    scope: 'billing',
  },
  windsurf: {
    promptText: 'Windsurf Cascade: Add sliding-window burst header X-RateLimit-Remaining',
    filePath: 'src/middleware/rateLimitHeaders.ts',
    summary: 'Attach RFC-compliant X-RateLimit-Remaining and Retry-After headers',
    additions: 52,
    deletions: 8,
    intent: 'feat',
    scope: 'middleware',
  },
  'gemini-cli': {
    promptText: 'Gemini CLI: Add PKCE code_verifier SHA-256 challenge validator',
    filePath: 'src/auth/pkceVerifier.ts',
    summary: 'Validate RFC 7636 S256 code_verifier challenge length and entropy',
    additions: 48,
    deletions: 6,
    intent: 'feat',
    scope: 'auth',
  },
  kiro: {
    promptText: 'Kiro Spec IDE: Generate localized receipt summary breakdown from checkout spec',
    filePath: 'src/components/ReceiptSummary.tsx',
    summary: 'Render localized minor-unit tax and subtotal receipt rows',
    additions: 51,
    deletions: 9,
    intent: 'feat',
    scope: 'checkout',
  },
};

function ensureUniqueCommitIds(units: AtomicCommitUnit[]): AtomicCommitUnit[] {
  const seen = new Set<string>();
  return units.map((u, idx) => {
    const hydratedHunks = resolveCommitRealHunks(u);
    if (!seen.has(u.id)) {
      seen.add(u.id);
      return { ...u, hunks: hydratedHunks };
    }
    const uniqueId = `${u.id}-u${idx}`;
    seen.add(uniqueId);
    return { ...u, id: uniqueId, hunks: hydratedHunks };
  });
}

function mergeAllAgentProfiles(existing: IdeAgentProfile[]): IdeAgentProfile[] {
  const map = new Map(existing.map((p) => [p.id, p]));
  return INITIAL_IDE_PROFILES.map((seed) => map.get(seed.id) || seed);
}

function getInitialWorkspaceState(): WorkspaceState {
  try {
    const cached = localStorage.getItem(LOCAL_STORAGE_KEY);
    if (cached) {
      const parsed = JSON.parse(cached) as WorkspaceState;
      if (
        parsed &&
        parsed.policy &&
        Array.isArray(parsed.workingTreeHunks) &&
        Array.isArray(parsed.ideProfiles)
      ) {
        return {
          ...parsed,
          ideProfiles: mergeAllAgentProfiles(parsed.ideProfiles),
          dailyCadence: ensureThirtyDayCadence(parsed.dailyCadence),
          stagedAtomicStack: ensureUniqueCommitIds(parsed.stagedAtomicStack || []),
          pushedStack: ensureUniqueCommitIds(
            ensurePushedStackItems(parsed.pushedStack)
          ),
        };
      }
    }
  } catch {
    // fallback to seed
  }
  return {
    policy: INITIAL_POLICY,
    githubConfig: INITIAL_GITHUB_CONFIG,
    ideProfiles: INITIAL_IDE_PROFILES,
    workingTreeHunks: INITIAL_WORKING_TREE_HUNKS,
    stagedAtomicStack: ensureUniqueCommitIds(
      sliceHunksIntoAtomicCommits(INITIAL_WORKING_TREE_HUNKS, INITIAL_POLICY)
    ),
    pushedStack: ensureUniqueCommitIds(INITIAL_PUSHED_STACK),
    promptStream: INITIAL_PROMPT_STREAM,
    dailyCadence: INITIAL_DAILY_CADENCE,
    daemonActive: true,
  };
}

function getInitialHotkeyBindings(): HotkeyBinding[] {
  try {
    const raw = localStorage.getItem(HOTKEY_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as HotkeyBinding[];
      if (Array.isArray(parsed) && parsed.length === DEFAULT_HOTKEY_BINDINGS.length) {
        return parsed;
      }
    }
  } catch {
    // fallback to defaults
  }
  return DEFAULT_HOTKEY_BINDINGS;
}

export default function App() {
  const [routePath, setRoutePath] = useState<string>(() =>
    typeof window !== 'undefined' ? window.location.pathname : '/'
  );
  const [activeView, setActiveView] = useState<ActiveView>('home');
  const [selectedIde, setSelectedIde] = useState<IdeHostId | 'all'>('all');
  const [workspace, setWorkspace] = useState<WorkspaceState>(getInitialWorkspaceState);
  const [isRefiningAi, setIsRefiningAi] = useState(false);
  const [statusNotice, setStatusNotice] = useState<string | null>(null);
  const [appIconStyle, setAppIconStyle] = useState<string>('meadow');
  const [hotkeyBindings, setHotkeyBindings] = useState<HotkeyBinding[]>(
    getInitialHotkeyBindings
  );
  const [lastTriggeredShortcut, setLastTriggeredShortcut] = useState<{
    actionLabel: string;
    combo: string;
    timestamp: string;
  } | null>(null);

  useEffect(() => {
    const handlePopState = () => {
      setRoutePath(window.location.pathname);
    };
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  const navigateToRoute = (nextPath: '/' | '/app') => {
    if (typeof window !== 'undefined' && window.location.pathname !== nextPath) {
      window.history.pushState({}, '', nextPath);
    }
    setRoutePath(nextPath);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleUpdateHotkeyBindings = (nextBindings: HotkeyBinding[]) => {
    setHotkeyBindings(nextBindings);
    try {
      localStorage.setItem(HOTKEY_STORAGE_KEY, JSON.stringify(nextBindings));
    } catch {
      // ignore storage errors
    }
  };

  const persistWorkspace = (nextState: WorkspaceState) => {
    const sanitized: WorkspaceState = {
      ...nextState,
      stagedAtomicStack: ensureUniqueCommitIds(nextState.stagedAtomicStack),
      pushedStack: ensureUniqueCommitIds(nextState.pushedStack),
    };
    setWorkspace(sanitized);
    try {
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(sanitized));
    } catch {
      // ignore storage quota errors
    }
    fetch('/api/state', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(sanitized),
    }).catch(() => {});
  };

  useEffect(() => {
    const hasLocalCache = Boolean(localStorage.getItem(LOCAL_STORAGE_KEY));
    if (!hasLocalCache) {
      fetch('/api/state')
        .then((res) => (res.ok ? res.json() : null))
        .then((serverData: Partial<WorkspaceState> | null) => {
          if (serverData && serverData.policy && Array.isArray(serverData.workingTreeHunks)) {
            const hydrated: WorkspaceState = {
              policy: serverData.policy,
              githubConfig: serverData.githubConfig || INITIAL_GITHUB_CONFIG,
              ideProfiles: serverData.ideProfiles || INITIAL_IDE_PROFILES,
              workingTreeHunks: serverData.workingTreeHunks,
              stagedAtomicStack: ensureUniqueCommitIds(
                serverData.stagedAtomicStack ||
                  sliceHunksIntoAtomicCommits(serverData.workingTreeHunks, serverData.policy)
              ),
              pushedStack: ensureUniqueCommitIds(
                ensurePushedStackItems(serverData.pushedStack)
              ),
              promptStream: serverData.promptStream || INITIAL_PROMPT_STREAM,
              dailyCadence: ensureThirtyDayCadence(serverData.dailyCadence),
              daemonActive: serverData.daemonActive ?? true,
            };
            setWorkspace(hydrated);
            localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(hydrated));
          }
        })
        .catch(() => {});
    }
  }, []);

  const showTransientNotice = (msg: string) => {
    setStatusNotice(msg);
  };

  const handleSimulateLiveAgentTick = (targetIde: IdeHostId) => {
    const scenario = LIVE_SIMULATION_SCENARIOS[targetIde];
    const newHunk: DiffHunk = {
      id: `hunk-live-${Date.now()}`,
      filePath: scenario.filePath,
      moduleScope: scenario.scope,
      intent: scenario.intent,
      summary: scenario.summary,
      additions: scenario.additions,
      deletions: scenario.deletions,
      promptContext: scenario.promptText,
      sourceAgent: targetIde,
      isBrainstormOrPlan: false,
      diffSnippet: synthesizeCodeDiffSnippet({
        filePath: scenario.filePath,
        scope: scenario.scope,
        intent: scenario.intent,
        summary: scenario.summary,
        additions: scenario.additions,
        deletions: scenario.deletions,
      }),
    };

    const singleSliceList = sliceHunksIntoAtomicCommits([newHunk], workspace.policy);
    const generatedUnit = singleSliceList[0];

    const updatedProfiles = workspace.ideProfiles.map((prof) =>
      prof.id === targetIde
        ? {
            ...prof,
            activeTaskTitle: scenario.summary,
            autoCommittedToday: prof.autoCommittedToday + 1,
            prsCreatedToday: prof.prsCreatedToday + 1,
            status: 'pr_synced' as const,
          }
        : prof
    );

    if (workspace.daemonActive && generatedUnit) {
      // Auto-Pilot ON: immediately commit & create a stacked PR on behalf of the user!
      const nextPrNumber =
        Math.max(142, ...workspace.pushedStack.map((p) => p.prNumber || 140)) + 1;

      const autoPushedPr: AtomicCommitUnit = {
        ...generatedUnit,
        id: `${generatedUnit.id}-pr${nextPrNumber}-${Date.now()}`,
        status: 'pr_open',
        prNumber: nextPrNumber,
        sourceAgent: targetIde,
      };

      const updatedCadence = workspace.dailyCadence.map((day, idx, arr) =>
        idx === arr.length - 1
          ? {
              ...day,
              atomicCommitsCount: day.atomicCommitsCount + 1,
              prsStackedCount: day.prsStackedCount + 1,
            }
          : day
      );

      persistWorkspace({
        ...workspace,
        ideProfiles: updatedProfiles,
        pushedStack: [autoPushedPr, ...workspace.pushedStack],
        dailyCadence: updatedCadence,
      });

      showTransientNotice(
        `Extension Overlay intercepted real-time edit in ${scenario.filePath} (${generatedUnit.totalLoc} LOC) → Auto-committed "${generatedUnit.conventionalHeader}" & created PR #${nextPrNumber} with zero manual clicks.`
      );
    } else {
      const nextHunks = [newHunk, ...workspace.workingTreeHunks];
      const nextStaged = sliceHunksIntoAtomicCommits(nextHunks, workspace.policy);
      persistWorkspace({
        ...workspace,
        ideProfiles: updatedProfiles,
        workingTreeHunks: nextHunks,
        stagedAtomicStack: nextStaged,
      });
      showTransientNotice(
        `Extension Overlay detected edit in ${scenario.filePath} and staged atomic slice "${generatedUnit?.conventionalHeader}".`
      );
    }
  };

  const handleRefineWithAi = async () => {
    if (workspace.workingTreeHunks.length === 0) return;
    setIsRefiningAi(true);
    try {
      const response = await fetch('/api/ai/refine-stack', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          hunks: workspace.workingTreeHunks,
          policy: workspace.policy,
        }),
      });
      if (response.ok) {
        const data = (await response.json()) as {
          stack: AtomicCommitUnit[];
          engine: string;
        };
        persistWorkspace({
          ...workspace,
          stagedAtomicStack: data.stack,
        });
        showTransientNotice(
          `Refined ${data.stack.length} Conventional Commit headers and architectural bullets (${data.engine}).`
        );
      }
    } catch {
      const fallback = sliceHunksIntoAtomicCommits(
        workspace.workingTreeHunks,
        workspace.policy
      );
      persistWorkspace({
        ...workspace,
        stagedAtomicStack: fallback,
      });
    } finally {
      setIsRefiningAi(false);
    }
  };

  const handlePushSingleCommit = (commitId: string) => {
    const target = workspace.stagedAtomicStack.find((c) => c.id === commitId);
    if (!target) return;

    const committedHunkIds = new Set(target.hunks.map((h) => h.id));
    const remainingWorkingHunks = workspace.workingTreeHunks.filter(
      (h) => !committedHunkIds.has(h.id)
    );
    const remainingStaged = workspace.stagedAtomicStack.filter(
      (c) => c.id !== commitId
    );

    const nextPrNumber =
      Math.max(142, ...workspace.pushedStack.map((p) => p.prNumber || 140)) + 1;

    const pushedUnit: AtomicCommitUnit = {
      ...target,
      status: 'pr_open',
      prNumber: nextPrNumber,
    };

    const updatedCadence = workspace.dailyCadence.map((day, idx, arr) =>
      idx === arr.length - 1
        ? {
            ...day,
            atomicCommitsCount: day.atomicCommitsCount + 1,
            prsStackedCount: day.prsStackedCount + 1,
          }
        : day
    );

    persistWorkspace({
      ...workspace,
      workingTreeHunks: remainingWorkingHunks,
      stagedAtomicStack: remainingStaged,
      pushedStack: [pushedUnit, ...workspace.pushedStack],
      dailyCadence: updatedCadence,
    });

    showTransientNotice(
      `Committed & pushed "${target.conventionalHeader}" (${target.totalLoc} LOC) to ${workspace.githubConfig.owner}/${workspace.githubConfig.repo} as PR #${nextPrNumber}.`
    );
  };

  const handlePushAllStaged = () => {
    if (workspace.stagedAtomicStack.length === 0) {
      setActiveView('features');
      return;
    }

    let highestPr = Math.max(
      142,
      ...workspace.pushedStack.map((p) => p.prNumber || 140)
    );

    const newlyPushed: AtomicCommitUnit[] = workspace.stagedAtomicStack.map(
      (unit) => {
        highestPr += 1;
        return {
          ...unit,
          status: 'pr_open',
          prNumber: highestPr,
        };
      }
    );

    const pushedCount = newlyPushed.length;
    const updatedCadence = workspace.dailyCadence.map((day, idx, arr) =>
      idx === arr.length - 1
        ? {
            ...day,
            atomicCommitsCount: day.atomicCommitsCount + pushedCount,
            prsStackedCount: day.prsStackedCount + pushedCount,
            bulkCommitsPrevented: day.bulkCommitsPrevented + 1,
          }
        : day
    );

    persistWorkspace({
      ...workspace,
      workingTreeHunks: [],
      stagedAtomicStack: [],
      pushedStack: [...newlyPushed.reverse(), ...workspace.pushedStack],
      dailyCadence: updatedCadence,
    });

    showTransientNotice(
      `Pushed ${pushedCount} modular atomic commits and created stacked PRs on ${workspace.githubConfig.owner}/${workspace.githubConfig.repo}.`
    );
  };

  const handleSplitCommit = (commitId: string, hunkIdToExtract: string) => {
    const targetIndex = workspace.stagedAtomicStack.findIndex(
      (c) => c.id === commitId
    );
    if (targetIndex === -1) return;

    const target = workspace.stagedAtomicStack[targetIndex];
    const splitPair = splitAtomicCommit(target, [hunkIdToExtract], workspace.policy);
    if (!splitPair) return;

    const nextStaged = [...workspace.stagedAtomicStack];
    nextStaged.splice(targetIndex, 1, splitPair[0], splitPair[1]);

    persistWorkspace({
      ...workspace,
      stagedAtomicStack: nextStaged,
    });

    showTransientNotice(
      `Split "${target.conventionalHeader}" into 2 smaller chained commits (${splitPair[0].totalLoc} LOC and ${splitPair[1].totalLoc} LOC).`
    );
  };

  const handleInjectNotesCapture = (payload: {
    promptText: string;
    rawFilesInput: string;
    sourceAgent: IdeHostId;
    autoPushImmediately: boolean;
  }) => {
    const parsed = parseRawPatchOrPromptInput({
      promptText: payload.promptText,
      rawFilesInput: payload.rawFilesInput,
      sourceAgent: payload.sourceAgent,
    });
    if (!parsed.valid) return;

    const newSlices = sliceHunksIntoAtomicCommits(parsed.hunks, workspace.policy);

    if (payload.autoPushImmediately) {
      let highestPr = Math.max(
        142,
        ...workspace.pushedStack.map((p) => p.prNumber || 140)
      );
      const pushedUnits: AtomicCommitUnit[] = newSlices.map((u) => {
        highestPr += 1;
        return {
          ...u,
          status: 'pr_open',
          prNumber: highestPr,
          sourceAgent: payload.sourceAgent,
        };
      });

      const updatedCadence = workspace.dailyCadence.map((day, idx, arr) =>
        idx === arr.length - 1
          ? {
              ...day,
              atomicCommitsCount: day.atomicCommitsCount + pushedUnits.length,
              prsStackedCount: day.prsStackedCount + pushedUnits.length,
              bulkCommitsPrevented: day.bulkCommitsPrevented + 1,
            }
          : day
      );

      persistWorkspace({
        ...workspace,
        pushedStack: [...pushedUnits.reverse(), ...workspace.pushedStack],
        dailyCadence: updatedCadence,
      });

      showTransientNotice(
        `Auto-sliced ${parsed.hunks.length} files into ${pushedUnits.length} atomic commits and opened stacked PRs on GitHub.`
      );
    } else {
      const combinedHunks = [...parsed.hunks, ...workspace.workingTreeHunks];
      const combinedStaged = sliceHunksIntoAtomicCommits(
        combinedHunks,
        workspace.policy
      );
      persistWorkspace({
        ...workspace,
        workingTreeHunks: combinedHunks,
        stagedAtomicStack: combinedStaged,
      });
      showTransientNotice(
        `Captured ${parsed.hunks.length} files into ${newSlices.length} atomic slices in the IDE Overlay queue.`
      );
    }
  };

  const handleMergeTopPr = (commitId: string) => {
    const nextPushed = workspace.pushedStack.map((pr) =>
      pr.id === commitId ? { ...pr, status: 'merged' as const } : pr
    );
    persistWorkspace({
      ...workspace,
      pushedStack: nextPushed,
    });
    showTransientNotice(
      'Merged atomic PR into base branch and automatically rebased child branches in the stack.'
    );
  };

  const handlePromoteDraftPr = (commitId: string) => {
    const nextPushed = workspace.pushedStack.map((pr) =>
      pr.id === commitId ? { ...pr, status: 'pr_open' as const } : pr
    );
    persistWorkspace({
      ...workspace,
      pushedStack: nextPushed,
    });
    showTransientNotice(
      'Promoted Draft PR to Open — ready for 1-minute atomic review.'
    );
  };

  const handleUpdatePolicy = (updatedPolicy: GuardrailPolicy) => {
    const resliced = sliceHunksIntoAtomicCommits(
      workspace.workingTreeHunks,
      updatedPolicy
    );
    persistWorkspace({
      ...workspace,
      policy: updatedPolicy,
      stagedAtomicStack: resliced,
    });
    showTransientNotice(
      `Updated senior guardrails (max ${updatedPolicy.maxLocPerCommit} LOC/commit) — working tree re-sliced into ${resliced.length} atomic commits.`
    );
  };

  const handleChangeBaseBranch = (nextBranch: string) => {
    const updatedConfig: GitHubConnectionConfig = {
      ...workspace.githubConfig,
      defaultBranch: nextBranch,
      connected: true,
      lastSyncedAt: 'Just now',
    };
    const updatedPolicy: GuardrailPolicy = {
      ...workspace.policy,
      baseBranch: nextBranch,
    };
    persistWorkspace({
      ...workspace,
      githubConfig: updatedConfig,
      policy: updatedPolicy,
    });
    showTransientNotice(
      `Switched GitHub base branch connection to "${nextBranch}" (${updatedConfig.owner}/${updatedConfig.repo}).`
    );
  };

  const handleResetDemo = () => {
    localStorage.removeItem(LOCAL_STORAGE_KEY);
    const fresh: WorkspaceState = {
      policy: INITIAL_POLICY,
      githubConfig: INITIAL_GITHUB_CONFIG,
      ideProfiles: INITIAL_IDE_PROFILES,
      workingTreeHunks: INITIAL_WORKING_TREE_HUNKS,
      stagedAtomicStack: sliceHunksIntoAtomicCommits(
        INITIAL_WORKING_TREE_HUNKS,
        INITIAL_POLICY
      ),
      pushedStack: INITIAL_PUSHED_STACK,
      promptStream: INITIAL_PROMPT_STREAM,
      dailyCadence: INITIAL_DAILY_CADENCE,
      daemonActive: true,
    };
    persistWorkspace(fresh);
    fetch('/api/reset', { method: 'POST' }).catch(() => {});
    showTransientNotice(
      'Reset IDE Extension Overlay and atomic PR stack to initial multi-agent state.'
    );
  };

  const handleTriggerHotkeyAction = (actionId: HotkeyActionId) => {
    const binding =
      hotkeyBindings.find((b) => b.actionId === actionId) ||
      DEFAULT_HOTKEY_BINDINGS[0];
    const nowLabel = new Date().toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });

    setLastTriggeredShortcut({
      actionLabel: binding.label,
      combo: binding.combo,
      timestamp: nowLabel,
    });

    if (actionId === 'trigger_quick_atomic_commit') {
      if (workspace.stagedAtomicStack.length > 0) {
        handlePushSingleCommit(workspace.stagedAtomicStack[0].id);
      } else {
        handleSimulateLiveAgentTick(
          selectedIde === 'all' ? 'antigravity' : selectedIde
        );
      }
      return;
    }

    if (actionId === 'toggle_overlay_queue' || actionId === 'open_hotkey_manager') {
      setActiveView('features');
      setTimeout(() => {
        const el = document.getElementById('feat-ide-hotkeys');
        if (el) {
          el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      }, 60);
      return;
    }

    if (actionId === 'push_all_staged_stack') {
      if (workspace.stagedAtomicStack.length > 0) {
        handlePushAllStaged();
      } else {
        showTransientNotice(
          `Shortcut ${binding.combo}: Working tree is already clean — all stacked PRs are synced on GitHub.`
        );
      }
      return;
    }

    if (actionId === 'simulate_agent_slice') {
      handleSimulateLiveAgentTick(
        selectedIde === 'all' ? 'antigravity' : selectedIde
      );
      return;
    }

    if (actionId === 'toggle_autopilot_daemon') {
      const nextActive = !workspace.daemonActive;
      persistWorkspace({
        ...workspace,
        daemonActive: nextActive,
      });
      showTransientNotice(
        `Shortcut ${binding.combo}: Zero-Click Auto-Pilot Daemon turned ${
          nextActive ? 'ON' : 'OFF'
        }.`
      );
      return;
    }
  };

  // Global keyboard shortcut listener across the entire IDE workspace
  useEffect(() => {
    const handleGlobalKeyDown = (e: KeyboardEvent) => {
      const matchedAction = matchKeyboardEventToAction(e, hotkeyBindings);
      if (matchedAction) {
        e.preventDefault();
        handleTriggerHotkeyAction(matchedAction);
      }
    };
    window.addEventListener('keydown', handleGlobalKeyDown);
    return () => window.removeEventListener('keydown', handleGlobalKeyDown);
  });

  const iconGradient =
    appIconStyle === 'ceramic'
      ? 'from-[#FDE68A] via-[#FCA5A5] to-[#FDBA74]'
      : appIconStyle === 'starry'
      ? 'from-[#1E1B4B] via-[#312E81] to-[#F59E0B]'
      : appIconStyle === 'obsidian'
      ? 'from-[#18181B] via-[#27272A] to-[#52525B]'
      : 'from-[#60A5FA] via-[#BAE6FD] to-[#86EFAC]';

  const isDesktopAppRoute =
    routePath === '/app' || routePath.startsWith('/app/');

  if (isDesktopAppRoute) {
    return (
      <OttoDesktopAppView
        ideProfiles={workspace.ideProfiles}
        selectedIde={selectedIde}
        onSelectIde={setSelectedIde}
        workingTreeHunks={workspace.workingTreeHunks}
        stagedAtomicStack={workspace.stagedAtomicStack}
        pushedStack={workspace.pushedStack}
        promptStream={workspace.promptStream}
        dailyCadence={workspace.dailyCadence}
        policy={workspace.policy}
        githubConfig={workspace.githubConfig}
        daemonActive={workspace.daemonActive}
        isRefiningAi={isRefiningAi}
        statusNotice={statusNotice}
        onDismissNotice={() => setStatusNotice(null)}
        onToggleDaemon={() =>
          persistWorkspace({
            ...workspace,
            daemonActive: !workspace.daemonActive,
          })
        }
        onPushSingleCommit={handlePushSingleCommit}
        onPushAllStaged={handlePushAllStaged}
        onSplitCommit={handleSplitCommit}
        onMergeTopPr={handleMergeTopPr}
        onPromoteDraftPr={handlePromoteDraftPr}
        onChangeBaseBranch={handleChangeBaseBranch}
        onSimulateLiveAgentTick={handleSimulateLiveAgentTick}
        onInjectNotesCapture={handleInjectNotesCapture}
        onRefineWithAi={handleRefineWithAi}
        onUpdatePolicy={handleUpdatePolicy}
        onResetDemo={handleResetDemo}
        hotkeyBindings={hotkeyBindings}
        onUpdateHotkeyBindings={handleUpdateHotkeyBindings}
        lastTriggeredShortcut={lastTriggeredShortcut}
        onTriggerHotkeyAction={handleTriggerHotkeyAction}
        onNavigateToLanding={() => navigateToRoute('/')}
      />
    );
  }

  return (
    <div className="min-h-screen bg-[#FAF8F5] text-zinc-900 flex flex-col">
      {/* Moonjar-Style Floating Pill & Top Navigation Bar */}
      <header className="sticky top-3 z-30 px-3 sm:px-8 pt-2">
        <div
          className={`max-w-[1180px] w-full mx-auto flex flex-wrap sm:flex-nowrap items-center justify-between gap-y-2 gap-x-4 px-4 sm:px-6 py-2.5 rounded-2xl sm:rounded-full transition-all ${
            activeView === 'home'
              ? 'bg-[#FAF8F5]/95 backdrop-blur-md'
              : 'bg-white/95 backdrop-blur-md border border-black/[0.06] shadow-sm'
          }`}
        >
          {/* Zone 1: Transparent Otto octopus logo + lowercase wordmark (returns to Home Studio) */}
          <a
            href="/"
            onClick={(e) => {
              e.preventDefault();
              navigateToRoute('/');
              setActiveView('home');
            }}
            className="inline-flex items-center gap-2 whitespace-nowrap shrink-0 group"
          >
            <OttoLogo
              sizeClass="w-9 h-9"
              className="group-hover:scale-105 transition-transform"
            />
            <span className="text-[18px] sm:text-[19px] font-medium tracking-[-0.025em] text-[#3F3F46] group-hover:text-[#1D1D1F] transition-colors">
              otto
            </span>
          </a>

          {/* Zone 2: Exact 3 Moonjar Navigation Links */}
          <nav
            aria-label="Primary Workspace Navigation"
            className="order-3 sm:order-none w-full sm:w-auto flex items-center justify-center gap-6 sm:gap-7 pt-1.5 sm:pt-0 border-t border-black/[0.05] sm:border-t-0 text-[13px] sm:text-[14px] font-medium text-[#3F3F46]"
          >
            <a
              href="#why-this-exists"
              onClick={(e) => {
                e.preventDefault();
                setActiveView('why');
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className={`transition-colors whitespace-nowrap shrink-0 py-1 ${
                activeView === 'why'
                  ? 'text-[#18181B] font-semibold'
                  : 'text-[#52525B] hover:text-[#18181B]'
              }`}
            >
              Why This Exists
            </a>
            <a
              href="#features"
              onClick={(e) => {
                e.preventDefault();
                setActiveView('features');
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className={`transition-colors whitespace-nowrap shrink-0 py-1 ${
                activeView === 'features'
                  ? 'text-[#18181B] font-semibold'
                  : 'text-[#52525B] hover:text-[#18181B]'
              }`}
            >
              Features
            </a>
            <a
              href="#whats-possible"
              onClick={(e) => {
                e.preventDefault();
                setActiveView('possible');
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className={`transition-colors whitespace-nowrap shrink-0 py-1 ${
                activeView === 'possible'
                  ? 'text-[#18181B] font-semibold'
                  : 'text-[#52525B] hover:text-[#18181B]'
              }`}
            >
              What’s Possible
            </a>
          </nav>

          {/* Zone 3: Clean Moonjar Landing Page Primary CTA + Desktop App Link */}
          <div className="flex items-center gap-2.5 shrink-0">
            <a
              href="/app"
              onClick={(e) => {
                e.preventDefault();
                navigateToRoute('/app');
              }}
              className="px-3.5 py-2 text-[12.5px] sm:text-[13px] font-medium text-[#3F3F46] hover:text-[#18181B] bg-white/80 hover:bg-white border border-black/[0.08] rounded-full transition-all whitespace-nowrap shrink-0 cursor-pointer"
            >
              Open Desktop App
            </a>
            <button
              type="button"
              onClick={() => {
                setActiveView('features');
                setTimeout(() => {
                  const el = document.getElementById('feat-07-yours');
                  if (el) {
                    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
                  } else {
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                  }
                }, 60);
              }}
              className="px-4 sm:px-5 py-2 sm:py-2.5 text-[12.5px] sm:text-[13.5px] font-semibold text-white bg-[#232325] hover:bg-[#141416] rounded-full shadow-xs transition-all whitespace-nowrap shrink-0 cursor-pointer"
            >
              Get early access
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Container */}
      <main className="flex-1 max-w-[1340px] w-full mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-8">
        {statusNotice && (
          <div
            role="status"
            className="max-w-4xl mx-auto flex items-center justify-between gap-4 px-4 py-3 rounded-2xl bg-amber-100/90 border border-amber-300/80 text-xs font-medium text-zinc-900"
          >
            <span>{statusNotice}</span>
            <button
              type="button"
              onClick={() => setStatusNotice(null)}
              className="text-zinc-600 hover:text-zinc-900 underline whitespace-nowrap shrink-0 cursor-pointer"
            >
              Dismiss
            </button>
          </div>
        )}

        {activeView === 'home' && (
          <IdeExtensionOverlayView
            ideProfiles={workspace.ideProfiles}
            selectedIde={selectedIde}
            onSelectIde={setSelectedIde}
            workingTreeHunks={workspace.workingTreeHunks}
            stagedAtomicStack={workspace.stagedAtomicStack}
            pushedStack={workspace.pushedStack}
            policy={workspace.policy}
            githubConfig={workspace.githubConfig}
            daemonActive={workspace.daemonActive}
            onToggleDaemon={() =>
              persistWorkspace({
                ...workspace,
                daemonActive: !workspace.daemonActive,
              })
            }
            onPushSingleCommit={handlePushSingleCommit}
            onPushAllStaged={handlePushAllStaged}
            onSplitCommit={handleSplitCommit}
            onMergeTopPr={handleMergeTopPr}
            onPromoteDraftPr={handlePromoteDraftPr}
            onSimulateLiveAgentTick={handleSimulateLiveAgentTick}
            onInjectNotesCapture={handleInjectNotesCapture}
            onNavigateToInstall={() => {
              setActiveView('features');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          />
        )}

        {activeView === 'why' && (
          <WhyThisExistsView
            ideProfiles={workspace.ideProfiles}
            stagedAtomicStack={workspace.stagedAtomicStack}
            pushedStack={workspace.pushedStack}
            onSimulateLiveAgentTick={handleSimulateLiveAgentTick}
            onNavigateToFeatures={() => {
              setActiveView('features');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
            onNavigateToHome={() => {
              setActiveView('home');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          />
        )}

        {activeView === 'features' && (
          <FeaturesView
            ideProfiles={workspace.ideProfiles}
            workingTreeHunks={workspace.workingTreeHunks}
            stagedAtomicStack={workspace.stagedAtomicStack}
            pushedStack={workspace.pushedStack}
            dailyCadence={workspace.dailyCadence}
            policy={workspace.policy}
            githubConfig={workspace.githubConfig}
            daemonActive={workspace.daemonActive}
            isRefiningAi={isRefiningAi}
            onSimulateLiveAgentTick={handleSimulateLiveAgentTick}
            onPushSingleCommit={handlePushSingleCommit}
            onPushAllStaged={handlePushAllStaged}
            onSplitCommit={handleSplitCommit}
            onMergeTopPr={handleMergeTopPr}
            onPromoteDraftPr={handlePromoteDraftPr}
            onChangeBaseBranch={handleChangeBaseBranch}
            onRefineWithAi={handleRefineWithAi}
            onUpdatePolicy={handleUpdatePolicy}
            onResetDemo={handleResetDemo}
            appIconStyle={appIconStyle}
            onChangeAppIconStyle={setAppIconStyle}
            hotkeyBindings={hotkeyBindings}
            onUpdateHotkeyBindings={handleUpdateHotkeyBindings}
            lastTriggeredShortcut={lastTriggeredShortcut}
            onTriggerHotkeyAction={handleTriggerHotkeyAction}
          />
        )}

        {activeView === 'possible' && (
          <WhatsPossibleView
            onSimulateLiveAgentTick={handleSimulateLiveAgentTick}
            onNavigateToHome={() => {
              setActiveView('home');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          />
        )}
      </main>

      {/* Moonjar-Style Minimal Footer (Matches Screen 7 & 24) */}
      <footer className="border-t border-black/[0.06] mt-12 px-6 py-10 max-w-5xl w-full mx-auto space-y-8">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
          <div className="space-y-2 text-[11px] font-mono uppercase tracking-[0.16em] text-zinc-500">
            <div className="font-bold text-[#1D1D1F]">PAGES</div>
            <div className="flex flex-col space-y-1.5">
              <button
                type="button"
                onClick={() => {
                  setActiveView('why');
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
                className="text-left hover:text-[#1D1D1F] cursor-pointer"
              >
                WHY THIS EXISTS
              </button>
              <button
                type="button"
                onClick={() => {
                  setActiveView('features');
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
                className="text-left hover:text-[#1D1D1F] cursor-pointer"
              >
                FEATURES
              </button>
              <button
                type="button"
                onClick={() => {
                  setActiveView('possible');
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
                className="text-left hover:text-[#1D1D1F] cursor-pointer"
              >
                WHAT’S POSSIBLE
              </button>
              <button
                type="button"
                onClick={() => {
                  setActiveView('home');
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
                className="text-left hover:text-[#1D1D1F] cursor-pointer"
              >
                LIVE IDE &amp; MOBILE STUDIO
              </button>
              <a
                href="/app"
                onClick={(e) => {
                  e.preventDefault();
                  navigateToRoute('/app');
                }}
                className="text-left text-indigo-600 font-semibold hover:text-indigo-800 cursor-pointer"
              >
                OPEN DESKTOP APP (/APP) →
              </a>
            </div>
          </div>

          <button
            type="button"
            onClick={() => {
              setActiveView('home');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
            title="Return to Otto Live Studio"
            className="cursor-pointer hover:scale-105 transition-transform"
          >
            <OttoLogo
              sizeClass="w-14 h-14"
              roundedClass="rounded-2xl"
              gradientClass={`bg-gradient-to-b ${iconGradient}`}
            />
          </button>
        </div>

        <div className="pt-6 border-t border-black/[0.06] flex flex-col sm:flex-row items-center justify-between gap-2 text-[10px] font-mono uppercase tracking-[0.14em] text-zinc-400">
          <span>OTTO © 2026 · DESKTOP IDE &amp; MOBILE COMPANION</span>
          <span>ATOMIC COMMITS AND STACKED PRS MADE AUTOMATICALLY</span>
        </div>
      </footer>
    </div>
  );
}
