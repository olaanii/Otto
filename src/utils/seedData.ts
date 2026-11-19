import {
  AntigravityPromptEvent,
  AtomicCommitUnit,
  DailyCadenceDay,
  DiffHunk,
  GitHubConnectionConfig,
  GuardrailPolicy,
  IdeAgentProfile,
} from '../types/git';

export const INITIAL_POLICY: GuardrailPolicy = {
  maxLocPerCommit: 120,
  maxFilesPerCommit: 3,
  enforceConventionalCommits: true,
  isolateBrainstormingDocs: true,
  requireTestsForFeatFix: true,
  autoCommitCadenceMinutes: 15,
  autoPushToGitHub: true,
  branchPrefix: 'atomik/',
  baseBranch: 'main',
};

export const INITIAL_GITHUB_CONFIG: GitHubConnectionConfig = {
  owner: '',
  repo: '',
  defaultBranch: 'main',
  connected: false,
  lastSyncedAt: '',
  mode: 'live',
};

export const INITIAL_IDE_PROFILES: IdeAgentProfile[] = [
  {
    id: 'antigravity',
    name: 'Google Antigravity',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
  {
    id: 'cursor',
    name: 'Cursor Composer',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
  {
    id: 'claude-code',
    name: 'Claude Code CLI',
    kind: 'CLI & MCP Agent',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
  {
    id: 'codex-cli',
    name: 'OpenAI Codex CLI',
    kind: 'CLI & MCP Agent',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
  {
    id: 'vscode',
    name: 'VS Code + Copilot Edits',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
  {
    id: 'windsurf',
    name: 'Windsurf Cascade',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
  {
    id: 'gemini-cli',
    name: 'Gemini CLI',
    kind: 'CLI & MCP Agent',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
  {
    id: 'kiro',
    name: 'Kiro Spec IDE',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: '',
    filesInFlight: 0,
    autoCommittedToday: 0,
    prsCreatedToday: 0,
    status: 'idle',
  },
];

export const INITIAL_WORKING_TREE_HUNKS: DiffHunk[] = [];

export const INITIAL_PUSHED_STACK: AtomicCommitUnit[] = [];

export const INITIAL_PROMPT_STREAM: AntigravityPromptEvent[] = [];

export const INITIAL_DAILY_CADENCE: DailyCadenceDay[] = [];

export function ensureThirtyDayCadence(existing?: DailyCadenceDay[]): DailyCadenceDay[] {
  return Array.isArray(existing) ? existing : [];
}

export function ensurePushedStackItems(existing?: AtomicCommitUnit[]): AtomicCommitUnit[] {
  return Array.isArray(existing) ? existing : [];
}