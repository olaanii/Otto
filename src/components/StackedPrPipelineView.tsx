import React, { useState } from 'react';
import {
  AtomicCommitUnit,
  DailyCadenceDay,
  GitHubConnectionConfig,
  GuardrailPolicy,
} from '../types/git';
import {
  CheckCircle2,
  GitBranch,
  GitMerge,
  GitPullRequest,
  Layers,
} from 'lucide-react';

interface StackedPrPipelineViewProps {
  pushedStack: AtomicCommitUnit[];
  stagedAtomicStack: AtomicCommitUnit[];
  dailyCadence: DailyCadenceDay[];
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  onMergeTopPr: (commitId: string) => void;
  onPushSingleCommit: (commitId: string) => void;
  onPushAllStaged: () => void;
}

export const StackedPrPipelineView: React.FC<StackedPrPipelineViewProps> = ({
  pushedStack,
  stagedAtomicStack,
  dailyCadence,
  policy,
  githubConfig,
  onMergeTopPr,
  onPushSingleCommit,
  onPushAllStaged,
}) => {
  const [statusFilter, setStatusFilter] = useState<'all' | 'pr_open' | 'merged'>('all');

  const filteredPushed = pushedStack.filter((item) => {
    if (statusFilter === 'all') return true;
    return item.status === statusFilter;
  });

  const totalWeeklyCommits = dailyCadence.reduce(
    (sum, d) => sum + d.atomicCommitsCount,
    0
  );
  const totalBulkPrevented = dailyCadence.reduce(
    (sum, d) => sum + d.bulkCommitsPrevented,
    0
  );
  const avgLocAcrossWeek =
    dailyCadence.length > 0
      ? Math.round(
          dailyCadence.reduce((sum, d) => sum + d.avgLocPerCommit, 0) /
            dailyCadence.length
        )
      : 0;

  return (
    <div className="space-y-8">
      {/* Top Summary Metrics Row */}
      <section
        aria-label="Stacked PR & Reviewability Summary"
        className="border border-zinc-200/90 bg-white rounded-2xl p-6 shadow-2xs"
      >
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 divide-y sm:divide-y-0 sm:divide-x divide-zinc-200/80">
          <div className="pt-4 first:pt-0 sm:pt-0 sm:px-4 first:pl-0">
            <div className="text-xs text-zinc-500">Active Repository Target</div>
            <div className="text-sm font-semibold text-zinc-900 font-mono mt-1.5 break-all">
              {githubConfig.owner}/{githubConfig.repo}
            </div>
            <div className="text-xs text-zinc-500 mt-1">
              Base branch: <span className="font-mono text-zinc-800">{githubConfig.defaultBranch}</span>
            </div>
          </div>

          <div className="pt-4 sm:pt-0 sm:px-4">
            <div className="text-xs text-zinc-500">7-Day Atomic Commits Pushed</div>
            <div className="text-2xl font-bold text-zinc-900 font-mono tabular-nums mt-1">
              {totalWeeklyCommits} commits
            </div>
            <div className="text-xs text-emerald-700 font-medium mt-1">
              7-day daily commit streak maintained
            </div>
          </div>

          <div className="pt-4 sm:pt-0 sm:px-4">
            <div className="text-xs text-zinc-500">Mean PR Slice Size</div>
            <div className="text-2xl font-bold text-zinc-900 font-mono tabular-nums mt-1">
              {avgLocAcrossWeek} LOC
            </div>
            <div className="text-xs text-zinc-500 mt-1">
              Budget cap: {policy.maxLocPerCommit} LOC per atomic PR
            </div>
          </div>

          <div className="pt-4 sm:pt-0 sm:px-4">
            <div className="text-xs text-zinc-500">Monolithic Bulk PRs Prevented</div>
            <div className="text-2xl font-bold text-zinc-900 font-mono tabular-nums mt-1">
              <mark className="bg-amber-200/80 px-1.5 py-0.5 rounded text-zinc-900">
                {totalBulkPrevented} bulk dumps
              </mark>
            </div>
            <div className="text-xs text-zinc-500 mt-1">
              Auto-sliced into ~4 min review units
            </div>
          </div>
        </div>
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left 7 Cols: Pushed Stacked PR Dependency Chain */}
        <section
          aria-label="GitHub Stacked Pull Request Chain"
          className="lg:col-span-7 border border-zinc-200/90 bg-white rounded-2xl p-6 space-y-5 shadow-2xs"
        >
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-zinc-200/80 pb-4">
            <div>
              <h3 className="text-base font-bold text-zinc-900 flex items-center gap-2">
                <Layers className="w-4 h-4 text-zinc-700" />
                <span>GitHub Stacked Pull Request Topology ({filteredPushed.length})</span>
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Small, dependent PR branches chained in review order so reviewers never face a 1,000-line dump
              </p>
            </div>

            <div
              role="group"
              aria-label="Filter stacked PRs by state"
              className="flex items-center gap-1 p-1 bg-zinc-100 border border-zinc-200/80 rounded-full shrink-0"
            >
              {(
                [
                  { id: 'all', label: 'All PRs' },
                  { id: 'pr_open', label: 'Open in Stack' },
                  { id: 'merged', label: 'Merged' },
                ] as const
              ).map((tab) => (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setStatusFilter(tab.id)}
                  className={`px-3 py-1 text-xs font-medium rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                    statusFilter === tab.id
                      ? 'bg-zinc-900 text-white shadow-2xs'
                      : 'text-zinc-600 hover:text-zinc-900'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          <div className="divide-y divide-zinc-200/70">
            {filteredPushed.map((pr, idx) => (
              <article key={pr.id} className="py-5 first:pt-0 last:pb-0 space-y-3">
                <div className="flex flex-wrap items-center justify-between gap-2 text-xs font-mono text-zinc-500 tabular-nums">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="text-zinc-900 font-bold">
                      PR #{pr.prNumber || 140 + idx}
                    </span>
                    <span aria-hidden="true">·</span>
                    <span
                      className={
                        pr.status === 'merged'
                          ? 'text-zinc-500 font-medium'
                          : 'text-emerald-700 font-semibold'
                      }
                    >
                      {pr.status === 'merged' ? 'Merged to Base' : 'Open for Fast Review'}
                    </span>
                    <span aria-hidden="true">·</span>
                    <span className="inline-flex items-center gap-1 text-zinc-700">
                      <GitBranch className="w-3.5 h-3.5" />
                      <span>{pr.parentBranch}</span>
                      <span aria-hidden="true">←</span>
                      <span className="text-zinc-900 font-medium">{pr.branchName}</span>
                    </span>
                  </div>

                  <div className="flex items-center gap-2">
                    <span className="text-emerald-700 font-medium">+{pr.totalAdditions}</span>
                    <span>/</span>
                    <span className="text-rose-700 font-medium">-{pr.totalDeletions}</span>
                    <span aria-hidden="true">·</span>
                    <span>{pr.totalLoc} LOC</span>
                    <span aria-hidden="true">·</span>
                    <span>~{pr.reviewMinutes} min review</span>
                  </div>
                </div>

                <h4 className="text-sm font-mono font-semibold text-zinc-900">
                  {pr.conventionalHeader}
                </h4>

                <ul className="space-y-1 text-xs text-zinc-600 pl-4 list-disc">
                  {pr.bodyBullets.map((b, bIdx) => (
                    <li key={bIdx}>{b}</li>
                  ))}
                </ul>

                <div className="flex flex-wrap items-center justify-between gap-3 pt-1">
                  <span className="text-xs text-zinc-500 font-mono">
                    Commit SHA: {pr.sha} · Compliance: {pr.complianceScore}%
                  </span>

                  {pr.status === 'pr_open' ? (
                    <button
                      type="button"
                      onClick={() => onMergeTopPr(pr.id)}
                      className="inline-flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                    >
                      <GitMerge className="w-3.5 h-3.5" />
                      <span>Merge Atomic PR &amp; Rebase Stack</span>
                    </button>
                  ) : (
                    <span className="inline-flex items-center gap-1 text-xs text-zinc-500">
                      <CheckCircle2 className="w-3.5 h-3.5 text-zinc-700" />
                      <span>Merged cleanly into {pr.parentBranch}</span>
                    </span>
                  )}
                </div>
              </article>
            ))}
          </div>

          {stagedAtomicStack.length > 0 && (
            <div className="pt-4 border-t border-zinc-200/80 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="text-xs text-zinc-700">
                <span className="font-semibold text-zinc-900">
                  {stagedAtomicStack.length} staged atomic slices
                </span>{' '}
                are ready to be appended to this GitHub PR stack.
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => onPushSingleCommit(stagedAtomicStack[0].id)}
                  className="px-3 py-1.5 text-xs font-medium text-zinc-800 bg-zinc-100 hover:bg-zinc-200 border border-zinc-200 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                >
                  Push Next Slice ({stagedAtomicStack[0].type}({stagedAtomicStack[0].scope}))
                </button>
                <button
                  type="button"
                  onClick={onPushAllStaged}
                  className="inline-flex items-center gap-1.5 px-4 py-1.5 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 rounded-full transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                >
                  <GitPullRequest className="w-3.5 h-3.5" />
                  <span>Push All {stagedAtomicStack.length} to Stack</span>
                </button>
              </div>
            </div>
          )}
        </section>

        {/* Right 5 Cols: Daily GitHub Contribution Cadence Table */}
        <section
          aria-label="Daily GitHub Commit Cadence Ledger"
          className="lg:col-span-5 border border-zinc-200/90 bg-white rounded-2xl p-6 space-y-5 shadow-2xs"
        >
          <div className="border-b border-zinc-200/80 pb-4">
            <h3 className="text-base font-bold text-zinc-900">
              Daily GitHub Cadence &amp; Anti-Bulk Ledger
            </h3>
            <p className="text-xs text-zinc-500 mt-0.5">
              Eliminates silent multi-day coding gaps by progressively pushing atomic slices every day you work
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-zinc-200 text-zinc-500">
                  <th className="py-2.5 pr-3 font-medium">Day</th>
                  <th className="py-2.5 px-3 font-medium text-right">Atomic Commits</th>
                  <th className="py-2.5 px-3 font-medium text-right">Stacked PRs</th>
                  <th className="py-2.5 px-3 font-medium text-right">Avg Slice</th>
                  <th className="py-2.5 pl-3 font-medium text-right">Bulk Split</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-200/60 font-mono tabular-nums">
                {dailyCadence.map((day) => (
                  <tr key={day.date} className="hover:bg-zinc-50">
                    <td className="py-2.5 pr-3 text-zinc-900 font-sans">
                      <span className="font-medium">{day.label}</span>{' '}
                      <span className="text-zinc-500 font-mono">({day.date.slice(5)})</span>
                    </td>
                    <td className="py-2.5 px-3 text-right text-emerald-700 font-semibold">
                      {day.atomicCommitsCount}
                    </td>
                    <td className="py-2.5 px-3 text-right text-zinc-800">
                      {day.prsStackedCount}
                    </td>
                    <td className="py-2.5 px-3 text-right text-zinc-600">
                      {day.avgLocPerCommit} LOC
                    </td>
                    <td className="py-2.5 pl-3 text-right text-zinc-900 font-semibold">
                      {day.bulkCommitsPrevented}x
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>
  );
};
