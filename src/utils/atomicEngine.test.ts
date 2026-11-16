import test from 'node:test';
import assert from 'node:assert/strict';
import {
  classifyFileAndHunkIntent,
  evaluateCommitCompliance,
  formatConventionalHeader,
  generateIdeExtensionBundle,
  parseRawPatchOrPromptInput,
  sliceHunksIntoAtomicCommits,
  splitAtomicCommit,
} from './atomicEngine';
import { DiffHunk, GuardrailPolicy } from '../types/git';

const DEFAULT_POLICY: GuardrailPolicy = {
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

test('classifyFileAndHunkIntent separates brainstorming docs, tests, bugfixes, and features', () => {
  const planDoc = classifyFileAndHunkIntent(
    'docs/roadmap-brainstorm.md',
    '+ ## Q4 Goals and Prompt Brainstorming',
    'Brainstorm next billing architecture'
  );
  assert.equal(planDoc.intent, 'docs');
  assert.equal(planDoc.isBrainstormOrPlan, true);

  const unitTest = classifyFileAndHunkIntent(
    'src/checkout/stripe.test.ts',
    '+ test("verifies signature")',
    'Add unit test'
  );
  assert.equal(unitTest.intent, 'test');
  assert.equal(unitTest.isBrainstormOrPlan, false);

  const bugFix = classifyFileAndHunkIntent(
    'src/auth/tokenRefresh.ts',
    '+ if (!token) return null; // guard against race condition',
    'Fix token refresh race condition bug'
  );
  assert.equal(bugFix.intent, 'fix');
  assert.equal(bugFix.scope, 'auth');
});

test('evaluateCommitCompliance flags oversized bulk commits and mixed intents', () => {
  const bulkHunks: DiffHunk[] = [
    {
      id: 'h1',
      filePath: 'src/auth/login.ts',
      moduleScope: 'auth',
      intent: 'feat',
      summary: 'add passkey login flow',
      additions: 110,
      deletions: 35,
      diffSnippet: '@@ -1,35 +1,110 @@',
    },
    {
      id: 'h2',
      filePath: 'docs/brainstorm-notes.md',
      moduleScope: 'plans',
      intent: 'docs',
      summary: 'capture antigravity prompt ideas',
      additions: 40,
      deletions: 0,
      diffSnippet: '@@ -0,0 +1,40 @@',
      isBrainstormOrPlan: true,
    },
  ];

  const result = evaluateCommitCompliance(
    {
      type: 'feat',
      scope: 'auth',
      title: 'add passkey login flow and notes',
      hunks: bulkHunks,
    },
    DEFAULT_POLICY
  );

  assert.equal(result.totalLoc, 185);
  assert.equal(result.complianceScore < 60, true);
  assert.equal(result.violations.length >= 3, true);
});

test('sliceHunksIntoAtomicCommits decomposes bulk mixed working tree into ordered atomic stack', () => {
  const mixedBulkHunks: DiffHunk[] = [
    {
      id: 'h-doc',
      filePath: 'docs/antigravity-plan.md',
      moduleScope: 'plans',
      intent: 'docs',
      summary: 'outline multi-region webhook retry goals',
      additions: 48,
      deletions: 4,
      diffSnippet: '@@ -1,4 +1,48 @@',
      isBrainstormOrPlan: true,
    },
    {
      id: 'h-feat-1',
      filePath: 'src/webhooks/dispatcher.ts',
      moduleScope: 'webhooks',
      intent: 'feat',
      summary: 'implement exponential backoff webhook dispatcher',
      additions: 72,
      deletions: 14,
      diffSnippet: '@@ -10,14 +10,72 @@',
    },
    {
      id: 'h-feat-2',
      filePath: 'src/webhooks/queue.ts',
      moduleScope: 'webhooks',
      intent: 'feat',
      summary: 'add dead-letter queue persistence handler',
      additions: 64,
      deletions: 10,
      diffSnippet: '@@ -5,10 +5,64 @@',
    },
    {
      id: 'h-refactor',
      filePath: 'src/types/webhook.ts',
      moduleScope: 'webhooks',
      intent: 'refactor',
      summary: 'extract strict webhook payload contracts',
      additions: 36,
      deletions: 8,
      diffSnippet: '@@ -1,8 +1,36 @@',
    },
    {
      id: 'h-test',
      filePath: 'src/webhooks/dispatcher.test.ts',
      moduleScope: 'webhooks',
      intent: 'test',
      summary: 'verify retry jitter and dead-letter promotion',
      additions: 58,
      deletions: 2,
      diffSnippet: '@@ -1,2 +1,58 @@',
    },
  ];

  const atomicStack = sliceHunksIntoAtomicCommits(mixedBulkHunks, DEFAULT_POLICY);

  assert.equal(atomicStack.length, 5);

  for (const unit of atomicStack) {
    assert.equal(
      unit.totalLoc <= DEFAULT_POLICY.maxLocPerCommit,
      true,
      `Commit ${unit.conventionalHeader} exceeded max LOC with ${unit.totalLoc}`
    );
    assert.equal(unit.complianceScore, 100);
    assert.equal(unit.violations.length, 0);
  }

  assert.equal(atomicStack[0].type, 'refactor');
  assert.equal(atomicStack[0].parentBranch, 'main');
  assert.equal(atomicStack[1].type, 'feat');
  assert.equal(atomicStack[1].parentBranch, atomicStack[0].branchName);

  const docsCommit = atomicStack[atomicStack.length - 1];
  assert.equal(docsCommit.type, 'docs');
  assert.equal(docsCommit.parentBranch, 'main');
});

test('splitAtomicCommit cleanly separates selected hunks into a chained child commit', () => {
  const hunks: DiffHunk[] = [
    {
      id: 'h-a',
      filePath: 'src/billing/invoice.ts',
      moduleScope: 'billing',
      intent: 'feat',
      summary: 'calculate prorated seat credits',
      additions: 40,
      deletions: 10,
      diffSnippet: '@@ -1,10 +1,40 @@',
    },
    {
      id: 'h-b',
      filePath: 'src/billing/receipt.ts',
      moduleScope: 'billing',
      intent: 'feat',
      summary: 'render itemized PDF tax breakdown',
      additions: 35,
      deletions: 5,
      diffSnippet: '@@ -1,5 +1,35 @@',
    },
  ];

  const [initial] = sliceHunksIntoAtomicCommits(hunks, DEFAULT_POLICY);
  assert.equal(initial.hunks.length, 2);

  const splitResult = splitAtomicCommit(initial, ['h-b'], DEFAULT_POLICY);
  assert.ok(splitResult);
  const [first, second] = splitResult;
  assert.equal(first.hunks.length, 1);
  assert.equal(second.hunks.length, 1);
  assert.equal(second.parentBranch, first.branchName);
  assert.equal(first.totalLoc, 50);
  assert.equal(second.totalLoc, 40);
});

test('parseRawPatchOrPromptInput and generateIdeExtensionBundle validate and output extension configs', () => {
  const emptyCheck = parseRawPatchOrPromptInput({ promptText: '   ', rawFilesInput: 'src/a.ts' });
  assert.equal(emptyCheck.valid, false);
  assert.ok(emptyCheck.error);

  const validCheck = parseRawPatchOrPromptInput({
    promptText: 'Fix session timeout bug and update roadmap plan',
    rawFilesInput:
      'src/auth/session.ts | +38 -9 | Guard against expired refresh token\ndocs/session-plan.md | +24 -0 | Document session lifecycle goals',
    sourceAgent: 'cursor',
  });
  assert.equal(validCheck.valid, true);
  assert.equal(validCheck.hunks.length, 2);
  assert.equal(validCheck.hunks[0].sourceAgent, 'cursor');
  assert.equal(
    formatConventionalHeader('fix', 'auth', 'Guard against expired refresh token'),
    'fix(auth): guard against expired refresh token'
  );

  const bundle = generateIdeExtensionBundle(DEFAULT_POLICY, {
    owner: 'olaniketema',
    repo: 'antigravity-core-platform',
    defaultBranch: 'main',
  });
  assert.ok(bundle.extensionManifestJson.includes('onStartupFinished'));
  assert.ok(bundle.extensionJs.includes('vscode.workspace.onDidSaveTextDocument'));
  assert.ok(bundle.mcpConfigJson.includes('mcpServers'));
});

test('resolvePrStatusBadgeMeta and summarizeThirtyDayCadence map PR statuses and 30-day activity metrics', async () => {
  const { resolvePrStatusBadgeMeta, summarizeThirtyDayCadence } = await import('./atomicEngine');

  const openBadge = resolvePrStatusBadgeMeta('pr_open');
  assert.equal(openBadge.label, 'Open');
  assert.equal(openBadge.statusKey, 'open');

  const mergedBadge = resolvePrStatusBadgeMeta('merged');
  assert.equal(mergedBadge.label, 'Merged');
  assert.equal(mergedBadge.statusKey, 'merged');

  const draftBadge = resolvePrStatusBadgeMeta('draft');
  assert.equal(draftBadge.label, 'Draft');
  assert.equal(draftBadge.statusKey, 'draft');

  const summary = summarizeThirtyDayCadence([
    {
      date: '2026-11-05',
      label: 'Nov 5',
      atomicCommitsCount: 10,
      prsStackedCount: 3,
      avgLocPerCommit: 80,
      bulkCommitsPrevented: 3,
    },
    {
      date: '2026-11-06',
      label: 'Today',
      atomicCommitsCount: 14,
      prsStackedCount: 5,
      avgLocPerCommit: 68,
      bulkCommitsPrevented: 4,
    },
  ]);

  assert.equal(summary.totalCommits, 24);
  assert.equal(summary.totalStackedPrs, 8);
  assert.equal(summary.totalBulkPrevented, 7);
  assert.equal(summary.peakDayLabel, 'Today');
  assert.equal(summary.peakDayCommits, 14);
});

test('centralized hotkeyManager serializes keyboard events, matches shortcuts, and exports IDE keybindings', async () => {
  const {
    DEFAULT_HOTKEY_BINDINGS,
    applyHotkeyPreset,
    formatComboKeycaps,
    formatCompactShortcut,
    generateIdeKeybindingsConfig,
    matchKeyboardEventToAction,
    serializeKeyboardEvent,
  } = await import('./hotkeyManager');

  assert.deepEqual(formatComboKeycaps('Alt+Shift+C'), ['⌥ Alt', '⇧ Shift', 'C']);
  assert.equal(formatCompactShortcut('Alt+Shift+Q'), '⌥⇧Q');

  const combo = serializeKeyboardEvent({
    key: 'Ç',
    code: 'KeyC',
    altKey: true,
    shiftKey: true,
    ctrlKey: false,
    metaKey: false,
  });
  assert.equal(combo, 'Alt+Shift+C');

  const matchedCommit = matchKeyboardEventToAction(
    {
      key: 'c',
      code: 'KeyC',
      altKey: true,
      shiftKey: true,
      ctrlKey: false,
      metaKey: false,
    },
    DEFAULT_HOTKEY_BINDINGS
  );
  assert.equal(matchedCommit, 'trigger_quick_atomic_commit');

  const ctrlPreset = applyHotkeyPreset('ctrl_shift');
  assert.equal(ctrlPreset[0].combo, 'Ctrl+Shift+C');

  const cursorExport = generateIdeKeybindingsConfig(DEFAULT_HOTKEY_BINDINGS, 'cursor');
  assert.ok(cursorExport.includes('atomikgit.quickAtomicCommit'));
  assert.ok(cursorExport.includes('"hostIde": "cursor"'));
});

test('parseUnifiedDiffLines and resolveCommitRealHunks parse exact line numbers and replace empty or placeholder hunks', async () => {
  const {
    isPlaceholderDiffSnippet,
    parseUnifiedDiffLines,
    resolveCommitRealHunks,
  } = await import('./atomicEngine');
  const { INITIAL_PUSHED_STACK } = await import('./seedData');

  // Every seeded pushed commit must have non-empty, non-placeholder diff hunks
  for (const unit of INITIAL_PUSHED_STACK) {
    assert.ok(unit.hunks.length >= 1, `Expected hunks for ${unit.id}`);
    for (const h of unit.hunks) {
      assert.equal(isPlaceholderDiffSnippet(h.diffSnippet), false);
    }
  }

  // Test line number calculation starting from @@ -18,12 +18,31 @@
  const parsed = parseUnifiedDiffLines(
    `@@ -18,4 +18,5 @@ import { createHmac } from 'node:crypto';\n const tolerance = 300;\n-return false;\n+const verified = true;\n+return verified;`
  );
  assert.equal(parsed[0].type, 'hunk_header');
  assert.equal(parsed[1].type, 'context');
  assert.equal(parsed[1].oldLineNumber, 18);
  assert.equal(parsed[1].newLineNumber, 18);
  assert.equal(parsed[2].type, 'del');
  assert.equal(parsed[2].oldLineNumber, 19);
  assert.equal(parsed[2].newLineNumber, null);
  assert.equal(parsed[3].type, 'add');
  assert.equal(parsed[3].oldLineNumber, null);
  assert.equal(parsed[3].newLineNumber, 19);
  assert.equal(parsed[4].type, 'add');
  assert.equal(parsed[4].newLineNumber, 20);

  // Test fallback synthesis when a cached commit has empty hunks
  const legacyUnit = {
    ...INITIAL_PUSHED_STACK[0],
    hunks: [],
  };
  const resolved = resolveCommitRealHunks(legacyUnit);
  assert.equal(resolved.length, 2);
  assert.equal(resolved[0].filePath, 'src/db/schema.ts');
  assert.equal(isPlaceholderDiffSnippet(resolved[0].diffSnippet), false);

  // Test detectSyntaxLanguage and extractNavigableHunks
  const { detectSyntaxLanguage, extractNavigableHunks } = await import(
    './atomicEngine'
  );
  const { INITIAL_WORKING_TREE_HUNKS, INITIAL_POLICY } = await import(
    './seedData'
  );

  assert.equal(detectSyntaxLanguage('src/components/ReceiptSummary.tsx'), 'tsx');
  assert.equal(detectSyntaxLanguage('src/db/migrations/004_ledger_idx.sql'), 'sql');
  assert.equal(detectSyntaxLanguage('docs/antigravity-brainstorm-ledger.md'), 'markdown');
  assert.equal(detectSyntaxLanguage('src/payment/webhookHandler.ts'), 'typescript');

  const stagedSlices = sliceHunksIntoAtomicCommits(
    INITIAL_WORKING_TREE_HUNKS,
    INITIAL_POLICY
  );
  for (const unit of [...stagedSlices, ...INITIAL_PUSHED_STACK]) {
    const navHunks = extractNavigableHunks(resolveCommitRealHunks(unit));
    assert.ok(
      navHunks.length >= 2,
      `Expected at least 2 navigable hunks in ${unit.conventionalHeader}, got ${navHunks.length}`
    );
    assert.equal(navHunks[0].hunkIndex, 1);
    assert.equal(navHunks[1].hunkIndex, 2);
  }
});




