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
  owner: 'olaniketema',
  repo: 'antigravity-core-platform',
  defaultBranch: 'main',
  connected: true,
  lastSyncedAt: '2026-11-06T04:55:00.000Z',
  mode: 'simulated_git_ledger',
};

export const INITIAL_IDE_PROFILES: IdeAgentProfile[] = [
  {
    id: 'antigravity',
    name: 'Antigravity IDE',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: 'Stripe webhook signature verifier & HMAC timing guard',
    filesInFlight: 3,
    autoCommittedToday: 5,
    prsCreatedToday: 2,
    status: 'watching_realtime',
  },
  {
    id: 'cursor',
    name: 'Cursor Composer',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: 'Token refresh race-condition mutex & session deduplication',
    filesInFlight: 1,
    autoCommittedToday: 4,
    prsCreatedToday: 1,
    status: 'slicing_diff',
  },
  {
    id: 'claude-code',
    name: 'Claude Code CLI',
    kind: 'CLI & MCP Agent',
    activeTaskTitle: 'Dead-letter exponential backoff retry queue & unit specs',
    filesInFlight: 2,
    autoCommittedToday: 6,
    prsCreatedToday: 2,
    status: 'watching_realtime',
  },
  {
    id: 'codex-cli',
    name: 'OpenAI Codex CLI',
    kind: 'CLI & MCP Agent',
    activeTaskTitle: 'Multi-currency settlement ledger schema & brainstorm notes',
    filesInFlight: 1,
    autoCommittedToday: 3,
    prsCreatedToday: 1,
    status: 'pr_synced',
  },
  {
    id: 'vscode',
    name: 'VS Code + Copilot Edits',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: 'Idempotency envelope TypeScript interfaces',
    filesInFlight: 1,
    autoCommittedToday: 4,
    prsCreatedToday: 1,
    status: 'pr_synced',
  },
  {
    id: 'windsurf',
    name: 'Windsurf Cascade',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: 'Tenant rate-limiter middleware & burst headers',
    filesInFlight: 0,
    autoCommittedToday: 3,
    prsCreatedToday: 1,
    status: 'pr_synced',
  },
  {
    id: 'gemini-cli',
    name: 'Gemini CLI',
    kind: 'CLI & MCP Agent',
    activeTaskTitle: 'OAuth PKCE verifier exchange & session cookie bounds',
    filesInFlight: 1,
    autoCommittedToday: 4,
    prsCreatedToday: 2,
    status: 'watching_realtime',
  },
  {
    id: 'kiro',
    name: 'Kiro Spec IDE',
    kind: 'IDE Extension Overlay',
    activeTaskTitle: 'Spec-driven checkout receipt component & currency contracts',
    filesInFlight: 1,
    autoCommittedToday: 3,
    prsCreatedToday: 1,
    status: 'pr_synced',
  },
];

export const INITIAL_WORKING_TREE_HUNKS: DiffHunk[] = [
  {
    id: 'hunk-101',
    filePath: 'src/types/payment.ts',
    moduleScope: 'payment',
    intent: 'refactor',
    summary: 'Extract strict idempotency key and webhook payload contracts',
    additions: 32,
    deletions: 8,
    promptContext: 'Antigravity: Refactor payment webhook types before adding Stripe signature verifier',
    sourceAgent: 'antigravity',
    isBrainstormOrPlan: false,
    diffSnippet: `@@ -1,10 +1,24 @@
+export type WebhookEventType =
+  | 'charge.succeeded'
+  | 'charge.failed'
+  | 'subscription.updated'
+  | 'payout.reconciled';
+
-export interface RawWebhookPayload {
-  id: string;
-  data: any;
-}
+export interface IdempotencyEnvelope<T = Record<string, unknown>> {
+  readonly eventId: string;
+  readonly idempotencyKey: string;
+  readonly eventType: WebhookEventType;
+  readonly occurredAtIso: string;
+  readonly signatureVersion: 'v1';
+  readonly payload: T;
+}
@@ -34,6 +48,14 @@ export interface WebhookDeliveryMetadata {
   readonly attemptCount: number;
-  readonly rawHeaders: Record<string, string>;
+  readonly signatureHeader: string;
+  readonly replayWindowSeconds: number;
+}
+
+export interface WebhookVerificationResult {
+  readonly verified: boolean;
+  readonly replayAgeSeconds: number;
+  readonly reason?: 'invalid_timestamp' | 'replay_window_exceeded' | 'digest_mismatch';
 }`,
  },
  {
    id: 'hunk-101b',
    filePath: 'src/payment/idempotencyNormalizer.ts',
    moduleScope: 'payment',
    intent: 'refactor',
    summary: 'Normalize incoming Stripe idempotency headers into canonical envelope keys',
    additions: 24,
    deletions: 6,
    promptContext: 'Antigravity: Refactor payment webhook types before adding Stripe signature verifier',
    sourceAgent: 'antigravity',
    isBrainstormOrPlan: false,
    diffSnippet: `@@ -8,9 +8,23 @@ import type { IdempotencyEnvelope, WebhookEventType } from '../types/payment';
 
-export function parseIdempotencyHeader(rawHeader?: string): string {
-  return rawHeader || 'default_key';
+export function normalizeIdempotencyKey(eventId: string, rawHeader?: string): string {
+  const trimmed = (rawHeader ?? '').trim();
+  if (trimmed.length >= 12 && /^[a-zA-Z0-9._-]+$/.test(trimmed)) {
+    return \`idem_\${trimmed}\`;
+  }
+  return \`idem_\${eventId.replace(/[^a-zA-Z0-9_-]/g, '')}\`;
+}
+
+export function createIdempotencyEnvelope<T>(
+  eventId: string,
+  eventType: WebhookEventType,
+  payload: T,
+  rawHeader?: string
+): IdempotencyEnvelope<T> {
+  return {
+    eventId,
+    idempotencyKey: normalizeIdempotencyKey(eventId, rawHeader),
+    eventType,
+    occurredAtIso: new Date().toISOString(),
+    signatureVersion: 'v1',
+    payload,
+  };
 }`,
  },
  {
    id: 'hunk-102',
    filePath: 'src/payment/webhookHandler.ts',
    moduleScope: 'payment',
    intent: 'feat',
    summary: 'Verify HMAC-SHA256 webhook signatures with 300s replay tolerance',
    additions: 56,
    deletions: 12,
    promptContext: 'Antigravity: Implement Stripe webhook signature verification and replay guard',
    sourceAgent: 'antigravity',
    isBrainstormOrPlan: false,
    diffSnippet: `@@ -18,12 +18,31 @@ import { computeHmacSha256, timingSafeDigestMatch } from './signatureCrypto';
 
-export function verifyWebhookSignature(rawBody: string, signatureHeader: string): boolean {
-  return signatureHeader.startsWith('v1=');
-}
+export function verifyWebhookSignature(
+  rawBody: string,
+  signatureHeader: string,
+  secret: string,
+  toleranceSec = 300
+): boolean {
+  const [timestampPart, sigPart] = signatureHeader.split(',');
+  const timestamp = Number(timestampPart?.replace('t=', ''));
+  if (!Number.isFinite(timestamp) || timestamp <= 0) {
+    return false;
+  }
+  const ageSec = Math.abs(Math.floor(Date.now() / 1000) - timestamp);
+  if (ageSec > toleranceSec) {
+    return false;
+  }
+  const expectedDigest = computeHmacSha256(\`\${timestamp}.\${rawBody}\`, secret);
+  const candidateDigest = sigPart?.replace('v1=', '') ?? '';
+  return timingSafeDigestMatch(expectedDigest, candidateDigest);
+}`,
  },
  {
    id: 'hunk-102b',
    filePath: 'src/payment/signatureCrypto.ts',
    moduleScope: 'payment',
    intent: 'feat',
    summary: 'Add timing-safe HMAC digest comparator for webhook verification',
    additions: 28,
    deletions: 4,
    promptContext: 'Antigravity: Implement Stripe webhook signature verification and replay guard',
    sourceAgent: 'antigravity',
    isBrainstormOrPlan: false,
    diffSnippet: `@@ -1,6 +1,19 @@
-import { createHmac } from 'node:crypto';
+import { createHmac, timingSafeEqual } from 'node:crypto';
 
 export function computeHmacSha256(payload: string, secret: string): string {
   return createHmac('sha256', secret).update(payload, 'utf8').digest('hex');
 }
+
+export function timingSafeDigestMatch(expectedHex: string, candidateHex: string): boolean {
+  if (!expectedHex || !candidateHex || expectedHex.length !== candidateHex.length) {
+    return false;
+  }
+  const left = Buffer.from(expectedHex, 'utf8');
+  const right = Buffer.from(candidateHex, 'utf8');
+  return timingSafeEqual(left, right);
+}`,
  },
  {
    id: 'hunk-103',
    filePath: 'src/payment/retryQueue.ts',
    moduleScope: 'payment',
    intent: 'feat',
    summary: 'Add exponential backoff dead-letter queue for transient webhook failures',
    additions: 44,
    deletions: 8,
    promptContext: 'Claude Code CLI: Add dead-letter retry scheduler with jittered backoff',
    sourceAgent: 'claude-code',
    isBrainstormOrPlan: false,
    diffSnippet: `@@ -12,10 +12,26 @@ export interface DeadLetterJob {
   readonly eventId: string;
   readonly attempt: number;
-  readonly nextRunAt: number;
+  readonly nextRunAtEpochMs: number;
+  readonly lastFailureCode: string;
 }
 
-export function computeNextRetryDelayMs(attempt: number): number {
-  return attempt * 1000;
+export function computeNextRetryDelayMs(attempt: number, baseDelayMs = 1500): number {
+  const cappedAttempt = Math.max(0, Math.min(attempt, 6));
+  const exponential = baseDelayMs * Math.pow(2, cappedAttempt);
+  const deterministicJitter = (cappedAttempt * 313) % 450;
+  return exponential + deterministicJitter;
 }`,
  },
  {
    id: 'hunk-103b',
    filePath: 'src/types/payment.ts',
    moduleScope: 'payment',
    intent: 'feat',
    summary: 'Extend WebhookEventType union with dead-letter exhaustion event contracts',
    additions: 20,
    deletions: 4,
    promptContext: 'Claude Code CLI: Add dead-letter retry scheduler with jittered backoff',
    sourceAgent: 'claude-code',
    isBrainstormOrPlan: false,
    diffSnippet: `@@ -1,12 +1,22 @@
 export type WebhookEventType =
   | 'charge.succeeded'
   | 'charge.failed'
+  | 'charge.dlq_exhausted'
+  | 'payout.dlq_requeued'
   | 'subscription.updated';
 
+export interface DeadLetterWebhookEnvelope {
+  readonly eventId: string;
+  readonly eventType: WebhookEventType;
+  readonly maxRetriesReached: boolean;
+  readonly deadLetteredAtIso: string;
+}`,
  },
  {
    id: 'hunk-104',
    filePath: 'src/auth/tokenRefresh.ts',
    moduleScope: 'auth',
    intent: 'fix',
    summary: 'Prevent concurrent token refresh race condition via in-flight promise deduplication',
    additions: 38,
    deletions: 16,
    promptContext: 'Cursor Composer: Fix intermittent 401 logout bug when two tabs refresh JWT simultaneously',
    sourceAgent: 'cursor',
    isBrainstormOrPlan: false,
    diffSnippet: `@@ -24,11 +24,23 @@ export interface TokenPair {
   readonly accessToken: string;
   readonly refreshToken: string;
   readonly expiresAtEpochMs: number;
 }
 
-export async function refreshSessionToken(refreshToken: string) {
-  return fetchNewTokenPair(refreshToken);
-}
+let inFlightRefreshPromise: Promise<TokenPair> | null = null;
+
+export async function refreshSessionToken(refreshToken: string): Promise<TokenPair> {
+  if (inFlightRefreshPromise) {
+    return inFlightRefreshPromise;
+  }
+  inFlightRefreshPromise = fetchNewTokenPair(refreshToken).finally(() => {
+    inFlightRefreshPromise = null;
+  });
+  return inFlightRefreshPromise;
+}`,
  },
  {
    id: 'hunk-105',
    filePath: 'src/payment/webhookHandler.test.ts',
    moduleScope: 'payment',
    intent: 'test',
    summary: 'Add unit tests covering stale replay timestamps and tampered HMAC signatures',
    additions: 62,
    deletions: 4,
    promptContext: 'Claude Code CLI: Write unit specs for signature mismatch and replay window',
    sourceAgent: 'claude-code',
    isBrainstormOrPlan: false,
    hasCoupledTest: true,
    diffSnippet: `@@ -1,6 +1,22 @@
 import assert from 'node:assert/strict';
 import test from 'node:test';
 import { verifyWebhookSignature } from './webhookHandler';
 
-test('placeholder webhook test', () => {});
+test('rejects webhook payload when timestamp exceeds 300s replay window', () => {
+  const staleTimestamp = Math.floor(Date.now() / 1000) - 900;
+  const valid = verifyWebhookSignature(
+    '{"id":"evt_1","type":"charge.succeeded"}',
+    \`t=\${staleTimestamp},v1=deadbeef\`,
+    'whsec_test_secret'
+  );
+  assert.equal(valid, false);
+});
+
+test('rejects tampered webhook body even when timestamp is fresh', () => {
+  const nowSec = Math.floor(Date.now() / 1000);
+  const valid = verifyWebhookSignature('{"id":"evt_tampered"}', \`t=\${nowSec},v1=0000\`, 'whsec_test_secret');
+  assert.equal(valid, false);
+});`,
  },
  {
    id: 'hunk-106',
    filePath: 'docs/antigravity-brainstorm-ledger.md',
    moduleScope: 'plans',
    intent: 'docs',
    summary: 'Document multi-currency settlement brainstorming and Q4 architectural goals',
    additions: 52,
    deletions: 6,
    promptContext: 'OpenAI Codex CLI: Brainstorm multi-currency settlement goals and roadmap milestones',
    sourceAgent: 'codex-cli',
    isBrainstormOrPlan: true,
    diffSnippet: `@@ -1,6 +1,16 @@
-# Ledger Notes
-- Draft settlement ideas
+# Multi-Currency Settlement Architecture & Q4 Invariants
+
+## Core Settlement Invariants
+- Isolate FX conversion rate locks at checkout authorization time (\`fx_quote_id\`).
+- Enforce immutable double-entry ledger journal postings across all settlement batches.
+- Route all minor-unit rounding residuals to dedicated \`acct_fx_rounding_reserve\`.
+
+## Isolation Policy
+- Isolated from runtime feature PR stack via Otto \`docs(plans)\` guardrail.`,
  },
];

export const INITIAL_PUSHED_STACK: AtomicCommitUnit[] = [
  {
    id: 'pushed-stack-1',
    type: 'refactor',
    scope: 'db',
    title: 'normalize ledger account foreign keys and composite indexes',
    conventionalHeader: 'refactor(db): normalize ledger account foreign keys and composite indexes',
    bodyBullets: [
      'src/db/schema.ts: Add composite index on (tenant_id, posted_at) (+48 / -12 LOC)',
      'src/db/migrations/004_ledger_idx.sql: Non-blocking concurrent index migration (+28 / -0 LOC)',
    ],
    branchName: 'atomik/refactor-db-ledger-indexes',
    parentBranch: 'main',
    hunks: [
      {
        id: 'hunk-pushed-101a',
        filePath: 'src/db/schema.ts',
        moduleScope: 'db',
        intent: 'refactor',
        summary: 'Add composite index on (tenant_id, posted_at) and strict foreign key cascade',
        additions: 48,
        deletions: 12,
        promptContext: 'Optimize slow tenant ledger queries before adding settlement',
        sourceAgent: 'antigravity',
        isBrainstormOrPlan: false,
        diffSnippet: `@@ -42,12 +42,27 @@ export const ledgerEntries = pgTable('ledger_entries', {
   id: uuid('id').defaultRandom().primaryKey(),
-  tenantId: varchar('tenant_id', { length: 64 }).notNull(),
-  accountId: varchar('account_id', { length: 64 }).notNull(),
+  tenantId: uuid('tenant_id')
+    .notNull()
+    .references(() => tenants.id, { onDelete: 'restrict' }),
+  accountId: uuid('account_id')
+    .notNull()
+    .references(() => ledgerAccounts.id, { onDelete: 'restrict' }),
   direction: varchar('direction', { length: 6 }).$type<'debit' | 'credit'>().notNull(),
   amountMinor: bigint('amount_minor', { mode: 'bigint' }).notNull(),
   currency: char('currency', { length: 3 }).notNull(),
   postedAt: timestamp('posted_at', { withTimezone: true }).defaultNow().notNull(),
-});
+}, (table) => ({
+  tenantPostedIdx: index('idx_ledger_entries_tenant_posted_at').on(
+    table.tenantId,
+    table.postedAt.desc()
+  ),
+  accountCurrencyIdx: index('idx_ledger_entries_account_currency').on(
+    table.accountId,
+    table.currency
+  ),
+}));`,
      },
      {
        id: 'hunk-pushed-101b',
        filePath: 'src/db/migrations/004_ledger_idx.sql',
        moduleScope: 'db',
        intent: 'refactor',
        summary: 'Non-blocking concurrent index migration for tenant ledger lookups',
        additions: 28,
        deletions: 0,
        promptContext: 'Optimize slow tenant ledger queries before adding settlement',
        sourceAgent: 'antigravity',
        isBrainstormOrPlan: false,
        diffSnippet: `@@ -1,3 +1,19 @@
+-- Migration: 004_ledger_idx.sql
+CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ledger_entries_tenant_posted_at
+  ON ledger_entries (tenant_id, posted_at DESC);
+
+CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ledger_entries_account_currency
+  ON ledger_entries (account_id, currency);
+
+ALTER TABLE ledger_entries
+  ADD CONSTRAINT fk_ledger_entries_account
+  FOREIGN KEY (account_id) REFERENCES ledger_accounts(id)
+  ON DELETE RESTRICT NOT VALID;
+
+ALTER TABLE ledger_entries
+  VALIDATE CONSTRAINT fk_ledger_entries_account;`,
      },
    ],
    totalAdditions: 76,
    totalDeletions: 12,
    totalLoc: 88,
    reviewMinutes: 3,
    complianceScore: 100,
    violations: [],
    status: 'merged',
    sha: '8f31a9c',
    prNumber: 141,
    createdAt: '2026-11-05T19:40:00.000Z',
    promptOrigin: 'Antigravity: Optimize slow tenant ledger queries before adding settlement',
    sourceAgent: 'antigravity',
  },
  {
    id: 'pushed-stack-2',
    type: 'feat',
    scope: 'ledger',
    title: 'implement double-entry journal posting service with balance invariant check',
    conventionalHeader: 'feat(ledger): implement double-entry journal posting service with balance invariant check',
    bodyBullets: [
      'src/ledger/journalService.ts: Enforce zero-sum debit/credit invariant prior to commit (+74 / -9 LOC)',
      'src/ledger/journalService.test.ts: Add property tests for unbalanced entry rejection (+31 / -0 LOC)',
    ],
    branchName: 'atomik/feat-ledger-double-entry',
    parentBranch: 'atomik/refactor-db-ledger-indexes',
    hunks: [
      {
        id: 'hunk-pushed-102a',
        filePath: 'src/ledger/journalService.ts',
        moduleScope: 'ledger',
        intent: 'feat',
        summary: 'Enforce zero-sum debit/credit invariant prior to transaction commit',
        additions: 74,
        deletions: 9,
        promptContext: 'Build double-entry journal service and invariant tests',
        sourceAgent: 'claude-code',
        isBrainstormOrPlan: false,
        diffSnippet: `@@ -14,9 +14,32 @@ export interface JournalLeg {
   readonly accountId: string;
   readonly direction: 'debit' | 'credit';
   readonly amountMinor: bigint;
 }
 
-export async function postJournalBatch(legs: JournalLeg[]): Promise<string> {
-  return db.insert(ledgerEntries).values(legs);
+export function assertZeroSumBatch(legs: readonly JournalLeg[]): void {
+  if (legs.length < 2) {
+    throw new Error('Double-entry journal batch requires at least 2 legs');
+  }
+  let netDelta = 0n;
+  for (const leg of legs) {
+    if (leg.amountMinor <= 0n) {
+      throw new Error(\`Leg amount must be positive for account \${leg.accountId}\`);
+    }
+    netDelta += leg.direction === 'debit' ? leg.amountMinor : -leg.amountMinor;
+  }
+  if (netDelta !== 0n) {
+    throw new Error(\`Unbalanced journal batch rejected: net delta \${netDelta.toString()}\`);
+  }
+}
+
+export async function postJournalBatch(
+  tenantId: string,
+  currency: string,
+  legs: readonly JournalLeg[]
+): Promise<{ batchId: string; legCount: number }> {
+  assertZeroSumBatch(legs);
+  const batchId = crypto.randomUUID();
+  await db.transaction(async (tx) => {
+    await tx.insert(ledgerEntries).values(legs.map((l) => ({ ...l, tenantId, currency, batchId })));
+  });
+  return { batchId, legCount: legs.length };
 }`,
      },
      {
        id: 'hunk-pushed-102b',
        filePath: 'src/ledger/journalService.test.ts',
        moduleScope: 'ledger',
        intent: 'test',
        summary: 'Add unit specs for unbalanced debit/credit batch rejection',
        additions: 31,
        deletions: 0,
        promptContext: 'Build double-entry journal service and invariant tests',
        sourceAgent: 'claude-code',
        isBrainstormOrPlan: false,
        hasCoupledTest: true,
        diffSnippet: `@@ -1,4 +1,22 @@
+import { describe, it, expect } from 'vitest';
+import { assertZeroSumBatch } from './journalService';
+
+describe('assertZeroSumBatch', () => {
+  it('accepts balanced debit and credit legs', () => {
+    expect(() =>
+      assertZeroSumBatch([
+        { accountId: 'acct_cash', direction: 'debit', amountMinor: 12500n },
+        { accountId: 'acct_rev', direction: 'credit', amountMinor: 12500n },
+      ])
+    ).not.toThrow();
+  });
+
+  it('rejects unbalanced journal legs with non-zero net delta', () => {
+    expect(() =>
+      assertZeroSumBatch([
+        { accountId: 'acct_cash', direction: 'debit', amountMinor: 12500n },
+        { accountId: 'acct_rev', direction: 'credit', amountMinor: 12000n },
+      ])
+    ).toThrow(/Unbalanced journal batch rejected/);
+  });
+});`,
      },
    ],
    totalAdditions: 105,
    totalDeletions: 9,
    totalLoc: 114,
    reviewMinutes: 4,
    complianceScore: 100,
    violations: [],
    status: 'pr_open',
    sha: '4d92e1b',
    prNumber: 142,
    createdAt: '2026-11-06T01:25:00.000Z',
    promptOrigin: 'Claude Code CLI: Build double-entry journal service and invariant tests',
    sourceAgent: 'claude-code',
  },
  {
    id: 'pushed-stack-3',
    type: 'fix',
    scope: 'auth',
    title: 'enforce SameSite lax and maxAge bounds on PKCE session cookie',
    conventionalHeader: 'fix(auth): enforce SameSite lax and maxAge bounds on PKCE session cookie',
    bodyBullets: [
      'src/auth/cookieJar.ts: Cap session cookie maxAge to 7 days and enforce HttpOnly (+26 / -8 LOC)',
    ],
    branchName: 'atomik/fix-auth-cookie-bounds',
    parentBranch: 'atomik/feat-ledger-double-entry',
    hunks: [
      {
        id: 'hunk-pushed-103a',
        filePath: 'src/auth/cookieJar.ts',
        moduleScope: 'auth',
        intent: 'fix',
        summary: 'Cap session cookie maxAge to 7 days and enforce SameSite=Lax + HttpOnly',
        additions: 26,
        deletions: 8,
        promptContext: 'Harden session cookie flags for PKCE callback',
        sourceAgent: 'cursor',
        isBrainstormOrPlan: false,
        diffSnippet: `@@ -19,12 +19,24 @@ const MAX_SESSION_TTL_SEC = 60 * 60 * 24 * 7; // 7 days hard cap
 
 export function serializePkceSessionCookie(
   sessionId: string,
-  requestedTtlSec = 60 * 60 * 24 * 30
+  requestedTtlSec = MAX_SESSION_TTL_SEC
 ): string {
-  return \`otto_sid=\${sessionId}; Path=/; Max-Age=\${requestedTtlSec}\`;
+  const boundedMaxAge = Math.max(60, Math.min(requestedTtlSec, MAX_SESSION_TTL_SEC));
+  const attributes = [
+    \`otto_sid=\${encodeURIComponent(sessionId)}\`,
+    'Path=/',
+    \`Max-Age=\${boundedMaxAge}\`,
+    'HttpOnly',
+    'Secure',
+    'SameSite=Lax',
+  ];
+  return attributes.join('; ');
 }`,
      },
    ],
    totalAdditions: 26,
    totalDeletions: 8,
    totalLoc: 34,
    reviewMinutes: 1,
    complianceScore: 100,
    violations: [],
    status: 'pr_open',
    sha: 'c209b4a',
    prNumber: 143,
    createdAt: '2026-11-06T03:10:00.000Z',
    promptOrigin: 'Cursor Composer: Harden session cookie flags for PKCE callback',
    sourceAgent: 'cursor',
  },
  {
    id: 'pushed-stack-4',
    type: 'feat',
    scope: 'checkout',
    title: 'scaffold localized minor-unit tax and subtotal receipt breakdown',
    conventionalHeader: 'feat(checkout): scaffold localized minor-unit tax and subtotal receipt breakdown',
    bodyBullets: [
      'src/components/ReceiptSummary.tsx: Format JPY/KRW zero-decimal and USD/EUR minor units (+51 / -9 LOC)',
    ],
    branchName: 'atomik/feat-checkout-receipt-draft',
    parentBranch: 'atomik/fix-auth-cookie-bounds',
    hunks: [
      {
        id: 'hunk-pushed-104a',
        filePath: 'src/components/ReceiptSummary.tsx',
        moduleScope: 'checkout',
        intent: 'feat',
        summary: 'Format JPY/KRW zero-decimal and USD/EUR two-decimal minor units in receipt breakdown',
        additions: 51,
        deletions: 9,
        promptContext: 'Generate localized receipt summary breakdown from checkout spec',
        sourceAgent: 'kiro',
        isBrainstormOrPlan: false,
        diffSnippet: `@@ -8,11 +8,29 @@ const ZERO_DECIMAL_CURRENCIES = new Set(['JPY', 'KRW', 'VND']);
 
 export function formatMinorCurrency(amountMinor: number, currency: string, locale = 'en-US'): string {
   const upperCurrency = currency.toUpperCase();
-  const major = amountMinor / 100;
-  return new Intl.NumberFormat(locale, { style: 'currency', currency: upperCurrency }).format(major);
+  const isZeroDecimal = ZERO_DECIMAL_CURRENCIES.has(upperCurrency);
+  const majorValue = isZeroDecimal ? amountMinor : amountMinor / 100;
+  return new Intl.NumberFormat(locale, {
+    style: 'currency',
+    currency: upperCurrency,
+    minimumFractionDigits: isZeroDecimal ? 0 : 2,
+    maximumFractionDigits: isZeroDecimal ? 0 : 2,
+  }).format(majorValue);
 }
 
 export function computeReceiptTotals(subtotalMinor: number, taxRateBps: number) {
+  const taxMinor = Math.round((subtotalMinor * taxRateBps) / 10_000);
+  return {
+    subtotalMinor,
+    taxMinor,
+    totalMinor: subtotalMinor + taxMinor,
+  };
 }`,
      },
    ],
    totalAdditions: 51,
    totalDeletions: 9,
    totalLoc: 60,
    reviewMinutes: 2,
    complianceScore: 100,
    violations: [],
    status: 'draft',
    sha: '7a18e3d',
    prNumber: 144,
    createdAt: '2026-11-06T05:45:00.000Z',
    promptOrigin: 'Kiro Spec IDE: Generate localized receipt summary breakdown from checkout spec',
    sourceAgent: 'kiro',
  },
];

export const INITIAL_PROMPT_STREAM: AntigravityPromptEvent[] = [
  {
    id: 'evt-44',
    timestamp: '2 mins ago',
    promptText: 'Brainstorm multi-currency settlement goals and roadmap milestones in docs/',
    sourceAgent: 'codex-cli',
    category: 'brainstorm',
    filesTouched: ['docs/antigravity-brainstorm-ledger.md'],
    locDelta: '+52 / -6',
    agentAction: 'Routed to isolated docs(plans) slice so feature PR stack stays pure',
    generatedCommitIds: [],
  },
  {
    id: 'evt-43',
    timestamp: '9 mins ago',
    promptText: 'Fix intermittent 401 logout bug when two tabs refresh JWT simultaneously',
    sourceAgent: 'cursor',
    category: 'bugfix',
    filesTouched: ['src/auth/tokenRefresh.ts'],
    locDelta: '+38 / -16',
    agentAction: 'Detected hotfix inside feature session — isolated into standalone fix(auth) slice',
    generatedCommitIds: [],
  },
  {
    id: 'evt-42',
    timestamp: '18 mins ago',
    promptText: 'Implement Stripe webhook signature verification, retry queue, and unit tests',
    sourceAgent: 'antigravity',
    category: 'feature',
    filesTouched: [
      'src/payment/webhookHandler.ts',
      'src/payment/signatureCrypto.ts',
      'src/payment/retryQueue.ts',
      'src/payment/webhookHandler.test.ts',
    ],
    locDelta: '+210 / -32',
    agentAction: 'Split 242 LOC across 2 atomic feat(payment) commits + 1 coupled test(payment) commit',
    generatedCommitIds: [],
  },
  {
    id: 'evt-41',
    timestamp: '27 mins ago',
    promptText: 'Refactor payment webhook types before adding Stripe signature verifier',
    sourceAgent: 'vscode',
    category: 'refactor',
    filesTouched: ['src/types/payment.ts'],
    locDelta: '+44 / -10',
    agentAction: 'Positioned refactor(payment) at root of PR stack (54 LOC)',
    generatedCommitIds: [],
  },
];

export const INITIAL_DAILY_CADENCE: DailyCadenceDay[] = [
  { date: '2026-10-08', label: 'Oct 8', atomicCommitsCount: 5, prsStackedCount: 2, avgLocPerCommit: 74, bulkCommitsPrevented: 1 },
  { date: '2026-10-09', label: 'Oct 9', atomicCommitsCount: 8, prsStackedCount: 3, avgLocPerCommit: 69, bulkCommitsPrevented: 2 },
  { date: '2026-10-10', label: 'Oct 10', atomicCommitsCount: 6, prsStackedCount: 2, avgLocPerCommit: 81, bulkCommitsPrevented: 2 },
  { date: '2026-10-11', label: 'Oct 11', atomicCommitsCount: 4, prsStackedCount: 1, avgLocPerCommit: 62, bulkCommitsPrevented: 1 },
  { date: '2026-10-12', label: 'Oct 12', atomicCommitsCount: 9, prsStackedCount: 3, avgLocPerCommit: 77, bulkCommitsPrevented: 3 },
  { date: '2026-10-13', label: 'Oct 13', atomicCommitsCount: 11, prsStackedCount: 4, avgLocPerCommit: 71, bulkCommitsPrevented: 3 },
  { date: '2026-10-14', label: 'Oct 14', atomicCommitsCount: 10, prsStackedCount: 3, avgLocPerCommit: 75, bulkCommitsPrevented: 2 },
  { date: '2026-10-15', label: 'Oct 15', atomicCommitsCount: 12, prsStackedCount: 4, avgLocPerCommit: 68, bulkCommitsPrevented: 4 },
  { date: '2026-10-16', label: 'Oct 16', atomicCommitsCount: 9, prsStackedCount: 3, avgLocPerCommit: 79, bulkCommitsPrevented: 2 },
  { date: '2026-10-17', label: 'Oct 17', atomicCommitsCount: 7, prsStackedCount: 2, avgLocPerCommit: 73, bulkCommitsPrevented: 2 },
  { date: '2026-10-18', label: 'Oct 18', atomicCommitsCount: 5, prsStackedCount: 2, avgLocPerCommit: 66, bulkCommitsPrevented: 1 },
  { date: '2026-10-19', label: 'Oct 19', atomicCommitsCount: 10, prsStackedCount: 4, avgLocPerCommit: 72, bulkCommitsPrevented: 3 },
  { date: '2026-10-20', label: 'Oct 20', atomicCommitsCount: 13, prsStackedCount: 5, avgLocPerCommit: 67, bulkCommitsPrevented: 4 },
  { date: '2026-10-21', label: 'Oct 21', atomicCommitsCount: 11, prsStackedCount: 4, avgLocPerCommit: 74, bulkCommitsPrevented: 3 },
  { date: '2026-10-22', label: 'Oct 22', atomicCommitsCount: 14, prsStackedCount: 5, avgLocPerCommit: 65, bulkCommitsPrevented: 4 },
  { date: '2026-10-23', label: 'Oct 23', atomicCommitsCount: 9, prsStackedCount: 3, avgLocPerCommit: 78, bulkCommitsPrevented: 2 },
  { date: '2026-10-24', label: 'Oct 24', atomicCommitsCount: 6, prsStackedCount: 2, avgLocPerCommit: 70, bulkCommitsPrevented: 2 },
  { date: '2026-10-25', label: 'Oct 25', atomicCommitsCount: 8, prsStackedCount: 3, avgLocPerCommit: 69, bulkCommitsPrevented: 2 },
  { date: '2026-10-26', label: 'Oct 26', atomicCommitsCount: 12, prsStackedCount: 4, avgLocPerCommit: 73, bulkCommitsPrevented: 3 },
  { date: '2026-10-27', label: 'Oct 27', atomicCommitsCount: 15, prsStackedCount: 5, avgLocPerCommit: 64, bulkCommitsPrevented: 5 },
  { date: '2026-10-28', label: 'Oct 28', atomicCommitsCount: 11, prsStackedCount: 4, avgLocPerCommit: 71, bulkCommitsPrevented: 3 },
  { date: '2026-10-29', label: 'Oct 29', atomicCommitsCount: 13, prsStackedCount: 5, avgLocPerCommit: 68, bulkCommitsPrevented: 4 },
  { date: '2026-10-30', label: 'Oct 30', atomicCommitsCount: 10, prsStackedCount: 3, avgLocPerCommit: 76, bulkCommitsPrevented: 3 },
  { date: '2026-10-31', label: 'Oct 31', atomicCommitsCount: 6, prsStackedCount: 2, avgLocPerCommit: 78, bulkCommitsPrevented: 2 },
  { date: '2026-11-01', label: 'Nov 1', atomicCommitsCount: 5, prsStackedCount: 2, avgLocPerCommit: 64, bulkCommitsPrevented: 1 },
  { date: '2026-11-02', label: 'Nov 2', atomicCommitsCount: 11, prsStackedCount: 4, avgLocPerCommit: 75, bulkCommitsPrevented: 3 },
  { date: '2026-11-03', label: 'Nov 3', atomicCommitsCount: 14, prsStackedCount: 5, avgLocPerCommit: 72, bulkCommitsPrevented: 4 },
  { date: '2026-11-04', label: 'Nov 4', atomicCommitsCount: 10, prsStackedCount: 4, avgLocPerCommit: 77, bulkCommitsPrevented: 3 },
  { date: '2026-11-05', label: 'Nov 5', atomicCommitsCount: 12, prsStackedCount: 4, avgLocPerCommit: 71, bulkCommitsPrevented: 4 },
  { date: '2026-11-06', label: 'Today', atomicCommitsCount: 9, prsStackedCount: 4, avgLocPerCommit: 69, bulkCommitsPrevented: 3 },
];

export function ensureThirtyDayCadence(existing?: DailyCadenceDay[]): DailyCadenceDay[] {
  if (!Array.isArray(existing) || existing.length < 30) {
    const byDate = new Map((existing || []).map((d) => [d.date, d]));
    return INITIAL_DAILY_CADENCE.map((seed) => {
      const match = byDate.get(seed.date);
      if (!match) return seed;
      return {
        ...seed,
        atomicCommitsCount: Math.max(seed.atomicCommitsCount, match.atomicCommitsCount),
        prsStackedCount: Math.max(seed.prsStackedCount, match.prsStackedCount),
      };
    });
  }
  return existing;
}

export function ensurePushedStackItems(existing?: AtomicCommitUnit[]): AtomicCommitUnit[] {
  if (!Array.isArray(existing) || existing.length === 0) {
    return INITIAL_PUSHED_STACK;
  }
  const seedById = new Map(INITIAL_PUSHED_STACK.map((s) => [s.id, s]));
  const hydratedExisting = existing.map((item) => {
    const seedMatch = seedById.get(item.id);
    if (seedMatch && (!Array.isArray(item.hunks) || item.hunks.length === 0)) {
      return {
        ...item,
        hunks: seedMatch.hunks,
      };
    }
    return item;
  });
  const byId = new Map(hydratedExisting.map((item) => [item.id, item]));
  const mergedList = [...hydratedExisting];
  for (const seed of INITIAL_PUSHED_STACK) {
    if (!byId.has(seed.id)) {
      mergedList.push(seed);
    }
  }
  return mergedList;
}

