import React, { useState, useRef, useEffect } from 'react';
import { Check, Copy, ExternalLink, Key, Lock, LogIn, LogOut, ShieldCheck, User } from 'lucide-react';

export interface ClerkUserProfile {
  id: string;
  fullName: string;
  email: string;
  avatarUrl: string;
  role: string;
  organization: string;
  sessionToken: string;
  tokenExpires: string;
}

export const DEFAULT_CLERK_USER: ClerkUserProfile = {
  id: 'user_2sP91x0kK7Lq8Z2',
  fullName: 'Alex Vance',
  email: 'alex@otto.dev',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=128&auto=format&fit=crop&q=80',
  role: 'Staff Engineer',
  organization: 'Otto Systems Inc.',
  sessionToken: 'clerk_live_eyJhbGciOiJSUzI1NiIsImtpZCI6Imluc18ya3...98f4c2',
  tokenExpires: 'In 7 days (JWT RS256)',
};

interface ClerkUserPillProps {
  user?: ClerkUserProfile | null;
  onSignIn: () => void;
  onSignOut: () => void;
  onCopyToken?: () => void;
}

export const ClerkUserPill: React.FC<ClerkUserPillProps> = ({
  user = DEFAULT_CLERK_USER,
  onSignIn,
  onSignOut,
  onCopyToken,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const popoverRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (popoverRef.current && !popoverRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  const handleCopy = () => {
    if (user?.sessionToken) {
      navigator.clipboard.writeText(user.sessionToken);
      setCopied(true);
      if (onCopyToken) onCopyToken();
      setTimeout(() => setCopied(false), 2000);
    }
  };

  if (!user) {
    return (
      <button
        type="button"
        onClick={onSignIn}
        className="inline-flex items-center gap-2 px-3.5 py-1.5 text-[12.5px] font-medium text-zinc-700 bg-white/90 hover:bg-white hover:text-zinc-950 border border-black/[0.08] rounded-full shadow-xs transition-all cursor-pointer group"
      >
        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
        <Lock className="w-3.5 h-3.5 text-zinc-400 group-hover:text-indigo-600 transition-colors" />
        <span>Sign In</span>
      </button>
    );
  }

  return (
    <div className="relative inline-block" ref={popoverRef}>
      {/* Navbar User Pill */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="inline-flex items-center gap-2 pl-1 pr-3 py-1 text-[12.5px] font-medium text-zinc-800 bg-white/90 hover:bg-white border border-black/[0.08] hover:border-black/[0.14] rounded-full shadow-xs transition-all cursor-pointer group"
        title="Clerk Authentication & Session Profile"
      >
        <img
          src={user.avatarUrl}
          alt={user.fullName}
          className="w-5 h-5 rounded-full object-cover ring-1 ring-black/10"
        />
        <span className="max-w-[85px] sm:max-w-[110px] truncate">{user.fullName}</span>
        <span className="inline-flex items-center px-1.5 py-0.5 rounded-full text-[9.5px] font-mono font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60">
          Clerk
        </span>
      </button>

      {/* Popover Dropdown */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-80 bg-white/98 backdrop-blur-xl border border-black/[0.08] rounded-2xl shadow-2xl p-4 z-50 animate-in fade-in zoom-in-95 duration-150 text-zinc-900">
          {/* Header */}
          <div className="flex items-center justify-between pb-3 border-b border-black/[0.06]">
            <div className="flex items-center gap-2.5">
              <img
                src={user.avatarUrl}
                alt={user.fullName}
                className="w-9 h-9 rounded-full object-cover ring-2 ring-indigo-500/20"
              />
              <div>
                <div className="text-[13px] font-semibold text-zinc-900 leading-tight">
                  {user.fullName}
                </div>
                <div className="text-[11px] text-zinc-500 font-mono truncate max-w-[160px]">
                  {user.email}
                </div>
              </div>
            </div>
            <span className="inline-flex items-center gap-1 text-[10px] font-medium text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-full px-2 py-0.5">
              <ShieldCheck className="w-3 h-3 text-emerald-600" />
              Verified
            </span>
          </div>

          {/* Org & Role */}
          <div className="py-2.5 space-y-1 text-[11px] text-zinc-600">
            <div className="flex justify-between">
              <span className="text-zinc-400">Organization:</span>
              <span className="font-medium text-zinc-800">{user.organization}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-zinc-400">Role:</span>
              <span className="font-medium text-zinc-800">{user.role}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-zinc-400">Security Model:</span>
              <span className="font-medium text-indigo-600">Clerk RS256 JWT</span>
            </div>
          </div>

          {/* Token Copy Section for IDE Extension */}
          <div className="pt-2 pb-3 border-t border-black/[0.06] space-y-1.5">
            <div className="flex items-center justify-between text-[11px]">
              <span className="font-semibold text-zinc-700 flex items-center gap-1">
                <Key className="w-3 h-3 text-indigo-500" />
                IDE Extension Token
              </span>
              <span className="text-[10px] text-zinc-400 font-mono">{user.tokenExpires}</span>
            </div>
            <div className="flex items-center gap-1.5 bg-zinc-50 border border-zinc-200/80 rounded-lg p-1.5">
              <input
                type="text"
                readOnly
                value={user.sessionToken}
                className="w-full bg-transparent font-mono text-[10.5px] text-zinc-600 focus:outline-hidden select-all"
              />
              <button
                type="button"
                onClick={handleCopy}
                className="p-1 rounded-md bg-white hover:bg-zinc-100 border border-zinc-200 text-zinc-700 hover:text-zinc-900 transition-colors shrink-0 cursor-pointer"
                title="Copy token to paste into VS Code/Cursor/Windsurf extension"
              >
                {copied ? (
                  <Check className="w-3.5 h-3.5 text-emerald-600" />
                ) : (
                  <Copy className="w-3.5 h-3.5" />
                )}
              </button>
            </div>
            <p className="text-[10px] text-zinc-400 leading-tight">
              Paste into your IDE extension settings (<code className="text-zinc-600">otto.clerkToken</code>) to link this session.
            </p>
          </div>

          {/* Sign Out CTA */}
          <div className="pt-2 border-t border-black/[0.06] flex items-center justify-between">
            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                onSignOut();
              }}
              className="inline-flex items-center gap-1.5 text-[11.5px] font-medium text-red-600 hover:text-red-700 hover:bg-red-50/50 px-2 py-1 rounded-md transition-colors cursor-pointer"
            >
              <LogOut className="w-3 h-3" />
              Sign Out
            </button>
            <span className="text-[10px] text-zinc-400">Otto Security Engine</span>
          </div>
        </div>
      )}
    </div>
  );
};
