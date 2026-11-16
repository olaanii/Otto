import express from 'express';
import { createServer as createViteServer } from 'vite';
import fs from 'node:fs';
import path from 'node:path';
import { GoogleGenAI, Type } from '@google/genai';
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
} from './src/utils/seedData';
import {
  formatConventionalHeader,
  sliceHunksIntoAtomicCommits,
} from './src/utils/atomicEngine';
import {
  AntigravityPromptEvent,
  AtomicCommitUnit,
  DailyCadenceDay,
  DiffHunk,
  GitHubConnectionConfig,
  GuardrailPolicy,
  IdeAgentProfile,
} from './src/types/git';

interface PersistedState {
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

const DATA_DIR = path.resolve(process.cwd(), '.data');
const STATE_FILE = path.join(DATA_DIR, 'atomik-state.json');

function loadOrInitializeState(): PersistedState {
  try {
    if (fs.existsSync(STATE_FILE)) {
      const raw = fs.readFileSync(STATE_FILE, 'utf8');
      const parsed = JSON.parse(raw) as PersistedState;
      if (parsed && parsed.policy && Array.isArray(parsed.workingTreeHunks)) {
        return {
          ...parsed,
          ideProfiles: parsed.ideProfiles || INITIAL_IDE_PROFILES,
          dailyCadence: ensureThirtyDayCadence(parsed.dailyCadence),
          pushedStack: ensurePushedStackItems(parsed.pushedStack),
        };
      }
    }
  } catch (err) {
    console.warn('Initializing fresh state store:', err);
  }

  const initialStaged = sliceHunksIntoAtomicCommits(
    INITIAL_WORKING_TREE_HUNKS,
    INITIAL_POLICY
  );

  const initialState: PersistedState = {
    policy: INITIAL_POLICY,
    githubConfig: INITIAL_GITHUB_CONFIG,
    ideProfiles: INITIAL_IDE_PROFILES,
    workingTreeHunks: INITIAL_WORKING_TREE_HUNKS,
    stagedAtomicStack: initialStaged,
    pushedStack: INITIAL_PUSHED_STACK,
    promptStream: INITIAL_PROMPT_STREAM,
    dailyCadence: INITIAL_DAILY_CADENCE,
    daemonActive: true,
  };

  saveState(initialState);
  return initialState;
}

function saveState(state: PersistedState): void {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2), 'utf8');
  } catch (err) {
    console.error('Failed to persist state:', err);
  }
}

function getGenAIClient(): GoogleGenAI | null {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === 'MY_GEMINI_API_KEY') {
    return null;
  }
  return new GoogleGenAI({
    apiKey,
    httpOptions: {
      headers: {
        'User-Agent': 'aistudio-build',
      },
    },
  });
}

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json({ limit: '2mb' }));

  let appState = loadOrInitializeState();

  app.get('/api/state', (_req, res) => {
    res.json(appState);
  });

  app.post('/api/state', (req, res) => {
    const body = req.body as Partial<PersistedState>;
    appState = {
      ...appState,
      ...body,
    };
    saveState(appState);
    res.json(appState);
  });

  app.post('/api/reset', (_req, res) => {
    if (fs.existsSync(STATE_FILE)) {
      fs.unlinkSync(STATE_FILE);
    }
    appState = loadOrInitializeState();
    res.json(appState);
  });

  // Real-time GitHub Sync Status endpoint for Navbar indicator
  app.get('/api/github/sync-status', (_req, res) => {
    const stagedCount = appState.stagedAtomicStack.length;
    const openPrCount = appState.pushedStack.filter((p) => p.status === 'pr_open').length;
    const draftPrCount = appState.pushedStack.filter((p) => p.status === 'draft').length;
    const mergedPrCount = appState.pushedStack.filter((p) => p.status === 'merged').length;
    const pendingPrSyncCount = stagedCount + draftPrCount;

    const activeHeadUnit =
      appState.stagedAtomicStack[0] ||
      appState.pushedStack.find((p) => p.status === 'pr_open' || p.status === 'draft') ||
      appState.pushedStack[0];

    const activeBranch =
      activeHeadUnit?.branchName || appState.githubConfig.defaultBranch || 'main';
    const latestPrNumber = appState.pushedStack[0]?.prNumber || 143;
    const latestSha = appState.pushedStack[0]?.sha || '8f4e2c1';

    res.json({
      connected: appState.githubConfig.connected,
      owner: appState.githubConfig.owner,
      repo: appState.githubConfig.repo,
      defaultBranch: appState.githubConfig.defaultBranch,
      activeBranch,
      pendingPrSyncCount,
      stagedCount,
      openPrCount,
      draftPrCount,
      mergedPrCount,
      latestPrNumber,
      latestSha,
      daemonActive: appState.daemonActive,
      syncState: !appState.githubConfig.connected
        ? 'disconnected'
        : stagedCount > 0
        ? 'pending_sync'
        : draftPrCount > 0
        ? 'draft_pending'
        : 'synced',
      lastSyncedAt: appState.githubConfig.lastSyncedAt || 'Just now',
      checkedAt: new Date().toISOString(),
    });
  });

  // Trigger an immediate branch/PR synchronization or update target base branch
  app.post('/api/github/sync-now', (req, res) => {
    const { defaultBranch, pushStaged } = (req.body || {}) as {
      defaultBranch?: string;
      pushStaged?: boolean;
    };

    if (defaultBranch && typeof defaultBranch === 'string') {
      appState.githubConfig = {
        ...appState.githubConfig,
        defaultBranch,
        connected: true,
        lastSyncedAt: 'Just now',
      };
      appState.policy = {
        ...appState.policy,
        baseBranch: defaultBranch,
      };
    } else {
      appState.githubConfig = {
        ...appState.githubConfig,
        connected: true,
        lastSyncedAt: 'Just now',
      };
    }

    if (pushStaged && appState.stagedAtomicStack.length > 0) {
      let highestPr = Math.max(
        142,
        ...appState.pushedStack.map((p) => p.prNumber || 140)
      );
      const newlyPushed: AtomicCommitUnit[] = appState.stagedAtomicStack.map(
        (unit) => {
          highestPr += 1;
          return {
            ...unit,
            status: 'pr_open',
            prNumber: highestPr,
          };
        }
      );
      appState.workingTreeHunks = [];
      appState.stagedAtomicStack = [];
      appState.pushedStack = [...newlyPushed.reverse(), ...appState.pushedStack];
    }

    saveState(appState);
    res.json({
      ok: true,
      state: appState,
      syncedAt: new Date().toISOString(),
    });
  });

  // AI + Deterministic Atomic Commit Message Refiner
  app.post('/api/ai/refine-stack', async (req, res) => {
    const { hunks, policy } = req.body as {
      hunks: DiffHunk[];
      policy: GuardrailPolicy;
    };

    const targetHunks = Array.isArray(hunks) ? hunks : appState.workingTreeHunks;
    const targetPolicy = policy || appState.policy;

    // First compute deterministic compliant stack
    const baseStack = sliceHunksIntoAtomicCommits(targetHunks, targetPolicy);

    const ai = getGenAIClient();
    if (!ai || baseStack.length === 0) {
      appState.stagedAtomicStack = baseStack;
      saveState(appState);
      res.json({
        stack: baseStack,
        engine: 'deterministic-ast-slicer',
      });
      return;
    }

    try {
      const promptSummary = baseStack
        .map(
          (u, idx) =>
            `Unit ${idx + 1}: type=${u.type}, scope=${u.scope}, files=${u.hunks
              .map((h) => h.filePath)
              .join(', ')}, summaries=${u.hunks.map((h) => h.summary).join('; ')}`
        )
        .join('\n');

      const response = await ai.models.generateContent({
        model: 'gemini-3.8-flash',
        contents: `Refine these ${baseStack.length} atomic git commits into senior-engineer Conventional Commit subjects (imperative mood, concise, under 68 chars, no trailing period) and 2 architectural rationale bullets per commit:\n${promptSummary}`,
        config: {
          systemInstruction:
            'You are a Principal Staff Engineer enforcing atomic commits and Conventional Commits 1.0. Return JSON matching the requested schema.',
          responseMimeType: 'application/json',
          responseSchema: {
            type: Type.ARRAY,
            items: {
              type: Type.OBJECT,
              properties: {
                unitIndex: { type: Type.INTEGER },
                title: { type: Type.STRING },
                rationaleBullets: {
                  type: Type.ARRAY,
                  items: { type: Type.STRING },
                },
              },
            },
          },
        },
      });

      const parsed = JSON.parse((response.text ?? '[]').trim()) as Array<{
        unitIndex?: number;
        title?: string;
        rationaleBullets?: string[];
      }>;

      const refinedStack = baseStack.map((unit, idx) => {
        const match = parsed[idx];
        if (!match || !match.title) return unit;
        const cleanTitle = match.title.trim();
        return {
          ...unit,
          title: cleanTitle,
          conventionalHeader: formatConventionalHeader(unit.type, unit.scope, cleanTitle),
          bodyBullets:
            Array.isArray(match.rationaleBullets) && match.rationaleBullets.length > 0
              ? match.rationaleBullets
              : unit.bodyBullets,
        };
      });

      appState.stagedAtomicStack = refinedStack;
      saveState(appState);
      res.json({
        stack: refinedStack,
        engine: 'gemini-3.8-flash',
      });
    } catch (err) {
      // Graceful fallback to deterministic stack
      console.warn('Gemini refinement fallback used:', err);
      appState.stagedAtomicStack = baseStack;
      saveState(appState);
      res.json({
        stack: baseStack,
        engine: 'deterministic-ast-slicer',
      });
    }
  });

  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (_req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`AtomikGit server listening on http://localhost:${PORT}`);
  });
}

startServer();
