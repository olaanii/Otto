import React, { useMemo, useState } from 'react';
import {
  AtomicCommitUnit,
  GitHubConnectionConfig,
  GuardrailPolicy,
} from '../types/git';
import {
  buildStackDependencyGraph,
  rebaseAndReorderPendingStack,
  resolveCommitCiCdStatus,
  scanStackForMergeConflicts,
  sortStackBySemanticOrder,
} from '../utils/atomicEngine';
import {
  AlertTriangle,
  ArrowDown,
  ArrowUp,
  Check,
  Copy,
  GitBranch,
  GitCommit,
  GitMerge,
  GripVertical,
  RotateCcw,
  Sparkles,
} from 'lucide-react';

interface RebasePlaygroundViewProps {
  pendingStack: AtomicCommitUnit[];
  allUnits: AtomicCommitUnit[];
  policy: GuardrailPolicy;
  githubConfig: GitHubConnectionConfig;
  selectedUnitId: string | null;
  onSelectUnit: (commitId: string) => void;
  onReorderPendingStack: (nextStack: AtomicCommitUnit[], summaryMessage?: string) => void;
  onReturnToGitDiff: () => void;
}

export const RebasePlaygroundView: React.FC<RebasePlaygroundViewProps> = ({
  pendingStack,
  allUnits,
  policy,
  githubConfig,
  selectedUnitId,
  onSelectUnit,
  onReorderPendingStack,
  onReturnToGitDiff,
}) => {
  const [draggedIndex, setDraggedIndex] = useState<number | null>(null);
  const [dragOverIndex, setDragOverIndex] = useState<number | null>(null);
  const [copiedRebaseTodo, setCopiedRebaseTodo] = useState(false);

  const baseBranch = policy.baseBranch || githubConfig.defaultBranch || 'main';

  const dependencyGraph = useMemo(
    () => buildStackDependencyGraph(pendingStack, baseBranch),
    [pendingStack, baseBranch]
  );

  const handleMoveCommit = (fromIndex: number, toIndex: number) => {
    if (
      fromIndex === toIndex ||
      fromIndex < 0 ||
      toIndex < 0 ||
      fromIndex >= pendingStack.length ||
      toIndex >= pendingStack.length
    ) {
      return;
    }
    const movedUnit = pendingStack[fromIndex];
    const rebased = rebaseAndReorderPendingStack(
      pendingStack,
      fromIndex,
      toIndex,
      policy
    );
    onReorderPendingStack(
      rebased,
      `Rebased stack: moved "${movedUnit.conventionalHeader}" from position #${
        fromIndex + 1
      } to #${toIndex + 1} and updated child branch dependencies.`
    );
  };

  const handleDragStart = (e: React.DragEvent, index: number) => {
    setDraggedIndex(index);
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', String(index));
  };

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    if (dragOverIndex !== index) {
      setDragOverIndex(index);
    }
  };

  const handleDrop = (e: React.DragEvent, dropIndex: number) => {
    e.preventDefault();
    const rawFrom = e.dataTransfer.getData('text/plain');
    const fromIdx =
      draggedIndex !== null ? draggedIndex : parseInt(rawFrom, 10);
    setDraggedIndex(null);
    setDragOverIndex(null);
    if (!Number.isNaN(fromIdx)) {
      handleMoveCommit(fromIdx, dropIndex);
    }
  };

  const handleDragEnd = () => {
    setDraggedIndex(null);
    setDragOverIndex(null);
  };

  const handleAutoSortSemantic = () => {
    const sorted = sortStackBySemanticOrder(pendingStack, policy);
    onReorderPendingStack(
      sorted,
      'Rebased stack into canonical semantic order (refactor → feat → fix → test → docs).'
    );
  };

  const handleCopyRebaseTodo = async () => {
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(dependencyGraph.rebaseTodoScript);
      }
    } catch {
      // Fallback for restricted clipboard in headless browsers
    }
    setCopiedRebaseTodo(true);
    window.setTimeout(() => setCopiedRebaseTodo(false), 1800);
  };

  return (
    <div
      id="otto-rebase-playground"
      data-testid="rebase-playground-view"
      className="w-full max-w-[960px] mx-auto flex-1 flex flex-col min-h-0 rounded-2xl bg-[#14161C] text-zinc-100 border border-black/20 shadow-[0_16px_40px_rgba(0,0,0,0.12)] overflow-hidden font-mono text-xs"
    >
      {/* Top Rebase Playground Header Bar */}
      <div className="px-4 py-3 bg-[#1B1E26] border-b border-white/[0.08] flex flex-wrap items-center justify-between gap-3 shrink-0">
        <div className="space-y-1 min-w-0">
          <div className="flex flex-wrap items-center gap-2 text-[11px] text-zinc-400">
            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-indigo-500/20 text-indigo-300 border border-indigo-400/30 font-semibold uppercase tracking-wider text-[10px]">
              <GitBranch className="w-3 h-3 text-indigo-300" />
              Rebase Playground
            </span>
            <span className="text-zinc-300 font-semibold">
              git rebase -i {baseBranch}
            </span>
            <span className="text-zinc-600">·</span>
            <span
              data-testid="rebase-stack-count-badge"
              className="text-emerald-400"
            >
              {pendingStack.length} pending atomic{' '}
              {pendingStack.length === 1 ? 'commit' : 'commits'}
            </span>
            {dependencyGraph.orderWarningsCount > 0 ? (
              <span
                data-testid="rebase-order-warning-badge"
                className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-amber-500/20 border border-amber-400/40 text-amber-200 text-[10px] font-semibold"
              >
                <AlertTriangle className="w-3 h-3 text-amber-300" />
                {dependencyGraph.orderWarningsCount} order{' '}
                {dependencyGraph.orderWarningsCount === 1
                  ? 'warning'
                  : 'warnings'}
              </span>
            ) : (
              <span
                data-testid="rebase-order-clean-badge"
                className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-emerald-500/15 border border-emerald-400/30 text-emerald-300 text-[10px] font-semibold"
              >
                <Check className="w-3 h-3 text-emerald-400" />
                Clean DAG Order
              </span>
            )}
          </div>
          <div className="text-[11px] text-zinc-400 truncate">
            Drag and drop commits (or use ↑/↓ controls) to reorder the stack and
            watch parent-child PR branches &amp; DAG edges recalculate live.
          </div>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          <button
            type="button"
            data-testid="rebase-auto-sort-btn"
            onClick={handleAutoSortSemantic}
            title="Restore canonical semantic order (refactor → feat → fix → test → docs)"
            className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-white/[0.07] hover:bg-white/[0.14] border border-white/[0.1] text-[11px] text-zinc-200 transition-colors cursor-pointer"
          >
            <Sparkles className="w-3.5 h-3.5 text-indigo-300" />
            <span>Auto-Sort DAG</span>
          </button>

          <button
            type="button"
            data-testid="copy-rebase-todo-btn"
            onClick={handleCopyRebaseTodo}
            className={`inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border text-[11px] transition-colors cursor-pointer ${
              copiedRebaseTodo
                ? 'bg-emerald-500/25 border-emerald-400/40 text-emerald-200 font-semibold'
                : 'bg-white/[0.07] hover:bg-white/[0.14] border-white/[0.1] text-zinc-200'
            }`}
          >
            {copiedRebaseTodo ? (
              <>
                <Check className="w-3.5 h-3.5 text-emerald-300" />
                <span>Copied Todo!</span>
              </>
            ) : (
              <>
                <Copy className="w-3.5 h-3.5 text-zinc-300" />
                <span>Copy Rebase Todo</span>
              </>
            )}
          </button>

          <button
            type="button"
            onClick={onReturnToGitDiff}
            className="px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white text-[11px] font-semibold transition-colors cursor-pointer"
          >
            Inspect Diff →
          </button>
        </div>
      </div>

      {/* Main Split Workspace: Left Drag-and-Drop Stack + Right Real-Time Dependency Graph */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-12 min-h-0 divide-y lg:divide-y-0 lg:divide-x divide-white/[0.08] overflow-hidden">
        {/* LEFT COLUMN (7 cols): Interactive Drag-and-Drop Rebase Stack */}
        <div className="lg:col-span-7 flex flex-col min-h-0 overflow-y-auto p-3.5 space-y-2.5">
          <div className="flex items-center justify-between px-1 text-[10.5px] text-zinc-400">
            <span className="uppercase tracking-wider font-semibold text-zinc-300">
              Interactive Stack Order (Base → Top)
            </span>
            <span>Drag cards or click ↑ / ↓ to reorder</span>
          </div>

          {pendingStack.length === 0 ? (
            <div className="p-8 rounded-xl bg-white/[0.03] border border-white/[0.06] text-center space-y-2">
              <div className="text-zinc-300 font-semibold">
                All pending slices have been pushed to GitHub.
              </div>
              <div className="text-[11px] text-zinc-500">
                Use the bottom prompt bar or click Reset to stage new atomic
                slices for interactive rebasing.
              </div>
            </div>
          ) : (
            <div
              role="list"
              aria-label="Draggable Pending Commits Stack"
              className="space-y-2"
            >
              {pendingStack.map((unit, idx) => {
                const graphNode = dependencyGraph.nodes[idx];
                const ciReport = resolveCommitCiCdStatus(unit, githubConfig);
                const conflictReport = scanStackForMergeConflicts(
                  unit,
                  allUnits
                );
                const isSelected = selectedUnitId === unit.id;
                const isDragging = draggedIndex === idx;
                const isDragOver = dragOverIndex === idx && draggedIndex !== idx;

                return (
                  <div
                    key={unit.id}
                    role="listitem"
                    draggable
                    data-testid={`rebase-commit-item-${idx}`}
                    data-commit-id={unit.id}
                    data-branch-name={unit.branchName}
                    data-parent-branch={unit.parentBranch}
                    onDragStart={(e) => handleDragStart(e, idx)}
                    onDragOver={(e) => handleDragOver(e, idx)}
                    onDrop={(e) => handleDrop(e, idx)}
                    onDragEnd={handleDragEnd}
                    onClick={() => onSelectUnit(unit.id)}
                    className={`p-3 rounded-xl border transition-all select-none cursor-grab active:cursor-grabbing ${
                      isDragOver
                        ? 'bg-indigo-500/20 border-indigo-400 ring-2 ring-indigo-400/50 scale-[1.01]'
                        : isDragging
                        ? 'opacity-50 bg-[#1B1F2B] border-indigo-400/40'
                        : isSelected
                        ? 'bg-[#1D2230] border-indigo-500/60 shadow-md'
                        : 'bg-[#181B24] hover:bg-[#1C202B] border-white/[0.08]'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2.5">
                      <div className="flex items-start gap-2 min-w-0 flex-1">
                        <span
                          title="Drag to reorder commit in stack"
                          className="mt-0.5 p-1 rounded bg-white/[0.05] text-zinc-400 hover:text-white shrink-0"
                        >
                          <GripVertical className="w-3.5 h-3.5" />
                        </span>

                        <div className="min-w-0 flex-1 space-y-1.5">
                          <div className="flex flex-wrap items-center gap-1.5">
                            <span
                              data-testid={`rebase-slot-badge-${idx}`}
                              className="px-1.5 py-0.5 rounded bg-indigo-500/25 border border-indigo-400/40 text-indigo-200 text-[10px] font-bold"
                            >
                              #{idx + 1} {idx === 0 ? 'BASE' : idx === pendingStack.length - 1 ? 'HEAD' : 'STACK'}
                            </span>
                            <span className="px-1.5 py-0.5 rounded bg-white/[0.07] text-emerald-300 text-[10px] font-semibold">
                              pick {unit.sha}
                            </span>
                            <span
                              className={`px-1.5 py-0.5 rounded text-[9.5px] font-semibold uppercase ${
                                ciReport.status === 'passing'
                                  ? 'bg-emerald-500/15 text-emerald-300 border border-emerald-500/30'
                                  : ciReport.status === 'failing'
                                  ? 'bg-rose-500/20 text-rose-300 border border-rose-500/40'
                                  : 'bg-amber-500/15 text-amber-200 border border-amber-500/30'
                              }`}
                            >
                              CI: {ciReport.statusLabel}
                            </span>
                            {conflictReport.hasConflicts && (
                              <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-rose-500/25 border border-rose-400/50 text-rose-200 text-[9.5px] font-semibold">
                                <AlertTriangle className="w-2.5 h-2.5 text-rose-300" />
                                Shared File Overlap
                              </span>
                            )}
                          </div>

                          <div
                            data-testid={`rebase-commit-header-${idx}`}
                            className="text-xs font-semibold text-white truncate"
                          >
                            {unit.conventionalHeader}
                          </div>

                          {/* Live Recomputed Branch Dependency Chain */}
                          <div className="flex flex-wrap items-center gap-1.5 text-[10.5px] text-zinc-400">
                            <GitBranch className="w-3 h-3 text-indigo-400 shrink-0" />
                            <span
                              data-testid={`rebase-parent-branch-${idx}`}
                              className="px-1.5 py-0.5 rounded bg-black/40 text-amber-300 border border-white/[0.06]"
                            >
                              {unit.parentBranch}
                            </span>
                            <span className="text-zinc-500">←</span>
                            <span
                              data-testid={`rebase-branch-name-${idx}`}
                              className="px-1.5 py-0.5 rounded bg-indigo-500/15 text-indigo-200 border border-indigo-400/25 font-medium"
                            >
                              {unit.branchName}
                            </span>
                            <span className="text-zinc-500 ml-auto tabular-nums">
                              +{unit.totalAdditions} / -{unit.totalDeletions} (
                              {unit.totalLoc} LOC)
                            </span>
                          </div>

                          {graphNode?.orderWarning && (
                            <div
                              data-testid={`rebase-node-warning-${idx}`}
                              className="px-2 py-1 rounded bg-amber-500/15 border border-amber-400/40 text-amber-200 text-[10px] flex items-center gap-1.5"
                            >
                              <AlertTriangle className="w-3 h-3 text-amber-300 shrink-0" />
                              <span className="truncate">
                                {graphNode.orderWarning}
                              </span>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Keyboard & Click Reorder Buttons */}
                      <div
                        className="flex flex-col gap-1 shrink-0"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <button
                          type="button"
                          data-testid={`rebase-move-up-${idx}`}
                          aria-label={`Move commit ${idx + 1} up in stack`}
                          disabled={idx === 0}
                          onClick={() => handleMoveCommit(idx, idx - 1)}
                          className="p-1 rounded bg-white/[0.07] hover:bg-indigo-500/30 disabled:opacity-30 text-zinc-200 cursor-pointer disabled:cursor-not-allowed transition-colors"
                          title="Move earlier in stack (closer to base branch)"
                        >
                          <ArrowUp className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          data-testid={`rebase-move-down-${idx}`}
                          aria-label={`Move commit ${idx + 1} down in stack`}
                          disabled={idx === pendingStack.length - 1}
                          onClick={() => handleMoveCommit(idx, idx + 1)}
                          className="p-1 rounded bg-white/[0.07] hover:bg-indigo-500/30 disabled:opacity-30 text-zinc-200 cursor-pointer disabled:cursor-not-allowed transition-colors"
                          title="Move later in stack (closer to stack top)"
                        >
                          <ArrowDown className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Live Interactive git-rebase-todo Script Preview */}
          <div className="mt-2 pt-2 border-t border-white/[0.07] space-y-1.5">
            <div className="flex items-center justify-between text-[10px] text-zinc-400">
              <span className="uppercase tracking-wider font-semibold">
                Generated .git/rebase-merge/git-rebase-todo
              </span>
              <span className="text-emerald-400">Live Sync</span>
            </div>
            <pre
              data-testid="rebase-todo-script-preview"
              className="p-2.5 rounded-xl bg-[#0D0F14] border border-white/[0.07] text-[10.5px] text-zinc-300 overflow-x-auto leading-relaxed"
            >
              {dependencyGraph.rebaseTodoScript}
            </pre>
          </div>
        </div>

        {/* RIGHT COLUMN (5 cols): Real-Time Dependency Graph DAG */}
        <div
          data-testid="rebase-dependency-graph"
          className="lg:col-span-5 flex flex-col min-h-0 overflow-y-auto p-3.5 bg-[#11131A] space-y-3"
        >
          <div className="flex items-center justify-between">
            <div>
              <div className="text-[11px] font-semibold uppercase tracking-wider text-indigo-300">
                Real-Time Dependency Graph (DAG)
              </div>
              <div className="text-[10px] text-zinc-400">
                Parent PR chain &amp; cross-slice file couplings
              </div>
            </div>
            <span className="px-2 py-0.5 rounded bg-white/[0.06] text-[10px] text-zinc-300 tabular-nums">
              {dependencyGraph.edges.length} edges
            </span>
          </div>

          {/* Interactive SVG + Node Topology Graph */}
          <div className="relative rounded-xl bg-[#161922] border border-white/[0.08] p-3.5 space-y-2">
            {/* Root Base Branch Node */}
            <div
              data-testid="dag-base-branch-node"
              className="p-2.5 rounded-xl bg-emerald-950/50 border border-emerald-500/40 flex items-center justify-between"
            >
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.8)]" />
                <span className="font-bold text-emerald-200 text-xs">
                  {baseBranch}
                </span>
                <span className="text-[10px] text-emerald-300/80">
                  (Base Target Branch)
                </span>
              </div>
              <GitMerge className="w-3.5 h-3.5 text-emerald-400" />
            </div>

            {/* Dynamic DAG Nodes & Directed Connector Edges */}
            {dependencyGraph.nodes.map((node, nIdx) => {
              const isSelected = selectedUnitId === node.commitId;
              const fileCouplingEdges = dependencyGraph.edges.filter(
                (e) =>
                  e.toNodeId === node.id &&
                  (e.kind === 'file_coupling' || e.kind === 'order_violation')
              );

              return (
                <div key={node.id} className="space-y-1.5">
                  {/* SVG Directed Edge Connector from Parent Branch */}
                  <div className="flex items-center gap-2 pl-4 py-0.5">
                    <svg
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      className="shrink-0 overflow-visible"
                      aria-hidden="true"
                    >
                      <line
                        x1="12"
                        y1="0"
                        x2="12"
                        y2="20"
                        stroke={
                          node.orderWarning
                            ? '#F59E0B'
                            : node.isIsolatedFromChain
                            ? '#34D399'
                            : '#818CF8'
                        }
                        strokeWidth="2"
                        strokeDasharray={node.isIsolatedFromChain ? '3 3' : undefined}
                      />
                      <polygon
                        points="8,16 16,16 12,23"
                        fill={
                          node.orderWarning
                            ? '#F59E0B'
                            : node.isIsolatedFromChain
                            ? '#34D399'
                            : '#818CF8'
                        }
                      />
                    </svg>
                    <span
                      data-testid={`dag-edge-label-${nIdx}`}
                      className="text-[10px] text-zinc-400 truncate"
                    >
                      rebases onto{' '}
                      <strong className="text-indigo-200">
                        {node.parentBranch}
                      </strong>
                      {node.isIsolatedFromChain && (
                        <span className="ml-1.5 text-emerald-300">
                          (isolated docs branch)
                        </span>
                      )}
                    </span>
                  </div>

                  {/* DAG Node Card */}
                  <div
                    data-testid={`dag-node-${nIdx}`}
                    data-node-branch={node.branchName}
                    data-node-parent={node.parentBranch}
                    onClick={() => onSelectUnit(node.commitId)}
                    className={`p-2.5 rounded-xl border transition-all cursor-pointer space-y-1.5 ${
                      node.orderWarning
                        ? 'bg-amber-950/40 border-amber-500/60'
                        : isSelected
                        ? 'bg-indigo-950/60 border-indigo-400/70 ring-1 ring-indigo-400/40'
                        : 'bg-[#1D212D] hover:bg-[#232836] border-white/[0.09]'
                    }`}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-1.5 min-w-0">
                        <span className="w-5 h-5 rounded-full bg-indigo-500/30 border border-indigo-400/50 text-indigo-200 text-[10px] font-bold flex items-center justify-center shrink-0">
                          {node.stackPosition}
                        </span>
                        <span className="font-semibold text-white truncate">
                          {node.branchName}
                        </span>
                      </div>
                      <span className="px-1.5 py-0.5 rounded bg-black/40 text-[10px] text-emerald-300 shrink-0">
                        {node.sha}
                      </span>
                    </div>

                    <div className="text-[10.5px] text-zinc-300 truncate">
                      {node.conventionalHeader}
                    </div>

                    {/* File Couplings & Shared Dependencies in Graph */}
                    <div className="flex flex-wrap items-center gap-1 pt-0.5">
                      {node.filesTouched.map((file) => (
                        <span
                          key={file}
                          className="px-1.5 py-0.5 rounded bg-white/[0.05] text-[9.5px] text-zinc-300 truncate max-w-full"
                        >
                          {file}
                        </span>
                      ))}
                    </div>

                    {fileCouplingEdges.map((edge) => (
                      <div
                        key={edge.id}
                        data-testid="dag-file-coupling-edge"
                        className={`px-2 py-1 rounded text-[9.5px] flex items-center gap-1.5 ${
                          edge.kind === 'order_violation'
                            ? 'bg-rose-500/20 border border-rose-400/40 text-rose-200'
                            : 'bg-indigo-500/15 border border-indigo-400/30 text-indigo-200'
                        }`}
                      >
                        <GitCommit className="w-3 h-3 shrink-0" />
                        <span className="truncate">{edge.detailLabel}</span>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};
