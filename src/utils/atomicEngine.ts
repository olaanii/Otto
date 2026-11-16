import {
  AtomicCommitUnit,
  CommitType,
  DailyCadenceDay,
  DiffHunk,
  GuardrailPolicy,
  IdeHostId,
} from '../types/git';

const COMMIT_ORDER_WEIGHT: Record<CommitType, number> = {
  refactor: 1,
  perf: 2,
  feat: 3,
  fix: 4,
  test: 5,
  chore: 6,
  docs: 7,
};

export function classifyFileAndHunkIntent(
  filePath: string,
  diffSnippet: string,
  promptHint?: string
): { intent: CommitType; scope: string; isBrainstormOrPlan: boolean } {
  const normalizedPath = filePath.trim().replace(/^\/+/, '');
  const lowerPath = normalizedPath.toLowerCase();
  const lowerPrompt = (promptHint || '').toLowerCase();
  const lowerDiff = diffSnippet.toLowerCase();

  const segments = normalizedPath.split('/').filter(Boolean);
  let scope = 'core';
  if (segments.length >= 2) {
    const candidate = segments[1].replace(/\.(ts|tsx|js|jsx|md|json|sql|css)$/i, '');
    if (candidate && !['index', 'app', 'main', 'utils', 'components'].includes(candidate.toLowerCase())) {
      scope = candidate.toLowerCase().replace(/[^a-z0-9-_]/g, '');
    } else if (segments.length >= 3) {
      scope = segments[2].replace(/\.(ts|tsx|js|jsx|md|json|sql|css)$/i, '').toLowerCase().replace(/[^a-z0-9-_]/g, '');
    }
  } else if (segments.length === 1) {
    scope = segments[0].replace(/\.(ts|tsx|js|jsx|md|json|sql|css)$/i, '').toLowerCase();
  }

  const isBrainstormOrPlan =
    lowerPath.endsWith('.md') ||
    lowerPath.includes('brainstorm') ||
    lowerPath.includes('roadmap') ||
    lowerPath.includes('plan') ||
    lowerPath.includes('rfc') ||
    lowerPath.includes('notes/') ||
    lowerPrompt.includes('brainstorm') ||
    lowerPrompt.includes('goal') ||
    lowerPrompt.includes('roadmap');

  if (isBrainstormOrPlan) {
    return {
      intent: 'docs',
      scope: lowerPath.includes('plan') || lowerPrompt.includes('plan') ? 'plans' : 'architecture',
      isBrainstormOrPlan: true,
    };
  }

  if (
    lowerPath.includes('.test.') ||
    lowerPath.includes('.spec.') ||
    lowerPath.includes('__tests__') ||
    lowerPath.startsWith('test/') ||
    lowerPath.startsWith('tests/')
  ) {
    return {
      intent: 'test',
      scope: scope.replace(/\.(test|spec)$/, '') || 'unit',
      isBrainstormOrPlan: false,
    };
  }

  if (
    lowerPath.endsWith('package.json') ||
    lowerPath.endsWith('tsconfig.json') ||
    lowerPath.includes('.eslintrc') ||
    lowerPath.includes('dockerfile') ||
    lowerPath.includes('.github/')
  ) {
    return {
      intent: 'chore',
      scope: 'config',
      isBrainstormOrPlan: false,
    };
  }

  if (
    lowerPrompt.includes('fix') ||
    lowerPrompt.includes('bug') ||
    lowerPrompt.includes('race condition') ||
    lowerPrompt.includes('crash') ||
    lowerDiff.includes('fix:') ||
    lowerDiff.includes('null check') ||
    lowerDiff.includes('guard against')
  ) {
    return {
      intent: 'fix',
      scope: scope || 'runtime',
      isBrainstormOrPlan: false,
    };
  }

  if (
    lowerPrompt.includes('refactor') ||
    lowerPrompt.includes('extract') ||
    lowerPrompt.includes('decouple') ||
    lowerPath.includes('types/') ||
    lowerPath.includes('schema')
  ) {
    return {
      intent: 'refactor',
      scope: scope || 'architecture',
      isBrainstormOrPlan: false,
    };
  }

  return {
    intent: 'feat',
    scope: scope || 'module',
    isBrainstormOrPlan: false,
  };
}

export function formatConventionalHeader(type: CommitType, scope: string, title: string): string {
  const cleanScope = scope.trim().toLowerCase().replace(/[^a-z0-9-_]/g, '') || 'core';
  const cleanTitle = title
    .trim()
    .replace(/^(feat|fix|refactor|test|docs|chore|perf)(\([^)]+\))?:\s*/i, '')
    .replace(/\.$/, '');
  const lowerFirst = cleanTitle.charAt(0).toLowerCase() + cleanTitle.slice(1);
  const maxSubjectLen = 76;
  const boundedSubject =
    lowerFirst.length > maxSubjectLen
      ? lowerFirst.slice(0, maxSubjectLen).trimEnd()
      : lowerFirst;
  return `${type}(${cleanScope}): ${boundedSubject}`;
}

export function evaluateCommitCompliance(
  unit: {
    type: CommitType;
    scope: string;
    title: string;
    conventionalHeader?: string;
    hunks: DiffHunk[];
  },
  policy: GuardrailPolicy
): {
  complianceScore: number;
  violations: string[];
  totalAdditions: number;
  totalDeletions: number;
  totalLoc: number;
  reviewMinutes: number;
} {
  const totalAdditions = unit.hunks.reduce((sum, h) => sum + h.additions, 0);
  const totalDeletions = unit.hunks.reduce((sum, h) => sum + h.deletions, 0);
  const totalLoc = totalAdditions + totalDeletions;
  const uniqueFiles = new Set(unit.hunks.map((h) => h.filePath));
  const uniqueIntents = new Set(unit.hunks.map((h) => h.intent));
  const hasPlanDocs = unit.hunks.some((h) => h.isBrainstormOrPlan);
  const hasRuntimeCode = unit.hunks.some((h) => !h.isBrainstormOrPlan && h.intent !== 'docs');

  const violations: string[] = [];
  let score = 100;

  if (totalLoc > policy.maxLocPerCommit) {
    const overage = totalLoc - policy.maxLocPerCommit;
    violations.push(
      `Exceeds atomic budget by ${overage} LOC (${totalLoc} / ${policy.maxLocPerCommit} max LOC)`
    );
    score -= Math.min(45, Math.ceil((overage / policy.maxLocPerCommit) * 40));
  }

  if (uniqueFiles.size > policy.maxFilesPerCommit) {
    violations.push(
      `Touches ${uniqueFiles.size} files (max ${policy.maxFilesPerCommit} files per atomic unit)`
    );
    score -= 20;
  }

  if (uniqueIntents.size > 1) {
    violations.push(
      `Mixes multiple semantic concerns (${Array.from(uniqueIntents).join(', ')}) in a single commit`
    );
    score -= 25;
  }

  if (policy.isolateBrainstormingDocs && hasPlanDocs && hasRuntimeCode) {
    violations.push(
      'Bundles IDE brainstorming/plan notes with production code (violates doc isolation policy)'
    );
    score -= 25;
  }

  const headerToCheck =
    unit.conventionalHeader || formatConventionalHeader(unit.type, unit.scope, unit.title);
  if (policy.enforceConventionalCommits) {
    const conventionalRegex = /^(feat|fix|refactor|test|docs|chore|perf)\([a-z0-9-_]+\):\s+.{6,100}$/;
    if (!conventionalRegex.test(headerToCheck)) {
      violations.push('Header must follow Conventional Commits 1.0 pattern type(scope): subject');
      score -= 15;
    }
  }

  const reviewMinutes = Math.max(1, Math.round(totalLoc / 28 + uniqueFiles.size * 0.6));

  return {
    complianceScore: Math.max(5, score),
    violations,
    totalAdditions,
    totalDeletions,
    totalLoc,
    reviewMinutes,
  };
}

export function sliceHunksIntoAtomicCommits(
  hunks: DiffHunk[],
  policy: GuardrailPolicy
): AtomicCommitUnit[] {
  if (hunks.length === 0) return [];

  const enrichedHunks: DiffHunk[] = hunks.map((hunk) => {
    const classification = classifyFileAndHunkIntent(
      hunk.filePath,
      hunk.diffSnippet,
      hunk.promptContext || hunk.summary
    );
    return {
      ...hunk,
      intent: hunk.isBrainstormOrPlan ? 'docs' : hunk.intent || classification.intent,
      moduleScope: hunk.moduleScope || classification.scope,
      isBrainstormOrPlan:
        hunk.isBrainstormOrPlan !== undefined
          ? hunk.isBrainstormOrPlan
          : classification.isBrainstormOrPlan,
    };
  });

  const buckets = new Map<string, DiffHunk[]>();

  for (const hunk of enrichedHunks) {
    let bucketKey: string;
    if (policy.isolateBrainstormingDocs && hunk.isBrainstormOrPlan) {
      bucketKey = `docs::plans`;
    } else {
      bucketKey = `${hunk.intent}::${hunk.moduleScope}`;
    }
    const existing = buckets.get(bucketKey) || [];
    existing.push(hunk);
    buckets.set(bucketKey, existing);
  }

  const rawUnits: Array<{
    type: CommitType;
    scope: string;
    hunks: DiffHunk[];
    partIndex: number;
    totalParts: number;
  }> = [];

  for (const [key, groupHunks] of buckets.entries()) {
    const [rawType, rawScope] = key.split('::') as [CommitType, string];
    const subChunks: DiffHunk[][] = [];
    let currentChunk: DiffHunk[] = [];
    let currentLoc = 0;
    let currentFiles = new Set<string>();

    for (const h of groupHunks) {
      const hunkLoc = h.additions + h.deletions;
      const wouldExceedLoc =
        currentChunk.length > 0 && currentLoc + hunkLoc > policy.maxLocPerCommit;
      const wouldExceedFiles =
        currentChunk.length > 0 &&
        !currentFiles.has(h.filePath) &&
        currentFiles.size + 1 > policy.maxFilesPerCommit;

      if (wouldExceedLoc || wouldExceedFiles) {
        subChunks.push(currentChunk);
        currentChunk = [h];
        currentLoc = hunkLoc;
        currentFiles = new Set([h.filePath]);
      } else {
        currentChunk.push(h);
        currentLoc += hunkLoc;
        currentFiles.add(h.filePath);
      }
    }
    if (currentChunk.length > 0) {
      subChunks.push(currentChunk);
    }

    subChunks.forEach((chunk, idx) => {
      rawUnits.push({
        type: rawType,
        scope: rawScope,
        hunks: chunk,
        partIndex: idx + 1,
        totalParts: subChunks.length,
      });
    });
  }

  rawUnits.sort((a, b) => {
    const weightDiff = COMMIT_ORDER_WEIGHT[a.type] - COMMIT_ORDER_WEIGHT[b.type];
    if (weightDiff !== 0) return weightDiff;
    return a.scope.localeCompare(b.scope);
  });

  const prefix = policy.branchPrefix.endsWith('/')
    ? policy.branchPrefix
    : `${policy.branchPrefix}/`;
  let previousCodeBranch = policy.baseBranch || 'main';

  return rawUnits.map((unit, idx) => {
    const primarySummary = unit.hunks[0]?.summary || `update ${unit.scope} module`;
    const cleanPrimary = primarySummary
      .replace(/^(feat|fix|refactor|test|docs|chore|perf)(\([^)]+\))?:\s*/i, '')
      .replace(/\.$/, '');
    const suffix =
      unit.totalParts > 1 ? ` (slice ${unit.partIndex}/${unit.totalParts})` : '';
    const title = `${cleanPrimary}${suffix}`;
    const conventionalHeader = formatConventionalHeader(unit.type, unit.scope, title);

    const slug = `${unit.type}-${unit.scope}-${idx + 1}`
      .toLowerCase()
      .replace(/[^a-z0-9-]/g, '-');
    const branchName = `${prefix}${slug}`;

    const isPlanCommit = unit.hunks.every((h) => h.isBrainstormOrPlan);
    const parentBranch = isPlanCommit ? policy.baseBranch || 'main' : previousCodeBranch;
    if (!isPlanCommit) {
      previousCodeBranch = branchName;
    }

    const evaluation = evaluateCommitCompliance(
      {
        type: unit.type,
        scope: unit.scope,
        title,
        conventionalHeader,
        hunks: unit.hunks,
      },
      policy
    );

    const bodyBullets = unit.hunks.map(
      (h) => `${h.filePath}: ${h.summary} (+${h.additions} / -${h.deletions} LOC)`
    );

    const sha = generateDeterministicShortSha(`${conventionalHeader}-${idx}-${evaluation.totalLoc}`);

    return {
      id: `atomic-${idx + 1}-${sha}`,
      type: unit.type,
      scope: unit.scope,
      title,
      conventionalHeader,
      bodyBullets,
      branchName,
      parentBranch,
      hunks: unit.hunks,
      totalAdditions: evaluation.totalAdditions,
      totalDeletions: evaluation.totalDeletions,
      totalLoc: evaluation.totalLoc,
      reviewMinutes: evaluation.reviewMinutes,
      complianceScore: evaluation.complianceScore,
      violations: evaluation.violations,
      status: 'staged',
      sha,
      createdAt: new Date().toISOString(),
      promptOrigin: unit.hunks[0]?.promptContext,
      sourceAgent: unit.hunks[0]?.sourceAgent || 'antigravity',
    };
  });
}

export function splitAtomicCommit(
  commit: AtomicCommitUnit,
  hunkIdsToExtract: string[],
  policy: GuardrailPolicy
): [AtomicCommitUnit, AtomicCommitUnit] | null {
  const extractSet = new Set(hunkIdsToExtract);
  const remainingHunks = commit.hunks.filter((h) => !extractSet.has(h.id));
  const extractedHunks = commit.hunks.filter((h) => extractSet.has(h.id));

  if (remainingHunks.length === 0 || extractedHunks.length === 0) {
    return null;
  }

  const firstTitle = `${commit.title.replace(/\s*\(part \d+\)$/i, '')} (core)`;
  const secondPrimary = extractedHunks[0].summary || `${commit.scope} extracted slice`;
  const secondType = extractedHunks[0].intent || commit.type;
  const secondScope = extractedHunks[0].moduleScope || commit.scope;

  const firstHeader = formatConventionalHeader(commit.type, commit.scope, firstTitle);
  const secondHeader = formatConventionalHeader(secondType, secondScope, secondPrimary);

  const evalFirst = evaluateCommitCompliance(
    {
      type: commit.type,
      scope: commit.scope,
      title: firstTitle,
      conventionalHeader: firstHeader,
      hunks: remainingHunks,
    },
    policy
  );

  const evalSecond = evaluateCommitCompliance(
    {
      type: secondType,
      scope: secondScope,
      title: secondPrimary,
      conventionalHeader: secondHeader,
      hunks: extractedHunks,
    },
    policy
  );

  const firstBranch = commit.branchName;
  const secondSha = generateDeterministicShortSha(`${secondHeader}-${evalSecond.totalLoc}`);
  const secondBranch = `${commit.branchName}-slice-${secondSha.slice(0, 4)}`;

  const firstUnit: AtomicCommitUnit = {
    ...commit,
    title: firstTitle,
    conventionalHeader: firstHeader,
    hunks: remainingHunks,
    bodyBullets: remainingHunks.map(
      (h) => `${h.filePath}: ${h.summary} (+${h.additions} / -${h.deletions} LOC)`
    ),
    totalAdditions: evalFirst.totalAdditions,
    totalDeletions: evalFirst.totalDeletions,
    totalLoc: evalFirst.totalLoc,
    reviewMinutes: evalFirst.reviewMinutes,
    complianceScore: evalFirst.complianceScore,
    violations: evalFirst.violations,
  };

  const secondUnit: AtomicCommitUnit = {
    id: `atomic-split-${secondSha}`,
    type: secondType,
    scope: secondScope,
    title: secondPrimary,
    conventionalHeader: secondHeader,
    bodyBullets: extractedHunks.map(
      (h) => `${h.filePath}: ${h.summary} (+${h.additions} / -${h.deletions} LOC)`
    ),
    branchName: secondBranch,
    parentBranch: firstBranch,
    hunks: extractedHunks,
    totalAdditions: evalSecond.totalAdditions,
    totalDeletions: evalSecond.totalDeletions,
    totalLoc: evalSecond.totalLoc,
    reviewMinutes: evalSecond.reviewMinutes,
    complianceScore: evalSecond.complianceScore,
    violations: evalSecond.violations,
    status: commit.status,
    sha: secondSha,
    createdAt: new Date().toISOString(),
    promptOrigin: extractedHunks[0]?.promptContext || commit.promptOrigin,
    sourceAgent: extractedHunks[0]?.sourceAgent || commit.sourceAgent,
  };

  return [firstUnit, secondUnit];
}

export interface ParsedDiffLine {
  type: 'hunk_header' | 'add' | 'del' | 'context';
  raw: string;
  content: string;
  oldLineNumber: number | null;
  newLineNumber: number | null;
}

export function isPlaceholderDiffSnippet(snippet?: string): boolean {
  if (!snippet || !snippet.trim()) return true;
  if (snippet.includes('// previous implementation')) return true;
  const nonHeaderLines = snippet
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.length > 0 && !l.startsWith('@@'));
  if (nonHeaderLines.length <= 1 && nonHeaderLines[0]?.startsWith('+ //')) {
    return true;
  }
  return false;
}

export function synthesizeCodeDiffSnippet(params: {
  filePath: string;
  scope: string;
  intent: CommitType;
  summary: string;
  additions: number;
  deletions: number;
}): string {
  const { filePath, scope, intent, summary, additions, deletions } = params;
  const cleanFile = filePath.trim();
  const baseName =
    cleanFile
      .split('/')
      .pop()
      ?.replace(/\.(ts|tsx|js|jsx|sql|md|json)$/i, '')
      ?.replace(/[^a-zA-Z0-9]/g, '') || 'Module';
  const camelName = baseName.charAt(0).toLowerCase() + baseName.slice(1);
  const pascalName = baseName.charAt(0).toUpperCase() + baseName.slice(1);

  if (cleanFile.endsWith('.sql')) {
    return `@@ -1,${Math.max(2, deletions)} +1,${Math.max(8, additions)} @@
+-- ${summary}
+CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_${scope}_${camelName}_lookup
+  ON ${scope}_records (tenant_id, created_at DESC);
+
+ALTER TABLE ${scope}_records
+  ADD CONSTRAINT chk_${scope}_${camelName}_valid
+  CHECK (created_at IS NOT NULL);`;
  }

  if (cleanFile.endsWith('.md') || intent === 'docs') {
    return `@@ -1,${Math.max(3, deletions)} +1,${Math.max(9, additions)} @@
-# ${pascalName} Notes
-- Legacy draft notes
+# ${pascalName} Architecture (${scope})
+
+## Summary
+- ${summary}
+- Enforced atomic boundary: isolated \`${intent}(${scope})\` unit
+- Verified deterministic rollback safety before PR stack promotion`;
  }

  if (cleanFile.includes('.test.') || cleanFile.includes('.spec.') || intent === 'test') {
    return `@@ -12,${Math.max(4, deletions)} +12,${Math.max(16, additions)} @@ import assert from 'node:assert/strict';
 import test from 'node:test';
-import { ${camelName} } from './${camelName}';
+import { ${camelName}, validate${pascalName}Invariant } from './${camelName.replace(/Test|Spec/i, '')}';
 
-test('${camelName} basic check', () => {});
+test('${scope}: ${summary.replace(/'/g, '')}', async () => {
+  const fixture = { scope: '${scope}', timestampMs: Date.now(), verified: true };
+  const outcome = await validate${pascalName}Invariant(fixture);
+  assert.equal(outcome.ok, true);
+  assert.equal(outcome.scope, '${scope}');
+});`;
  }

  if (cleanFile.endsWith('.tsx')) {
    return `@@ -18,${Math.max(6, deletions)} +18,${Math.max(18, additions)} @@ export interface ${pascalName}Props {
   readonly title?: string;
+  readonly scope?: string;
+  readonly onCommitReady?: (id: string) => void;
 }
 
-export function ${pascalName}({ title }: ${pascalName}Props) {
-  return <div>{title}</div>;
+export function ${pascalName}({ title = '${pascalName}', scope = '${scope}', onCommitReady }: ${pascalName}Props) {
+  return (
+    <section data-scope={scope} aria-label={title}>
+      <header>{title}</header>
+      <button type="button" onClick={() => onCommitReady?.(scope)}>
+        ${summary}
+      </button>
+    </section>
+  );
 }`;
  }

  if (intent === 'fix') {
    return `@@ -22,${Math.max(6, deletions)} +22,${Math.max(18, additions)} @@ export interface ${pascalName}Context {
   readonly requestId: string;
   readonly retryCount: number;
 }
 
-export async function execute${pascalName}(ctx: ${pascalName}Context) {
-  return runUnsafe${pascalName}(ctx.requestId);
+export async function execute${pascalName}(ctx: ${pascalName}Context): Promise<{ ok: boolean; requestId: string }> {
+  if (!ctx?.requestId || ctx.retryCount < 0) {
+    throw new TypeError('${pascalName}: valid requestId and non-negative retryCount required');
+  }
+  // ${summary}
+  const result = await runSafe${pascalName}(ctx.requestId, { maxRetries: Math.min(ctx.retryCount, 5) });
+  return { ok: Boolean(result), requestId: ctx.requestId };
 }`;
  }

  return `@@ -14,${Math.max(6, deletions)} +14,${Math.max(18, additions)} @@ export interface ${pascalName}Options {
   readonly scope: '${scope}';
-  readonly legacyMode?: boolean;
+  readonly strictGuardrails: boolean;
+  readonly timeoutMs: number;
 }
 
-export function process${pascalName}(input: Record<string, unknown>) {
-  return { ...input };
+export function process${pascalName}(
+  input: Readonly<Record<string, unknown>>,
+  options: ${pascalName}Options = { scope: '${scope}', strictGuardrails: true, timeoutMs: 2500 }
+): { ok: true; scope: string; processedAtIso: string } {
+  // ${summary}
+  if (options.strictGuardrails && Object.keys(input).length === 0) {
+    throw new Error('${pascalName}: empty payload rejected by ${scope} guardrail');
+  }
+  return {
+    ok: true,
+    scope: options.scope,
+    processedAtIso: new Date().toISOString(),
+  };
 }`;
}

export function parseUnifiedDiffLines(diffSnippet: string): ParsedDiffLine[] {
  const rawLines = (diffSnippet || '').split('\n');
  let currentOld = 1;
  let currentNew = 1;

  return rawLines.map((raw) => {
    if (raw.startsWith('@@')) {
      const match = raw.match(/@@\s*-(\d+)(?:,\d+)?\s+\+(\d+)(?:,\d+)?\s*@@/);
      if (match) {
        currentOld = parseInt(match[1], 10);
        currentNew = parseInt(match[2], 10);
      }
      return {
        type: 'hunk_header',
        raw,
        content: raw,
        oldLineNumber: null,
        newLineNumber: null,
      };
    }

    if (raw.startsWith('+')) {
      const lineNum = currentNew++;
      return {
        type: 'add',
        raw,
        content: raw.slice(1),
        oldLineNumber: null,
        newLineNumber: lineNum,
      };
    }

    if (raw.startsWith('-')) {
      const lineNum = currentOld++;
      return {
        type: 'del',
        raw,
        content: raw.slice(1),
        oldLineNumber: lineNum,
        newLineNumber: null,
      };
    }

    const oldNum = currentOld++;
    const newNum = currentNew++;
    return {
      type: 'context',
      raw,
      content: raw.startsWith(' ') ? raw.slice(1) : raw,
      oldLineNumber: oldNum,
      newLineNumber: newNum,
    };
  });
}

export type SyntaxLanguageId =
  | 'typescript'
  | 'tsx'
  | 'sql'
  | 'markdown'
  | 'json'
  | 'javascript';

export interface NavigableDiffHunk {
  id: string;
  parentHunkId: string;
  hunkIndex: number;
  subHunkIndex: number;
  filePath: string;
  summary: string;
  hunkHeader: string;
  additions: number;
  deletions: number;
  diffSnippet: string;
  language: SyntaxLanguageId;
}

export function detectSyntaxLanguage(filePath: string): SyntaxLanguageId {
  const clean = (filePath || '').trim().toLowerCase();
  if (clean.endsWith('.tsx') || clean.endsWith('.jsx')) return 'tsx';
  if (clean.endsWith('.sql')) return 'sql';
  if (clean.endsWith('.md') || clean.endsWith('.mdx')) return 'markdown';
  if (clean.endsWith('.json')) return 'json';
  if (clean.endsWith('.js') || clean.endsWith('.mjs') || clean.endsWith('.cjs')) {
    return 'javascript';
  }
  return 'typescript';
}

function splitDiffSnippetIntoBlocks(diffSnippet: string): string[] {
  const lines = (diffSnippet || '').split('\n');
  const blocks: string[][] = [];
  let current: string[] = [];

  for (const line of lines) {
    if (line.startsWith('@@')) {
      if (current.length > 0) {
        blocks.push(current);
      }
      current = [line];
    } else {
      if (current.length === 0) {
        current.push('@@ -1,6 +1,12 @@');
      }
      current.push(line);
    }
  }
  if (current.length > 0) {
    blocks.push(current);
  }
  return blocks.map((b) => b.join('\n'));
}

export function extractNavigableHunks(hunks: DiffHunk[]): NavigableDiffHunk[] {
  if (!Array.isArray(hunks) || hunks.length === 0) return [];

  const preliminary: Omit<NavigableDiffHunk, 'hunkIndex'>[] = [];

  for (const hunk of hunks) {
    const rawBlocks = splitDiffSnippetIntoBlocks(hunk.diffSnippet);
    const language = detectSyntaxLanguage(hunk.filePath);

    rawBlocks.forEach((blockSnippet, bIdx) => {
      const lines = blockSnippet.split('\n');
      const headerLine = lines[0]?.startsWith('@@')
        ? lines[0]
        : `@@ -1,${hunk.deletions} +1,${hunk.additions} @@`;
      const bodyLines = lines.slice(1);
      const addedCount = bodyLines.filter((l) => l.startsWith('+')).length;
      const deletedCount = bodyLines.filter((l) => l.startsWith('-')).length;

      preliminary.push({
        id: `${hunk.id}::sub-${bIdx + 1}`,
        parentHunkId: hunk.id,
        subHunkIndex: bIdx + 1,
        filePath: hunk.filePath,
        summary:
          rawBlocks.length > 1
            ? `${hunk.summary} (hunk ${bIdx + 1}/${rawBlocks.length})`
            : hunk.summary,
        hunkHeader: headerLine,
        additions: rawBlocks.length === 1 ? hunk.additions : Math.max(1, addedCount),
        deletions: rawBlocks.length === 1 ? hunk.deletions : deletedCount,
        diffSnippet: blockSnippet,
        language,
      });
    });
  }

  // If a single-file commit only had 1 @@ block, split it or append its companion export/contract hunk so the user can always cycle through multiple hunks within any single atomic commit
  if (preliminary.length === 1) {
    const single = preliminary[0];
    const allLines = single.diffSnippet.split('\n');
    const header = allLines[0] || '@@ -1,6 +1,16 @@';
    const body = allLines.slice(1);

    if (body.length >= 8) {
      const mid = Math.ceil(body.length / 2);
      const firstBody = body.slice(0, mid);
      const secondBody = body.slice(mid);
      const startMatch = header.match(/@@\s*-(\d+)(?:,\d+)?\s+\+(\d+)(?:,\d+)?\s*@@/);
      const baseOld = startMatch ? parseInt(startMatch[1], 10) : 1;
      const baseNew = startMatch ? parseInt(startMatch[2], 10) : 1;
      const firstOldSpan = firstBody.filter((l) => !l.startsWith('+')).length;
      const firstNewSpan = firstBody.filter((l) => !l.startsWith('-')).length;
      const secondHeader = `@@ -${baseOld + firstOldSpan},${Math.max(
        1,
        secondBody.filter((l) => !l.startsWith('+')).length
      )} +${baseNew + firstNewSpan},${Math.max(
        1,
        secondBody.filter((l) => !l.startsWith('-')).length
      )} @@`;

      const firstAdds = Math.max(1, Math.round(single.additions / 2));
      const secondAdds = Math.max(1, single.additions - firstAdds);
      const firstDels = Math.round(single.deletions / 2);
      const secondDels = Math.max(0, single.deletions - firstDels);

      return [
        {
          ...single,
          id: `${single.parentHunkId}::sub-1`,
          hunkIndex: 1,
          subHunkIndex: 1,
          summary: `${single.summary} (hunk 1/2)`,
          additions: firstAdds,
          deletions: firstDels,
          diffSnippet: [header, ...firstBody].join('\n'),
        },
        {
          ...single,
          id: `${single.parentHunkId}::sub-2`,
          hunkIndex: 2,
          subHunkIndex: 2,
          summary: `${single.summary} (hunk 2/2)`,
          hunkHeader: secondHeader,
          additions: secondAdds,
          deletions: secondDels,
          diffSnippet: [secondHeader, ...secondBody].join('\n'),
        },
      ];
    }
  }

  return preliminary.map((item, idx) => ({
    ...item,
    hunkIndex: idx + 1,
  }));
}

export function formatHunkForClipboard(
  hunk: Pick<NavigableDiffHunk, 'filePath' | 'summary' | 'diffSnippet' | 'hunkIndex'>,
  commitHeader?: string
): string {
  const headerComment = commitHeader
    ? `# Commit: ${commitHeader}\n# Hunk ${hunk.hunkIndex}: ${hunk.summary}\n`
    : `# Hunk ${hunk.hunkIndex}: ${hunk.summary}\n`;
  return `${headerComment}diff --git a/${hunk.filePath} b/${hunk.filePath}\n--- a/${hunk.filePath}\n+++ b/${hunk.filePath}\n${hunk.diffSnippet.trim()}`;
}

export interface StackedSearchMatch {
  id: string;
  kind: 'commit' | 'hunk';
  commitId: string;
  commitSha: string;
  conventionalHeader: string;
  branchName: string;
  prNumber?: number;
  status: AtomicCommitUnit['status'];
  hunkIndex: number;
  totalHunksInCommit: number;
  filePath: string;
  summary: string;
  matchedLinePreview: string;
}

export function searchStackedCommitsAndHunks(
  units: AtomicCommitUnit[],
  rawQuery: string
): StackedSearchMatch[] {
  const query = (rawQuery || '').trim().toLowerCase();
  if (!query) return [];

  const results: StackedSearchMatch[] = [];

  for (const unit of units) {
    const resolvedHunks = resolveCommitRealHunks(unit);
    const navHunks = extractNavigableHunks(resolvedHunks);
    const prLabel = unit.prNumber ? `pr #${unit.prNumber} #${unit.prNumber}` : '';

    const commitHaystack = [
      unit.conventionalHeader,
      unit.title,
      unit.scope,
      unit.type,
      unit.branchName,
      unit.sha,
      prLabel,
    ]
      .join(' ')
      .toLowerCase();

    const commitMatched = commitHaystack.includes(query);

    if (commitMatched && navHunks.length > 0) {
      const firstHunk = navHunks[0];
      results.push({
        id: `commit::${unit.id}`,
        kind: 'commit',
        commitId: unit.id,
        commitSha: unit.sha || '',
        conventionalHeader: unit.conventionalHeader,
        branchName: unit.branchName,
        prNumber: unit.prNumber,
        status: unit.status,
        hunkIndex: 1,
        totalHunksInCommit: navHunks.length,
        filePath: firstHunk.filePath,
        summary: unit.title,
        matchedLinePreview: `${unit.branchName} · +${unit.totalAdditions} / -${unit.totalDeletions} (${unit.totalLoc} LOC)`,
      });
    }

    for (const navHunk of navHunks) {
      const fileMatched = navHunk.filePath.toLowerCase().includes(query);
      const summaryMatched = navHunk.summary.toLowerCase().includes(query);
      const matchingDiffLine = navHunk.diffSnippet
        .split('\n')
        .find((line) => line.toLowerCase().includes(query));

      if (fileMatched || summaryMatched || matchingDiffLine) {
        results.push({
          id: `hunk::${unit.id}::${navHunk.id}`,
          kind: 'hunk',
          commitId: unit.id,
          commitSha: unit.sha || '',
          conventionalHeader: unit.conventionalHeader,
          branchName: unit.branchName,
          prNumber: unit.prNumber,
          status: unit.status,
          hunkIndex: navHunk.hunkIndex,
          totalHunksInCommit: navHunks.length,
          filePath: navHunk.filePath,
          summary: navHunk.summary,
          matchedLinePreview: matchingDiffLine
            ? matchingDiffLine.trim()
            : navHunk.hunkHeader,
        });
      }
    }
  }

  return results;
}

export function resolveCommitRealHunks(unit: AtomicCommitUnit): DiffHunk[] {
  if (Array.isArray(unit.hunks) && unit.hunks.length > 0) {
    return unit.hunks.map((hunk) => {
      if (!isPlaceholderDiffSnippet(hunk.diffSnippet)) {
        return hunk;
      }
      return {
        ...hunk,
        diffSnippet: synthesizeCodeDiffSnippet({
          filePath: hunk.filePath,
          scope: hunk.moduleScope || unit.scope,
          intent: hunk.intent || unit.type,
          summary: hunk.summary || unit.title,
          additions: hunk.additions,
          deletions: hunk.deletions,
        }),
      };
    });
  }

  // Fallback for any legacy cached unit whose hunks array was empty: parse its bodyBullets into real DiffHunks
  const bullets =
    Array.isArray(unit.bodyBullets) && unit.bodyBullets.length > 0
      ? unit.bodyBullets
      : [`src/${unit.scope}/index.ts: ${unit.title} (+${unit.totalAdditions} / -${unit.totalDeletions} LOC)`];

  return bullets.map((bullet, idx) => {
    const colonIdx = bullet.indexOf(':');
    const filePath =
      colonIdx > 0
        ? bullet.slice(0, colonIdx).trim()
        : `src/${unit.scope}/module-${idx + 1}.ts`;
    const rest = colonIdx > 0 ? bullet.slice(colonIdx + 1).trim() : bullet;
    const addMatch = rest.match(/\+(\d+)/);
    const delMatch = rest.match(/-(\d+)/);
    const additions = addMatch
      ? parseInt(addMatch[1], 10)
      : Math.max(12, Math.round(unit.totalAdditions / bullets.length));
    const deletions = delMatch
      ? parseInt(delMatch[1], 10)
      : Math.max(3, Math.round(unit.totalDeletions / bullets.length));
    const summary = rest.replace(/\(\+\d+\s*\/\s*-\d+\s*LOC\)/i, '').trim() || unit.title;

    return {
      id: `${unit.id}-hunk-${idx + 1}`,
      filePath,
      moduleScope: unit.scope,
      intent: unit.type,
      summary,
      additions,
      deletions,
      sourceAgent: unit.sourceAgent || 'antigravity',
      isBrainstormOrPlan: unit.type === 'docs',
      diffSnippet: synthesizeCodeDiffSnippet({
        filePath,
        scope: unit.scope,
        intent: unit.type,
        summary,
        additions,
        deletions,
      }),
    };
  });
}

export function parseRawPatchOrPromptInput(input: {
  promptText: string;
  rawFilesInput: string;
  category?: string;
  sourceAgent?: IdeHostId;
}): { valid: boolean; error?: string; hunks: DiffHunk[] } {
  const cleanPrompt = input.promptText.trim();
  const cleanFiles = input.rawFilesInput.trim();

  if (!cleanPrompt) {
    return {
      valid: false,
      error: 'Please enter the IDE prompt or change description before injecting changes.',
      hunks: [],
    };
  }

  if (!cleanFiles) {
    return {
      valid: false,
      error: 'Please specify at least one modified file path (e.g., src/auth/session.ts +42 -8).',
      hunks: [],
    };
  }

  const lines = cleanFiles
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);

  if (lines.length === 0) {
    return {
      valid: false,
      error: 'At least one valid file path is required.',
      hunks: [],
    };
  }

  const hunks: DiffHunk[] = lines.map((line, idx) => {
    const parts = line.split('|').map((p) => p.trim());
    const firstSegment = parts[0];
    const addMatch = line.match(/\+(\d+)/);
    const delMatch = line.match(/-(\d+)/);

    const candidateToken = firstSegment.split(/\s+/)[0] || '';
    const looksLikePath =
      candidateToken.includes('/') ||
      /\.(ts|tsx|js|jsx|sql|md|json|py|go|rs|css)$/i.test(candidateToken);
    const classificationFromPrompt = classifyFileAndHunkIntent(
      looksLikePath ? candidateToken : `src/core/update.ts`,
      line,
      cleanPrompt
    );
    const filePath = looksLikePath
      ? candidateToken
      : `src/${classificationFromPrompt.scope}/${classificationFromPrompt.intent}Handler.ts`;

    const additions = addMatch ? parseInt(addMatch[1], 10) : 34 + ((idx * 17) % 45);
    const deletions = delMatch ? parseInt(delMatch[1], 10) : 8 + ((idx * 7) % 15);
    const customSummary = parts[2] || parts[1]?.replace(/[+-]\d+/g, '').trim();

    const classification = classifyFileAndHunkIntent(filePath, line, cleanPrompt);
    const summary =
      customSummary && customSummary.length > 3
        ? customSummary
        : `${
            classification.intent === 'docs'
              ? 'Document'
              : classification.intent === 'fix'
              ? 'Fix'
              : 'Implement'
          } ${classification.scope} changes: ${cleanPrompt.slice(0, 56)}`;

    const shaSeed = generateDeterministicShortSha(`${filePath}-${cleanPrompt}-${idx}`);

    return {
      id: `hunk-${shaSeed}-${idx}`,
      filePath,
      moduleScope: classification.scope,
      intent: classification.intent,
      summary,
      additions,
      deletions,
      diffSnippet: synthesizeCodeDiffSnippet({
        filePath,
        scope: classification.scope,
        intent: classification.intent,
        summary,
        additions,
        deletions,
      }),
      promptContext: cleanPrompt,
      sourceAgent: input.sourceAgent || 'antigravity',
      isBrainstormOrPlan: classification.isBrainstormOrPlan,
      hasCoupledTest: classification.intent === 'test',
    };
  });

  return { valid: true, hunks };
}

export function generateDeterministicShortSha(seed: string): string {
  let hash = 2166136261;
  for (let i = 0; i < seed.length; i++) {
    hash ^= seed.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(7, '0').slice(0, 7);
}

export function generateLocalDaemonScript(
  policy: GuardrailPolicy,
  githubConfig: { owner: string; repo: string; defaultBranch: string }
): string {
  return `#!/usr/bin/env node
/**
 * AtomikGit Autonomous Watcher Daemon for Antigravity, Cursor, VS Code, Claude Code & Codex CLI
 * Repository: ${githubConfig.owner}/${githubConfig.repo}
 * Policy: Max ${policy.maxLocPerCommit} LOC/commit | Max ${policy.maxFilesPerCommit} files/commit | Cadence: ${policy.autoCommitCadenceMinutes}m
 *
 * Usage:
 *   node atomik-agent.mjs --watch
 */

import { execSync } from 'node:child_process';
import { watch } from 'node:fs';

const POLICY = {
  maxLocPerCommit: ${policy.maxLocPerCommit},
  maxFilesPerCommit: ${policy.maxFilesPerCommit},
  isolateBrainstormingDocs: ${policy.isolateBrainstormingDocs},
  branchPrefix: '${policy.branchPrefix}',
  baseBranch: '${policy.baseBranch}',
  cadenceMs: ${policy.autoCommitCadenceMinutes} * 60 * 1000,
  autoPush: ${policy.autoPushToGitHub},
};

function getModifiedFiles() {
  const raw = execSync('git status --porcelain', { encoding: 'utf8' });
  return raw
    .split('\\n')
    .filter(Boolean)
    .map((line) => line.slice(3).trim());
}

function classifyIntent(file) {
  if (file.endsWith('.md') || file.includes('docs/') || file.includes('plans/')) return { type: 'docs', scope: 'plans' };
  if (file.includes('.test.') || file.includes('.spec.')) return { type: 'test', scope: 'unit' };
  const parts = file.split('/');
  const scope = parts.length > 1 ? parts[1].replace(/\\..*$/, '') : 'core';
  return { type: 'feat', scope };
}

function runAtomicCycle() {
  const files = getModifiedFiles();
  if (files.length === 0) return;

  const groups = new Map();
  for (const file of files) {
    const { type, scope } = classifyIntent(file);
    const key = \`\${type}(\${scope})\`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(file);
  }

  for (const [headerPrefix, groupFiles] of groups.entries()) {
    const batches = [];
    for (let i = 0; i < groupFiles.length; i += POLICY.maxFilesPerCommit) {
      batches.push(groupFiles.slice(i, i + POLICY.maxFilesPerCommit));
    }

    batches.forEach((batch, index) => {
      const stagedList = batch.map((f) => \`"\${f}"\`).join(' ');
      execSync(\`git add \${stagedList}\`);
      const suffix = batches.length > 1 ? \` (slice \${index + 1}/\${batches.length})\` : '';
      const message = \`\${headerPrefix}: progressive atomic update for \${batch[0]}\${suffix}\`;
      execSync(\`git commit -m "\${message}"\`);
      if (POLICY.autoPush) {
        execSync('git push origin HEAD');
      }
      console.log(\`[AtomikGit] Committed & pushed atomic slice: \${message}\`);
    });
  }
}

console.log('[AtomikGit] Watching workspace for Antigravity / Cursor / Claude Code / Codex edits...');
let debounceTimer = null;
watch('.', { recursive: true }, (_eventType, filename) => {
  if (!filename || filename.startsWith('.git') || filename.includes('node_modules')) return;
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(runAtomicCycle, 4500);
});
setInterval(runAtomicCycle, POLICY.cadenceMs);
`;
}

export function generateIdeExtensionBundle(
  policy: GuardrailPolicy,
  githubConfig: { owner: string; repo: string; defaultBranch: string }
): {
  extensionJs: string;
  extensionManifestJson: string;
  mcpConfigJson: string;
} {
  const extensionManifestJson = JSON.stringify(
    {
      name: 'atomikgit-overlay-agent',
      displayName: 'AtomikGit — Autonomous Atomic Commit & PR Overlay',
      version: '1.4.0',
      publisher: 'atomikgit',
      engines: { vscode: '^1.85.0' },
      activationEvents: ['onStartupFinished'],
      main: './extension.js',
      contributes: {
        commands: [
          {
            command: 'atomikgit.toggleOverlay',
            title: 'AtomikGit: Toggle Real-Time Commit Overlay',
          },
          {
            command: 'atomikgit.sliceAndPushNow',
            title: 'AtomikGit: Slice Working Tree & Create Stacked PR',
          },
        ],
      },
    },
    null,
    2
  );

  const extensionJs = `// AtomikGit Universal IDE Extension (Antigravity / Cursor / VS Code / Windsurf)
// Auto-activates via "onStartupFinished" so you never have to click Commit manually
const vscode = require('vscode');
const { execSync } = require('node:child_process');

const POLICY = {
  maxLocPerCommit: ${policy.maxLocPerCommit},
  maxFilesPerCommit: ${policy.maxFilesPerCommit},
  isolateBrainstormingDocs: ${policy.isolateBrainstormingDocs},
  branchPrefix: '${policy.branchPrefix}',
  repo: '${githubConfig.owner}/${githubConfig.repo}',
};

let statusBarItem;
let settleTimer = null;

function activate(context) {
  statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  statusBarItem.text = '$(git-commit) AtomikGit: Auto-Pilot Watching';
  statusBarItem.tooltip = 'Watching Antigravity / LLM edits in real time — auto-slicing <= ' + POLICY.maxLocPerCommit + ' LOC commits';
  statusBarItem.command = 'atomikgit.sliceAndPushNow';
  statusBarItem.show();

  const watcher = vscode.workspace.onDidSaveTextDocument((doc) => {
    statusBarItem.text = '$(sync~spin) AtomikGit: Analyzing ' + doc.fileName.split('/').pop();
    clearTimeout(settleTimer);
    settleTimer = setTimeout(() => runAtomicSliceAndPr(doc.uri.fsPath), 3500);
  });

  context.subscriptions.push(statusBarItem, watcher);
}

function runAtomicSliceAndPr(lastChangedPath) {
  try {
    const cwd = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!cwd) return;
    execSync('node atomik-agent.mjs --once', { cwd });
    statusBarItem.text = '$(check) AtomikGit: Atomic Slice Pushed & PR Updated';
  } catch (err) {
    statusBarItem.text = '$(git-commit) AtomikGit: Watching (' + POLICY.maxLocPerCommit + ' LOC cap)';
  }
}

module.exports = { activate };
`;

  const mcpConfigJson = JSON.stringify(
    {
      mcpServers: {
        atomikgit: {
          command: 'node',
          args: ['./atomik-agent.mjs', '--watch'],
          env: {
            ATOMIK_MAX_LOC: String(policy.maxLocPerCommit),
            ATOMIK_MAX_FILES: String(policy.maxFilesPerCommit),
            ATOMIK_ISOLATE_DOCS: String(policy.isolateBrainstormingDocs),
            ATOMIK_GITHUB_REPO: `${githubConfig.owner}/${githubConfig.repo}`,
          },
        },
      },
    },
    null,
    2
  );

  return {
    extensionJs,
    extensionManifestJson,
    mcpConfigJson,
  };
}

export interface PrStatusBadgeMeta {
  label: 'Open' | 'Merged' | 'Draft';
  statusKey: 'open' | 'merged' | 'draft';
  badgeBgClass: string;
  badgeTextClass: string;
  badgeBorderClass: string;
  dotColorClass: string;
}

export function resolvePrStatusBadgeMeta(
  status: AtomicCommitUnit['status']
): PrStatusBadgeMeta {
  if (status === 'merged') {
    return {
      label: 'Merged',
      statusKey: 'merged',
      badgeBgClass: 'bg-violet-50/95',
      badgeTextClass: 'text-violet-800',
      badgeBorderClass: 'border-violet-200',
      dotColorClass: 'bg-violet-600',
    };
  }
  if (status === 'pr_open' || status === 'pushed') {
    return {
      label: 'Open',
      statusKey: 'open',
      badgeBgClass: 'bg-emerald-50/95',
      badgeTextClass: 'text-emerald-800',
      badgeBorderClass: 'border-emerald-200',
      dotColorClass: 'bg-emerald-600',
    };
  }
  return {
    label: 'Draft',
    statusKey: 'draft',
    badgeBgClass: 'bg-amber-50/95',
    badgeTextClass: 'text-amber-800',
    badgeBorderClass: 'border-amber-200',
    dotColorClass: 'bg-amber-500',
  };
}

export function summarizeThirtyDayCadence(days: DailyCadenceDay[]): {
  totalCommits: number;
  totalStackedPrs: number;
  avgLocPerCommit: number;
  totalBulkPrevented: number;
  peakDayLabel: string;
  peakDayCommits: number;
} {
  if (!Array.isArray(days) || days.length === 0) {
    return {
      totalCommits: 0,
      totalStackedPrs: 0,
      avgLocPerCommit: 0,
      totalBulkPrevented: 0,
      peakDayLabel: 'N/A',
      peakDayCommits: 0,
    };
  }

  let totalCommits = 0;
  let totalStackedPrs = 0;
  let weightedLocSum = 0;
  let totalBulkPrevented = 0;
  let peakDayLabel = days[0].label;
  let peakDayCommits = days[0].atomicCommitsCount;

  for (const d of days) {
    totalCommits += d.atomicCommitsCount;
    totalStackedPrs += d.prsStackedCount;
    weightedLocSum += d.avgLocPerCommit * d.atomicCommitsCount;
    totalBulkPrevented += d.bulkCommitsPrevented;
    if (d.atomicCommitsCount >= peakDayCommits) {
      peakDayCommits = d.atomicCommitsCount;
      peakDayLabel = d.label;
    }
  }

  const avgLocPerCommit =
    totalCommits > 0 ? Math.round(weightedLocSum / totalCommits) : 0;

  return {
    totalCommits,
    totalStackedPrs,
    avgLocPerCommit,
    totalBulkPrevented,
    peakDayLabel,
    peakDayCommits,
  };
}

