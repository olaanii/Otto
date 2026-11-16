import React, { useState } from 'react';
import {
  AtomicCommitUnit,
  CommitType,
  DiffHunk,
  GuardrailPolicy,
} from '../types/git';
import {
  evaluateCommitCompliance,
} from '../utils/atomicEngine';
import {
  ArrowRight,
  Check,
  ChevronDown,
  ChevronUp,
  GitBranch,
  GitCommit,
  Scissors,
  Sparkles,
  Trash2,
} from 'lucide-react';

interface AtomicSlicerViewProps {
  workingTreeHunks: DiffHunk[];
  stagedAtomicStack: AtomicCommitUnit[];
  policy: GuardrailPolicy;
  isRefiningAi: boolean;
  aiEngineUsed: string | null;
  onReslice: () => void;
  onRefineWithAi: () => void;
  onPushSingleCommit: (commitId: string) => void;
  onPushAllStaged: () => void;
  onSplitCommit: (commitId: string, hunkIdToExtract: string) => void;
  onUpdateCommitHeader: (commitId: string, newTitle: string) => void;
  onRemoveWorkingHunk: (hunkId: string) => void;
  onOpenPromptInjector: () => void;
}

export const AtomicSlicerView: React.FC<AtomicSlicerViewProps> = ({
  workingTreeHunks,
  stagedAtomicStack,
  policy,
  isRefiningAi,
  aiEngineUsed,
  onReslice,
  onRefineWithAi,
  onPushSingleCommit,
  onPushAllStaged,
  onSplitCommit,
  onUpdateCommitHeader,
  onRemoveWorkingHunk,
  onOpenPromptInjector,
}) => {
  const [selectedCategory, setSelectedCategory] = useState<'all' | 'code' | 'test' | 'docs'>('all');
  const [expandedHunkId, setExpandedHunkId] = useState<string | null>(
    workingTreeHunks[0]?.id || null
  );
  const [editingCommitId, setEditingCommitId] = useState<string | null>(null);
  const [editingTitleValue, setEditingTitleValue] = useState<string>('');

  const bulkEvaluation = evaluateCommitCompliance(
    {
      type: 'feat',
      scope: 'bulk',
      title: 'wip bulk commit from IDE session',
      hunks: workingTreeHunks,
    },
    policy
  );

  const filteredStack = stagedAtomicStack.filter((unit) => {
    if (selectedCategory === 'all') return true;
    if (selectedCategory === 'code') {
      return ['feat', 'fix', 'refactor', 'perf', 'chore'].includes(unit.type);
    }
    if (selectedCategory === 'test') return unit.type === 'test';
    if (selectedCategory === 'docs') return unit.type === 'docs';
    return true;
  });

  const handleStartEdit = (unit: AtomicCommitUnit) => {
    setEditingCommitId(unit.id);
    setEditingTitleValue(unit.title);
  };

  const handleSaveEdit = (unitId: string) => {
    if (editingTitleValue.trim()) {
      onUpdateCommitHeader(unitId, editingTitleValue.trim());
    }
    setEditingCommitId(null);
  };

  const formatIntentLabel = (intent: CommitType) => {
    switch (intent) {
      case 'feat':
        return 'Feature';
      case 'fix':
        return 'Bugfix';
      case 'refactor':
        return 'Refactor';
      case 'test':
        return 'Test Spec';
      case 'docs':
        return 'Plan / Docs';
      default:
        return intent;
    }
  };

  return (
    <div className="space-y-8">
      {/* Contrast Banner: Monolithic Bulk Commit Danger vs Atomic Slicer Outcome */}
      <section
        aria-label="Working Tree Bulk Risk Analysis"
        className="border border-zinc-200/90 bg-white rounded-2xl p-6 shadow-xs"
      >
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
          <div className="space-y-2 max-w-3xl">
            <div className="flex flex-wrap items-center gap-2 text-xs text-zinc-500 font-mono tabular-nums">
              <span>Uncommitted Working Tree</span>
              <span aria-hidden="true">·</span>
              <span>{workingTreeHunks.length} modified files</span>
              <span aria-hidden="true">·</span>
              <span className="text-emerald-700 font-medium">+{bulkEvaluation.totalAdditions}</span>
              <span>/</span>
              <span className="text-rose-700 font-medium">-{bulkEvaluation.totalDeletions}</span>
              <span>({bulkEvaluation.totalLoc} total LOC)</span>
              {aiEngineUsed && (
                <>
                  <span aria-hidden="true">·</span>
                  <span className="text-zinc-900 font-medium">Slicer: {aiEngineUsed}</span>
                </>
              )}
            </div>
            <h2 className="text-xl font-bold text-zinc-900 tracking-tight">
              {workingTreeHunks.length === 0
                ? 'Working tree is clean — all atomic slices have been pushed to GitHub'
                : `Prevented 1 monolithic ${bulkEvaluation.totalLoc}-LOC commit → Decomposed into ${stagedAtomicStack.length} atomic commits`}
            </h2>
            {bulkEvaluation.violations.length > 0 && workingTreeHunks.length > 0 && (
              <p className="text-sm text-amber-900 bg-amber-100/80 px-3 py-1.5 rounded-lg">
                Raw IDE working tree would fail senior review ({bulkEvaluation.complianceScore}% compliance):{' '}
                {bulkEvaluation.violations.join(' · ')}
              </p>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-3 shrink-0">
            <button
              type="button"
              onClick={onReslice}
              className="px-4 py-2 text-xs font-medium text-zinc-700 bg-zinc-100 hover:bg-zinc-200 border border-zinc-200 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              Re-Slice Working Tree
            </button>
            <button
              type="button"
              onClick={onRefineWithAi}
              disabled={isRefiningAi || stagedAtomicStack.length === 0}
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-medium text-zinc-800 bg-white hover:bg-zinc-100 disabled:opacity-50 border border-zinc-200 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              <Sparkles className="w-3.5 h-3.5 text-amber-500" />
              <span>{isRefiningAi ? 'Refining Commit Prose...' : 'Refine Commit Specs'}</span>
            </button>
            <button
              type="button"
              onClick={onPushAllStaged}
              disabled={stagedAtomicStack.length === 0}
              className="inline-flex items-center gap-2 px-5 py-2 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 disabled:opacity-40 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              <span>Approve &amp; Push {stagedAtomicStack.length} Atomic Commits</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </section>

      {/* Main 2-Column Split: Left = Raw Working Tree Hunks, Right = Modular Atomic Commit Stack */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left Column: Uncommitted Diff Hunks */}
        <section
          aria-label="Uncommitted IDE Diff Hunks"
          className="lg:col-span-5 border border-zinc-200/90 bg-white rounded-2xl p-6 space-y-5 shadow-2xs"
        >
          <div className="flex items-center justify-between gap-4 border-b border-zinc-200/80 pb-4">
            <div>
              <h3 className="text-base font-bold text-zinc-900">
                Raw IDE Working Tree Hunks
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Accumulated changes from Antigravity, Cursor, Claude Code &amp; Codex before slicing
              </p>
            </div>
            <button
              type="button"
              onClick={onOpenPromptInjector}
              className="px-3 py-1.5 text-xs font-medium text-zinc-800 hover:bg-zinc-100 bg-zinc-50 border border-zinc-200 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              + Simulate IDE Prompt
            </button>
          </div>

          {workingTreeHunks.length === 0 ? (
            <div className="py-12 text-center space-y-3">
              <p className="text-sm text-zinc-800 font-medium">
                No uncommitted hunks remaining in working tree.
              </p>
              <p className="text-xs text-zinc-500 max-w-sm mx-auto">
                Keep coding in your IDE or simulate a new feature/bugfix prompt to watch the agent slice and commit changes progressively.
              </p>
              <button
                type="button"
                onClick={onOpenPromptInjector}
                className="px-4 py-2 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
              >
                Simulate Next Agent Edit
              </button>
            </div>
          ) : (
            <div className="divide-y divide-zinc-200/70">
              {workingTreeHunks.map((hunk) => {
                const isExpanded = expandedHunkId === hunk.id;
                return (
                  <div key={hunk.id} className="py-3.5 first:pt-0 last:pb-0 space-y-2">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-1.5 text-xs text-zinc-500 font-mono tabular-nums">
                          <span className="text-zinc-900 font-semibold truncate">
                            {hunk.filePath}
                          </span>
                          <span aria-hidden="true">·</span>
                          <span className="text-zinc-700 font-medium">{formatIntentLabel(hunk.intent)}</span>
                          <span aria-hidden="true">·</span>
                          <span className="text-emerald-700 font-medium">+{hunk.additions}</span>
                          <span>/</span>
                          <span className="text-rose-700 font-medium">-{hunk.deletions}</span>
                        </div>
                        <p className="text-sm text-zinc-700 mt-1">{hunk.summary}</p>
                        {hunk.promptContext && (
                          <p className="text-xs text-zinc-500 mt-1">
                            Origin: {hunk.promptContext}
                          </p>
                        )}
                      </div>

                      <div className="flex items-center gap-1.5 shrink-0">
                        <button
                          type="button"
                          onClick={() =>
                            setExpandedHunkId(isExpanded ? null : hunk.id)
                          }
                          aria-label={`Toggle diff preview for ${hunk.filePath}`}
                          className="p-1.5 text-zinc-500 hover:text-zinc-900 bg-zinc-100 rounded-md transition-colors cursor-pointer"
                        >
                          {isExpanded ? (
                            <ChevronUp className="w-4 h-4" />
                          ) : (
                            <ChevronDown className="w-4 h-4" />
                          )}
                        </button>
                        <button
                          type="button"
                          onClick={() => onRemoveWorkingHunk(hunk.id)}
                          aria-label={`Discard hunk ${hunk.filePath}`}
                          className="p-1.5 text-zinc-500 hover:text-rose-600 bg-zinc-100 rounded-md transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>

                    {isExpanded && (
                      <pre className="mt-2 p-3 rounded-xl bg-zinc-900 text-xs font-mono text-zinc-100 overflow-x-auto leading-relaxed">
                        {hunk.diffSnippet}
                      </pre>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </section>

        {/* Right Column: Decomposed Modular Atomic Commit Queue */}
        <section
          aria-label="Staged Atomic Commit Queue"
          className="lg:col-span-7 border border-zinc-200/90 bg-white rounded-2xl p-6 space-y-5 shadow-2xs"
        >
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-zinc-200/80 pb-4">
            <div>
              <h3 className="text-base font-bold text-zinc-900">
                Atomic Commit &amp; Branch Stack ({filteredStack.length})
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Each slice is scoped to a single concern, capped at {policy.maxLocPerCommit} LOC, and chained for sequential PR review
              </p>
            </div>

            <div
              role="group"
              aria-label="Filter atomic commits by concern"
              className="flex items-center gap-1 p-1 bg-zinc-100 border border-zinc-200/80 rounded-full shrink-0"
            >
              {(
                [
                  { id: 'all', label: 'All Slices' },
                  { id: 'code', label: 'Code' },
                  { id: 'test', label: 'Tests' },
                  { id: 'docs', label: 'Plans & Docs' },
                ] as const
              ).map((tab) => (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setSelectedCategory(tab.id)}
                  className={`px-3 py-1 text-xs font-medium rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                    selectedCategory === tab.id
                      ? 'bg-zinc-900 text-white shadow-2xs'
                      : 'text-zinc-600 hover:text-zinc-900'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          {filteredStack.length === 0 ? (
            <div className="py-12 text-center space-y-2">
              <p className="text-sm text-zinc-600">
                No staged atomic commits match the current filter.
              </p>
              {selectedCategory !== 'all' && (
                <button
                  type="button"
                  onClick={() => setSelectedCategory('all')}
                  className="px-3 py-1.5 text-xs font-medium text-zinc-900 underline cursor-pointer"
                >
                  Show all atomic slices
                </button>
              )}
            </div>
          ) : (
            <div className="divide-y divide-zinc-200/70">
              {filteredStack.map((unit, index) => {
                const isEditing = editingCommitId === unit.id;
                const locPercent = Math.min(
                  100,
                  Math.round((unit.totalLoc / policy.maxLocPerCommit) * 100)
                );

                return (
                  <article
                    key={unit.id}
                    className="py-5 first:pt-0 last:pb-0 space-y-3"
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-zinc-500 font-mono tabular-nums">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-zinc-900 font-bold">
                          0{index + 1}.
                        </span>
                        <span className="inline-flex items-center gap-1 text-zinc-700">
                          <GitBranch className="w-3.5 h-3.5" />
                          <span>{unit.parentBranch}</span>
                          <span aria-hidden="true">→</span>
                          <span className="text-zinc-900 font-semibold">{unit.branchName}</span>
                        </span>
                        <span aria-hidden="true">·</span>
                        <span>SHA {unit.sha}</span>
                      </div>

                      <div className="flex items-center gap-2">
                        <span className="text-emerald-700 font-medium">+{unit.totalAdditions}</span>
                        <span>/</span>
                        <span className="text-rose-700 font-medium">-{unit.totalDeletions}</span>
                        <span aria-hidden="true">·</span>
                        <span>
                          {unit.totalLoc} / {policy.maxLocPerCommit} LOC ({locPercent}%)
                        </span>
                        <span aria-hidden="true">·</span>
                        <span>~{unit.reviewMinutes} min review</span>
                        <span aria-hidden="true">·</span>
                        <span
                          className={
                            unit.complianceScore === 100
                              ? 'text-emerald-700 font-medium'
                              : 'text-amber-700 font-medium'
                          }
                        >
                          {unit.complianceScore}% compliant
                        </span>
                      </div>
                    </div>

                    {isEditing ? (
                      <div className="flex items-center gap-2">
                        <label htmlFor={`edit-commit-${unit.id}`} className="sr-only">
                          Edit commit title for {unit.conventionalHeader}
                        </label>
                        <input
                          id={`edit-commit-${unit.id}`}
                          type="text"
                          value={editingTitleValue}
                          onChange={(e) => setEditingTitleValue(e.target.value)}
                          className="flex-1 bg-zinc-50 border border-zinc-300 rounded-lg px-3 py-1.5 text-sm font-mono text-zinc-900 focus:outline-none focus:border-zinc-900"
                        />
                        <button
                          type="button"
                          onClick={() => handleSaveEdit(unit.id)}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 rounded-lg cursor-pointer whitespace-nowrap shrink-0"
                        >
                          <Check className="w-3.5 h-3.5" />
                          <span>Save Header</span>
                        </button>
                      </div>
                    ) : (
                      <div className="flex items-start justify-between gap-4">
                        <h4 className="text-sm font-mono font-semibold text-zinc-900">
                          {unit.conventionalHeader}
                        </h4>
                        <button
                          type="button"
                          onClick={() => handleStartEdit(unit)}
                          className="text-xs text-zinc-500 hover:text-zinc-900 underline whitespace-nowrap shrink-0 cursor-pointer"
                        >
                          Edit Subject
                        </button>
                      </div>
                    )}

                    <ul className="space-y-1 text-xs text-zinc-600 pl-4 list-disc">
                      {unit.bodyBullets.map((bullet, bIdx) => (
                        <li key={bIdx}>{bullet}</li>
                      ))}
                    </ul>

                    {unit.violations.length > 0 && (
                      <p className="text-xs text-amber-800 bg-amber-100/70 px-2.5 py-1 rounded">
                        Policy Alert: {unit.violations.join(' · ')}
                      </p>
                    )}

                    <div className="flex flex-wrap items-center justify-between gap-3 pt-2">
                      <div className="text-xs text-zinc-500">
                        {unit.hunks.some((h) => h.isBrainstormOrPlan)
                          ? 'Isolated from production feature stack (branches directly off main)'
                          : `Includes ${unit.hunks.length} atomic file ${
                              unit.hunks.length === 1 ? 'hunk' : 'hunks'
                            }`}
                      </div>

                      <div className="flex items-center gap-2">
                        {unit.hunks.length > 1 && (
                          <button
                            type="button"
                            onClick={() =>
                              onSplitCommit(
                                unit.id,
                                unit.hunks[unit.hunks.length - 1].id
                              )
                            }
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-zinc-800 bg-zinc-100 hover:bg-zinc-200 border border-zinc-200 rounded-lg transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                          >
                            <Scissors className="w-3.5 h-3.5" />
                            <span>Split Hunks</span>
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() => onPushSingleCommit(unit.id)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-zinc-900 bg-amber-200/90 hover:bg-amber-300/90 rounded-lg transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                        >
                          <GitCommit className="w-3.5 h-3.5" />
                          <span>Commit &amp; Push Slice</span>
                        </button>
                      </div>
                    </div>
                  </article>
                );
              })}
            </div>
          )}
        </section>
      </div>
    </div>
  );
};
