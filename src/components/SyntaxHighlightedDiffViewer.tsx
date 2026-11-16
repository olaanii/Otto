import React, { useState } from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { AlertTriangle, Check, Copy } from 'lucide-react';
import {
  FileMergeConflictDetail,
  formatHunkForClipboard,
  NavigableDiffHunk,
  ParsedDiffLine,
  parseUnifiedDiffLines,
  SyntaxLanguageId,
} from '../utils/atomicEngine';

const DIFF_SYNTAX_STYLE: Record<string, React.CSSProperties> = {
  ...vscDarkPlus,
  'pre[class*="language-"]': {
    ...(vscDarkPlus['pre[class*="language-"]'] || {}),
    background: 'transparent',
    margin: 0,
    padding: 0,
    overflow: 'visible',
    fontSize: '12px',
    lineHeight: '1.55',
    fontFamily:
      'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
  },
  'code[class*="language-"]': {
    ...(vscDarkPlus['code[class*="language-"]'] || {}),
    background: 'transparent',
    margin: 0,
    padding: 0,
    fontSize: '12px',
    lineHeight: '1.55',
    fontFamily:
      'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
  },
};

interface HighlightedCodeLineProps {
  code: string;
  language: SyntaxLanguageId;
}

const HighlightedCodeLine: React.FC<HighlightedCodeLineProps> = ({
  code,
  language,
}) => {
  if (!code.trim()) {
    return <span>{code || ' '}</span>;
  }

  return (
    <SyntaxHighlighter
      language={language}
      style={DIFF_SYNTAX_STYLE}
      PreTag="span"
      CodeTag="span"
      customStyle={{
        background: 'transparent',
        padding: 0,
        margin: 0,
        display: 'inline',
      }}
    >
      {code}
    </SyntaxHighlighter>
  );
};

interface SyntaxHighlightedDiffViewerProps {
  hunk: NavigableDiffHunk;
  commitHeader?: string;
  totalHunksInCommit: number;
  isFocusedHunk: boolean;
  diffLayout: 'unified' | 'split';
  canExtractHunk: boolean;
  fileConflicts?: FileMergeConflictDetail[];
  onExtractHunk?: () => void;
  onSelectHunk?: () => void;
  onCopyHunk?: (hunk: NavigableDiffHunk, formattedPayload: string) => void;
}

export const SyntaxHighlightedDiffViewer: React.FC<
  SyntaxHighlightedDiffViewerProps
> = ({
  hunk,
  commitHeader,
  totalHunksInCommit,
  isFocusedHunk,
  diffLayout,
  canExtractHunk,
  fileConflicts,
  onExtractHunk,
  onSelectHunk,
  onCopyHunk,
}) => {
  const [copiedLocal, setCopiedLocal] = useState(false);
  const hasFileConflict = Boolean(fileConflicts && fileConflicts.length > 0);
  const primaryConflict = fileConflicts?.[0];

  const handleCopyClick = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const formatted = formatHunkForClipboard(hunk, commitHeader);
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(formatted);
      }
    } catch {
      // Fallback when clipboard permissions are restricted in headless browser
    }
    setCopiedLocal(true);
    onCopyHunk?.(hunk, formatted);
    window.setTimeout(() => {
      setCopiedLocal(false);
    }, 1800);
  };

  const parsedLines: ParsedDiffLine[] = parseUnifiedDiffLines(hunk.diffSnippet);
  const oldSideLines = parsedLines.filter(
    (l) => l.type === 'hunk_header' || l.type === 'del' || l.type === 'context'
  );
  const newSideLines = parsedLines.filter(
    (l) => l.type === 'hunk_header' || l.type === 'add' || l.type === 'context'
  );

  return (
    <div
      id={`git-diff-hunk-${hunk.hunkIndex}`}
      data-testid="syntax-highlighted-diff-viewer"
      data-file-conflict={hasFileConflict ? 'true' : 'false'}
      onClick={onSelectHunk}
      className={`font-mono text-xs transition-colors ${
        hasFileConflict
          ? 'bg-[#181216] ring-1 ring-inset ring-rose-500/50'
          : isFocusedHunk
          ? 'bg-[#141720] ring-1 ring-inset ring-indigo-500/40'
          : 'bg-[#12141B] opacity-90 hover:opacity-100'
      }`}
    >
      {/* File & Hunk Index Header Bar */}
      <div
        className={`px-4 py-2 border-b flex items-center justify-between gap-2 sticky top-0 z-10 ${
          hasFileConflict
            ? 'bg-rose-950/60 border-rose-500/40'
            : 'bg-[#181B24] border-white/[0.07]'
        }`}
      >
        <div className="flex items-center gap-2 min-w-0">
          <span
            className={`px-2 py-0.5 rounded text-[10px] font-semibold whitespace-nowrap shrink-0 ${
              hasFileConflict
                ? 'bg-rose-500/30 text-rose-200 border border-rose-400/50'
                : isFocusedHunk
                ? 'bg-indigo-500/25 text-indigo-200 border border-indigo-400/40'
                : 'bg-white/[0.06] text-zinc-400 border border-white/[0.06]'
            }`}
          >
            Hunk {hunk.hunkIndex}/{totalHunksInCommit}
          </span>
          <span className="px-1.5 py-0.5 rounded bg-white/[0.05] text-[10px] text-zinc-400 uppercase whitespace-nowrap shrink-0">
            {hunk.language}
          </span>
          <span
            className={`font-semibold whitespace-nowrap shrink-0 ${
              hasFileConflict ? 'text-rose-200' : 'text-zinc-100'
            }`}
          >
            {hunk.filePath}
          </span>
          {hasFileConflict && primaryConflict && (
            <span
              data-testid="diff-viewer-conflict-badge"
              title={primaryConflict.conflictReason}
              className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-rose-500/25 border border-rose-400/50 text-[10px] font-semibold text-rose-200 whitespace-nowrap shrink-0"
            >
              <AlertTriangle className="w-3 h-3 text-rose-300 shrink-0" />
              <span>
                CONFLICT · {primaryConflict.conflictingBranchName}
              </span>
            </span>
          )}
          <span className="text-[11px] text-zinc-400 truncate hidden md:inline">
            — {hunk.summary}
          </span>
        </div>

        <div className="flex items-center gap-2 text-[11px] tabular-nums shrink-0">
          <span className="text-emerald-400 font-medium">
            +{hunk.additions}
          </span>
          <span className="text-rose-400 font-medium">-{hunk.deletions}</span>

          <button
            type="button"
            data-testid={`copy-hunk-btn-${hunk.hunkIndex}`}
            aria-label="Copy Hunk"
            onClick={handleCopyClick}
            title="Copy current diff hunk to clipboard for debugging or PR comments"
            className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-medium transition-colors cursor-pointer whitespace-nowrap ${
              copiedLocal
                ? 'bg-emerald-500/25 text-emerald-200 border border-emerald-400/40'
                : 'bg-white/[0.08] hover:bg-white/[0.16] text-zinc-200 border border-white/[0.08]'
            }`}
          >
            {copiedLocal ? (
              <>
                <Check className="w-3 h-3 text-emerald-300" />
                <span>Copied!</span>
              </>
            ) : (
              <>
                <Copy className="w-3 h-3 text-zinc-300" />
                <span>Copy Hunk</span>
              </>
            )}
          </button>

          {canExtractHunk && onExtractHunk && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                onExtractHunk();
              }}
              className="px-2 py-0.5 rounded bg-white/[0.08] hover:bg-white/[0.16] text-[10px] text-zinc-200 cursor-pointer whitespace-nowrap"
            >
              Extract Hunk
            </button>
          )}
        </div>
      </div>

      {diffLayout === 'unified' ? (
        /* UNIFIED SYNTAX-HIGHLIGHTED DIFF VIEW */
        <div className="py-1.5 overflow-x-auto">
          {parsedLines.map((line, lIdx) => {
            const isHdr = line.type === 'hunk_header';
            const isAdd = line.type === 'add';
            const isDel = line.type === 'del';

            return (
              <div
                key={lIdx}
                className={`px-3 py-0.5 flex items-baseline whitespace-pre leading-relaxed border-l-2 ${
                  isAdd
                    ? 'bg-emerald-500/[0.13] border-emerald-400/80'
                    : isDel
                    ? 'bg-rose-500/[0.14] border-rose-400/80'
                    : isHdr
                    ? 'bg-indigo-500/[0.12] border-indigo-400/70 text-indigo-300 py-1 my-0.5 font-medium'
                    : 'border-transparent'
                }`}
              >
                <span className="w-8 shrink-0 text-right pr-2 text-zinc-500 select-none tabular-nums text-[11px]">
                  {line.oldLineNumber ?? ''}
                </span>
                <span className="w-8 shrink-0 text-right pr-2.5 text-zinc-500 select-none tabular-nums text-[11px] border-r border-white/[0.06] mr-2.5">
                  {line.newLineNumber ?? ''}
                </span>
                <span
                  className={`w-4 shrink-0 select-none font-bold ${
                    isAdd
                      ? 'text-emerald-400'
                      : isDel
                      ? 'text-rose-400'
                      : 'text-zinc-500'
                  }`}
                >
                  {isAdd ? '+' : isDel ? '-' : isHdr ? '' : ' '}
                </span>
                <span className="min-w-0">
                  {isHdr ? (
                    <span className="text-indigo-300">{line.raw}</span>
                  ) : (
                    <HighlightedCodeLine
                      code={line.content}
                      language={hunk.language}
                    />
                  )}
                </span>
              </div>
            );
          })}
        </div>
      ) : (
        /* SPLIT SIDE-BY-SIDE SYNTAX-HIGHLIGHTED DIFF VIEW */
        <div className="grid grid-cols-2 divide-x divide-white/[0.08] overflow-x-auto">
          {/* Left: Base / Removed */}
          <div className="py-1.5 min-w-0 overflow-x-auto">
            <div className="px-3 py-1 text-[10px] text-zinc-500 border-b border-white/[0.05]">
              a/{hunk.filePath}
            </div>
            {oldSideLines.map((line, lIdx) => {
              const isHdr = line.type === 'hunk_header';
              const isDel = line.type === 'del';
              return (
                <div
                  key={lIdx}
                  className={`px-2.5 py-0.5 flex items-baseline whitespace-pre leading-relaxed border-l-2 ${
                    isDel
                      ? 'bg-rose-500/[0.14] border-rose-400/80'
                      : isHdr
                      ? 'bg-indigo-500/[0.12] border-indigo-400/70 text-indigo-300 py-1 my-0.5'
                      : 'border-transparent'
                  }`}
                >
                  <span className="w-7 shrink-0 text-right pr-2 text-zinc-600 select-none tabular-nums text-[10px] border-r border-white/[0.06] mr-2">
                    {line.oldLineNumber ?? ''}
                  </span>
                  <span className="w-3.5 shrink-0 select-none text-rose-400 font-bold">
                    {isDel ? '-' : ' '}
                  </span>
                  <span>
                    {isHdr ? (
                      <span className="text-indigo-300">{line.raw}</span>
                    ) : (
                      <HighlightedCodeLine
                        code={line.content}
                        language={hunk.language}
                      />
                    )}
                  </span>
                </div>
              );
            })}
          </div>

          {/* Right: Head / Added */}
          <div className="py-1.5 min-w-0 overflow-x-auto">
            <div className="px-3 py-1 text-[10px] text-zinc-500 border-b border-white/[0.05]">
              b/{hunk.filePath}
            </div>
            {newSideLines.map((line, lIdx) => {
              const isHdr = line.type === 'hunk_header';
              const isAdd = line.type === 'add';
              return (
                <div
                  key={lIdx}
                  className={`px-2.5 py-0.5 flex items-baseline whitespace-pre leading-relaxed border-l-2 ${
                    isAdd
                      ? 'bg-emerald-500/[0.13] border-emerald-400/80'
                      : isHdr
                      ? 'bg-indigo-500/[0.12] border-indigo-400/70 text-indigo-300 py-1 my-0.5'
                      : 'border-transparent'
                  }`}
                >
                  <span className="w-7 shrink-0 text-right pr-2 text-zinc-600 select-none tabular-nums text-[10px] border-r border-white/[0.06] mr-2">
                    {line.newLineNumber ?? ''}
                  </span>
                  <span className="w-3.5 shrink-0 select-none text-emerald-400 font-bold">
                    {isAdd ? '+' : ' '}
                  </span>
                  <span>
                    {isHdr ? (
                      <span className="text-indigo-300">{line.raw}</span>
                    ) : (
                      <HighlightedCodeLine
                        code={line.content}
                        language={hunk.language}
                      />
                    )}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};
