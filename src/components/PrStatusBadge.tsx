import React from 'react';
import { AtomicCommitUnit } from '../types/git';
import { resolvePrStatusBadgeMeta } from '../utils/atomicEngine';
import { FileEdit, GitMerge, GitPullRequest } from 'lucide-react';

interface PrStatusBadgeProps {
  status: AtomicCommitUnit['status'];
  prNumber?: number;
  size?: 'xs' | 'sm';
  className?: string;
}

export const PrStatusBadge: React.FC<PrStatusBadgeProps> = ({
  status,
  prNumber,
  size = 'xs',
  className = '',
}) => {
  const meta = resolvePrStatusBadgeMeta(status);

  const Icon =
    meta.statusKey === 'merged'
      ? GitMerge
      : meta.statusKey === 'open'
      ? GitPullRequest
      : FileEdit;

  const sizeStyles =
    size === 'sm'
      ? 'px-2.5 py-1 text-xs gap-1.5'
      : 'px-2 py-0.5 text-[10.5px] gap-1';

  return (
    <span
      data-status={meta.statusKey}
      className={`inline-flex items-center font-mono font-semibold rounded-full border shadow-2xs shrink-0 ${sizeStyles} ${meta.badgeBgClass} ${meta.badgeTextClass} ${meta.badgeBorderClass} ${className}`}
    >
      <span
        aria-hidden="true"
        className={`w-1.5 h-1.5 rounded-full ${meta.dotColorClass}`}
      />
      <Icon className="w-3 h-3 shrink-0" />
      <span>{meta.label}</span>
      {typeof prNumber === 'number' && (
        <span className="opacity-75">#{prNumber}</span>
      )}
    </span>
  );
};
