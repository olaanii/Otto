import React from 'react';
import { IdeHostId } from '../types/git';

export const AGENT_ICON_ASSETS: Record<
  IdeHostId,
  {
    src: string;
    label: string;
    shortName: string;
    cardTint: string;
    cursorPill: string;
  }
> = {
  antigravity: {
    src: '/assets/aistudio/Antigravity_1f40514c.png',
    label: 'Antigravity',
    shortName: 'Antigravity',
    cardTint: 'from-[#DBEAFE] via-[#E0E7FF] to-[#EDE9FE]',
    cursorPill: 'Moving to PR stack',
  },
  'claude-code': {
    src: '/assets/aistudio/Claude_Code_2_84c402da.png',
    label: 'Claude Code',
    shortName: 'Claude Code',
    cardTint: 'from-[#EDE9FE] via-[#F3E8FF] to-[#E0E7FF]',
    cursorPill: 'Slicing atomic commit',
  },
  'codex-cli': {
    src: '/assets/aistudio/Codex_fef5d503.png',
    label: 'Codex',
    shortName: 'Codex',
    cardTint: 'from-[#E4E9E2] via-[#EFECE6] to-[#F5EBE1]',
    cursorPill: 'Isolating test hunk',
  },
  cursor: {
    src: '/assets/aistudio/Cursor_fcce9ac1.png',
    label: 'Cursor',
    shortName: 'Cursor',
    cardTint: 'from-[#F3E8FF] via-[#EDE9FE] to-[#FCE7F3]',
    cursorPill: 'Splitting 2 scopes',
  },
  vscode: {
    src: '/assets/aistudio/VS_Code_e7c47e0d.png',
    label: 'VS Code',
    shortName: 'VS Code',
    cardTint: 'from-[#E0F2FE] via-[#DBEAFE] to-[#E0E7FF]',
    cursorPill: 'Staging clean diff',
  },
  windsurf: {
    src: '/assets/aistudio/Windsurf_a904a261.png',
    label: 'Windsurf',
    shortName: 'Windsurf',
    cardTint: 'from-[#CCFBF1] via-[#E0F2FE] to-[#EDE9FE]',
    cursorPill: 'Rebasing branch',
  },
  'gemini-cli': {
    src: '/assets/aistudio/Gemini_CLI_f1625b87.png',
    label: 'Gemini CLI',
    shortName: 'Gemini CLI',
    cardTint: 'from-[#E0E7FF] via-[#FCE7F3] to-[#FEF3C7]',
    cursorPill: 'Verifying LOC cap',
  },
  kiro: {
    src: '/assets/aistudio/Kiro_8ad630b7.png',
    label: 'Kiro',
    shortName: 'Kiro',
    cardTint: 'from-[#EDE9FE] via-[#DDD6FE] to-[#F3E8FF]',
    cursorPill: 'Syncing spec to PR',
  },
};

interface AgentIconProps {
  agentId: IdeHostId;
  sizeClass?: string;
  roundedClass?: string;
  className?: string;
}

/**
 * Renders the uploaded 256x302 agent PNG asset cropped cleanly to the icon artwork
 * in the top ~220px so the bottom gallery label ("256 x 256 · PNG") is completely excluded.
 */
export const AgentIcon: React.FC<AgentIconProps> = ({
  agentId,
  sizeClass = 'w-8 h-8',
  roundedClass = 'rounded-xl',
  className = '',
}) => {
  const meta = AGENT_ICON_ASSETS[agentId] || AGENT_ICON_ASSETS.antigravity;

  return (
    <span
      className={`inline-flex items-start justify-center overflow-hidden bg-white border border-black/[0.08] shadow-2xs shrink-0 select-none ${sizeClass} ${roundedClass} ${className}`}
    >
      <img
        src={meta.src}
        alt={meta.label}
        loading="eager"
        draggable={false}
        className="w-[116%] h-auto max-w-none -mt-[3%] block select-none pointer-events-none"
      />
    </span>
  );
};

export const OTTO_LOGO_SRC = '/assets/aistudio/image_3de77cda.png';

interface OttoLogoProps {
  sizeClass?: string;
  roundedClass?: string;
  gradientClass?: string;
  className?: string;
}

export const OttoLogo: React.FC<OttoLogoProps> = ({
  sizeClass = 'w-9 h-9',
  className = '',
}) => {
  return (
    <span
      className={`inline-flex items-center justify-center shrink-0 select-none bg-transparent ${sizeClass} ${className}`}
    >
      <img
        src={OTTO_LOGO_SRC}
        alt="Otto logo"
        loading="eager"
        draggable={false}
        className="w-full h-full object-contain block select-none pointer-events-none"
      />
    </span>
  );
};


