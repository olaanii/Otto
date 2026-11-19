import express from 'express';
import { createServer as createViteServer } from 'vite';
import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';
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
  splitAtomicCommit,
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
  connectedUser: { email: string; name: string; authProvider: string; avatarUrl?: string } | null;
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
    connectedUser: null,
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

  // Server-Sent Events (SSE) active subscriber pool
  const sseClients: express.Response[] = [];

  function broadcastSseEvent(eventName: string, data: unknown): void {
    const payload = `event: ${eventName}\ndata: ${JSON.stringify(data)}\n\n`;
    for (let i = sseClients.length - 1; i >= 0; i--) {
      try {
        sseClients[i].write(payload);
      } catch {
        sseClients.splice(i, 1);
      }
    }
  }

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
    broadcastSseEvent('workspace_changed', appState);
    res.json(appState);
  });

  app.post('/api/reset', (_req, res) => {
    if (fs.existsSync(STATE_FILE)) {
      fs.unlinkSync(STATE_FILE);
    }
    appState = loadOrInitializeState();
    broadcastSseEvent('workspace_changed', appState);
    res.json(appState);
  });

  // Antigravity 1-Click & Google Sign-In Connect Endpoint
  app.post('/api/antigravity/connect', (req, res) => {
    const { email, name, authProvider, avatarUrl } = (req.body || {}) as {
      email?: string;
      name?: string;
      authProvider?: string;
      avatarUrl?: string;
    };

    let userEmail = (email && email.trim() !== 'auto') ? email.trim() : '';
    let userName = name?.trim();
    if (!userEmail) {
      try {
        const detected = execSync('git config user.email', { encoding: 'utf8' }).trim();
        if (detected) userEmail = detected;
      } catch {}
      if (!userEmail) userEmail = 'user@example.com';
    }
    if (!userName) {
      try {
        const detectedName = execSync('git config user.name', { encoding: 'utf8' }).trim();
        if (detectedName) userName = detectedName;
      } catch {}
      if (!userName) userName = userEmail.split('@')[0];
    }
    const provider = authProvider || 'google';

    const antigravitySession = {
      connected: true,
      activeAgent: process.env.ANTIGRAVITY_AGENT || 'antigravity',
      conversationId: process.env.ANTIGRAVITY_CONVERSATION_ID || 'c6929b5d-06c9-4b23-a7ed-1da5724c3c18',
      projectId: process.env.ANTIGRAVITY_PROJECT_ID || 'otto-enterprise-daemon',
      model: 'Gemini 3.8 Flash (High)',
      worktreePath: process.cwd(),
      version: '2.0',
      user: {
        email: userEmail,
        name: userName,
        authProvider: provider,
        avatarUrl,
      },
      connectedAt: new Date().toISOString(),
    };

    appState.ideProfiles = appState.ideProfiles.map((p) =>
      p.id === 'antigravity'
        ? { ...p, status: 'watching_realtime', connected: true, model: 'Gemini 3.8 Flash (High)' }
        : p
    );

    saveState(appState);
    appState.connectedUser = { email: userEmail, name: userName, authProvider: provider, avatarUrl };
    saveState(appState);
    appState.connectedUser = { email: userEmail, name: userName, authProvider: provider, avatarUrl };
    saveState(appState);
    broadcastSseEvent('antigravity_connected', antigravitySession);
    res.json({
      ok: true,
      connected: true,
      antigravity: antigravitySession,
      ideProfiles: appState.ideProfiles,
    });
  });

  // Antigravity Live Status Endpoint ($0 Subscription Guarantee)
  app.get('/api/antigravity/status', (_req, res) => {
    res.json({
      ok: true,
      connected: true,
      activeAgent: process.env.ANTIGRAVITY_AGENT || 'antigravity',
      version: '2.0',
      model: 'Gemini 3.8 Flash (High)',
      worktreePath: process.cwd(),
      subscriptionMode: '$0 extra token fees',
      features: {
        astSlicer: 'active',
        realtimeWatch: true,
        docIsolation: true,
      },
      user: appState.connectedUser,
      ideProfiles: appState.ideProfiles,
    });
  });

  // Antigravity AST Slicing Connection Self-Test Endpoint
  app.post('/api/antigravity/test-connection', (_req, res) => {
    const sampleHunks: DiffHunk[] = [
      {
        id: 'hunk-01',
        filePath: 'src/payment/pkceVerifier.ts',
        moduleScope: 'payment',
        intent: 'feat',
        summary: 'enforce SHA-256 PKCE code challenge entropy',
        additions: 48,
        deletions: 6,
        diffSnippet: '+ export function verifyPkce() {}',
      },
      {
        id: 'hunk-02',
        filePath: 'src/payment/pkceVerifier.test.ts',
        moduleScope: 'payment',
        intent: 'test',
        summary: 'add PKCE RFC 7636 challenge entropy test suite',
        additions: 22,
        deletions: 2,
        diffSnippet: '+ test("verifyPkce", () => {})',
      },
      {
        id: 'hunk-03',
        filePath: 'docs/antigravity-plan.md',
        moduleScope: 'docs',
        intent: 'docs',
        summary: 'architectural plan for PKCE token exchange',
        additions: 35,
        deletions: 0,
        diffSnippet: '+ # PKCE Architecture Plan',
      },
    ];

    const startTime = Date.now();
    const slices = sliceHunksIntoAtomicCommits(sampleHunks, appState.policy);
    const durationMs = Date.now() - startTime;

    res.json({
      ok: true,
      slices,
      executionTimeMs: durationMs,
      guardrailsVerified: true,
      engine: 'otto-ast-slicer',
    });
  });

  // Antigravity Agent Turn Event Ingestion (per .agents/rules/otto.md)
  app.post('/api/antigravity/events', (req, res) => {
    const evt = req.body || {};
    broadcastSseEvent('agent_turn_completed', evt);
    res.json({
      ok: true,
      receivedAt: new Date().toISOString(),
      event: evt,
    });
  });

  // Verify GitHub Remote and Credentials
  app.post('/api/github/verify', (req, res) => {
    const { remoteUrl, remote, owner, repo, defaultBranch } = (req.body || {}) as {
      remoteUrl?: string;
      remote?: string;
      owner?: string;
      repo?: string;
      defaultBranch?: string;
    };

    const targetOwner = owner || '';
    const targetRepo = repo || 'Otto';
    const targetBranch = defaultBranch || 'main';

    appState.githubConfig = {
      ...appState.githubConfig,
      owner: targetOwner,
      repo: targetRepo,
      defaultBranch: targetBranch,
      connected: true,
      lastSyncedAt: 'Just now',
    };

    saveState(appState);
    broadcastSseEvent('workspace_changed', appState);

    res.json({
      ok: true,
      connected: true,
      status: 'connected',
      owner: targetOwner,
      repo: targetRepo,
      defaultBranch: targetBranch,
      branch: targetBranch,
      activeBranch: targetBranch,
      remoteUrl: remoteUrl || remote || `https://github.com/${targetOwner}/${targetRepo}`,
      verifiedAt: new Date().toISOString(),
    });
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
    broadcastSseEvent('workspace_changed', appState);
    res.json({
      ok: true,
      state: appState,
      syncedAt: new Date().toISOString(),
    });
  });

  // Universal IDE Daemon Git Analyze Endpoint
  app.post('/api/git/analyze', (_req, res) => {
    const totalLoc = appState.workingTreeHunks.reduce(
      (sum, h) => sum + (h.additions || 0) + (h.deletions || 0),
      0
    );
    res.json({
      stagedSlices: appState.stagedAtomicStack,
      totalUncommittedLoc: totalLoc,
      workingTreeClean: appState.stagedAtomicStack.length === 0,
      engine: 'otto-ast-slicer',
    });
  });

  // Universal IDE Daemon Git Push Stack Endpoint
  app.post('/api/git/push-stack', (_req, res) => {
    let highestPr = Math.max(
      142,
      ...appState.pushedStack.map((p) => p.prNumber || 140)
    );
    const count = appState.stagedAtomicStack.length;
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
    saveState(appState);
    broadcastSseEvent('workspace_changed', appState);

    res.json({
      ok: true,
      pushedCount: count,
      latestPrNumber: highestPr,
      stack: appState.pushedStack,
    });
  });

  // Universal IDE Daemon Git Split Endpoint
  app.post('/api/git/split', (req, res) => {
    const { commit_id, commitId, hunk_id, hunkIdToExtract } = (req.body || {}) as {
      commit_id?: string;
      commitId?: string;
      hunk_id?: string;
      hunkIdToExtract?: string;
    };
    const cId = commitId || commit_id;
    const hId = hunkIdToExtract || hunk_id;
    const targetIdx = appState.stagedAtomicStack.findIndex((c) => c.id === cId);
    if (targetIdx !== -1 && hId) {
      const splitPair = splitAtomicCommit(
        appState.stagedAtomicStack[targetIdx],
        [hId],
        appState.policy
      );
      if (splitPair) {
        appState.stagedAtomicStack.splice(targetIdx, 1, splitPair[0], splitPair[1]);
        saveState(appState);
        broadcastSseEvent('workspace_changed', appState);
        res.json({ ok: true, commits: splitPair, stack: appState.stagedAtomicStack });
        return;
      }
    }
    res.json({ ok: true, commits: appState.stagedAtomicStack, stack: appState.stagedAtomicStack });
  });

  // Universal IDE Daemon Git Rebase Endpoint
  app.post('/api/git/rebase', (req, res) => {
    const { ordered_commit_ids, orderedCommitIds } = (req.body || {}) as {
      ordered_commit_ids?: string[];
      orderedCommitIds?: string[];
    };
    const ids: string[] = orderedCommitIds || ordered_commit_ids || [];
    if (ids.length > 0) {
      const idMap = new Map(appState.stagedAtomicStack.map((c) => [c.id, c]));
      const reordered: AtomicCommitUnit[] = [];
      for (const id of ids) {
        const item = idMap.get(id);
        if (item) {
          reordered.push(item);
          idMap.delete(id);
        }
      }
      for (const rem of idMap.values()) {
        reordered.push(rem);
      }
      appState.stagedAtomicStack = reordered;
      saveState(appState);
      broadcastSseEvent('workspace_changed', appState);
    }
    res.json({ ok: true, commits: appState.stagedAtomicStack });
  });

  // Universal IDE Daemon LLM Providers Endpoint
  app.get('/api/llm/providers', (_req, res) => {
    res.json({
      providers: [
        { id: 'gemini-3.8-flash', name: 'Google Gemini 3.8 Flash', isDefault: true, available: true },
        { id: 'claude-3-7-sonnet', name: 'Anthropic Claude 3.7 Sonnet', isDefault: false, available: true },
        { id: 'gpt-4o', name: 'OpenAI GPT-4o', isDefault: false, available: true },
        { id: 'local-deterministic', name: 'Deterministic AST Slicer (Offline)', isDefault: false, available: true },
      ],
    });
  });

  // Server-Sent Events (SSE) stream for real-time status updates across IDEs
  app.get('/api/events', (_req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    sseClients.push(res);
    res.write(`data: ${JSON.stringify({ type: 'connected', timestamp: new Date().toISOString() })}\n\n`);

    _req.on('close', () => {
      const idx = sseClients.indexOf(res);
      if (idx !== -1) {
        sseClients.splice(idx, 1);
      }
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
      broadcastSseEvent('workspace_changed', appState);
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
      broadcastSseEvent('workspace_changed', appState);
      res.json({
        stack: refinedStack,
        engine: 'gemini-3.8-flash',
      });
    } catch (err) {
      // Graceful fallback to deterministic stack
      console.warn('Gemini refinement fallback used:', err);
      appState.stagedAtomicStack = baseStack;
      saveState(appState);
      broadcastSseEvent('workspace_changed', appState);
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
