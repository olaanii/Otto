export type CommitType = 'feat' | 'fix' | 'refactor' | 'test' | 'docs' | 'chore' | 'perf';

export type IdeHostId =
  | 'antigravity'
  | 'cursor'
  | 'vscode'
  | 'windsurf'
  | 'claude-code'
  | 'codex-cli'
  | 'gemini-cli'
  | 'kiro';

export interface IdeAgentProfile {
  id: IdeHostId;
  name: string;
  kind: 'IDE Extension Overlay' | 'CLI & MCP Agent';
  activeTaskTitle: string;
  filesInFlight: number;
  autoCommittedToday: number;
  prsCreatedToday: number;
  status: 'watching_realtime' | 'slicing_diff' | 'pr_synced';
}

export interface DiffHunk {
  id: string;
  filePath: string;
  moduleScope: string;
  intent: CommitType;
  summary: string;
  additions: number;
  deletions: number;
  diffSnippet: string;
  promptContext?: string;
  sourceAgent?: IdeHostId;
  isBrainstormOrPlan?: boolean;
  hasCoupledTest?: boolean;
}

export interface AtomicCommitUnit {
  id: string;
  type: CommitType;
  scope: string;
  title: string;
  conventionalHeader: string;
  bodyBullets: string[];
  branchName: string;
  parentBranch: string;
  hunks: DiffHunk[];
  totalAdditions: number;
  totalDeletions: number;
  totalLoc: number;
  reviewMinutes: number;
  complianceScore: number;
  violations: string[];
  status: 'staged' | 'queued' | 'pushed' | 'pr_open' | 'merged' | 'draft';
  sha?: string;
  prNumber?: number;
  createdAt: string;
  promptOrigin?: string;
  sourceAgent?: IdeHostId;
}

export interface GuardrailPolicy {
  maxLocPerCommit: number;
  maxFilesPerCommit: number;
  enforceConventionalCommits: boolean;
  isolateBrainstormingDocs: boolean;
  requireTestsForFeatFix: boolean;
  autoCommitCadenceMinutes: number;
  autoPushToGitHub: boolean;
  branchPrefix: string;
  baseBranch: string;
}

export interface AntigravityPromptEvent {
  id: string;
  timestamp: string;
  promptText: string;
  sourceAgent?: IdeHostId;
  category: 'feature' | 'bugfix' | 'brainstorm' | 'refactor' | 'plan';
  filesTouched: string[];
  locDelta: string;
  agentAction: string;
  generatedCommitIds: string[];
}

export interface DailyCadenceDay {
  date: string;
  label: string;
  atomicCommitsCount: number;
  prsStackedCount: number;
  avgLocPerCommit: number;
  bulkCommitsPrevented: number;
}

export interface GitHubConnectionConfig {
  owner: string;
  repo: string;
  defaultBranch: string;
  connected: boolean;
  lastSyncedAt?: string;
  mode: 'simulated_git_ledger' | 'github_rest_api';
}
