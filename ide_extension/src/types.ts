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

export interface GitHubConnectionConfig {
  owner: string;
  repo: string;
  defaultBranch: string;
  connected: boolean;
  lastSyncedAt?: string;
  mode?: 'simulated_git_ledger' | 'github_rest_api';
}

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

export interface WorkspaceState {
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  ideProfiles: IdeAgentProfile[];
  workingTreeHunks: DiffHunk[];
  stagedAtomicStack: AtomicCommitUnit[];
  pushedStack: AtomicCommitUnit[];
  daemonActive: boolean;
}

export type State = WorkspaceState;

export interface ClerkUser {
  id: string;
  fullName: string;
  primaryEmail: string;
  avatarUrl: string;
  role: 'engineer' | 'lead' | 'architect';
  organization: string;
}

export interface ClerkSession {
  token: string;
  expiresAt: number;
  user: ClerkUser;
  isAuthenticated: boolean;
}

export interface DaemonAnalyzeRequest {
  hunks?: DiffHunk[];
  filePath?: string;
  fileContent?: string;
  sourceAgent?: IdeHostId;
  forceAi?: boolean;
}

export interface DaemonAnalyzeResponse {
  stagedSlices: AtomicCommitUnit[];
  totalUncommittedLoc: number;
  workingTreeClean: boolean;
  engine: string;
}

export interface DaemonPushStackRequest {
  commitIds?: string[];
  pushAll?: boolean;
  autoOpenPrs?: boolean;
}

export interface DaemonPushStackResponse {
  ok: boolean;
  pushedCount: number;
  latestPrNumber: number;
  stack: AtomicCommitUnit[];
}

export interface DaemonEvent {
  type: 'state_updated' | 'slice_staged' | 'stack_pushed' | 'daemon_status' | 'error';
  timestamp: string;
  payload: any;
}
