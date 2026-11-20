import React, { useState, useRef, useEffect } from 'react';
import { Check, Copy, Key, Lock, LogOut, ShieldCheck, Sparkles } from 'lucide-react';

export interface ClerkUserProfile {
  id: string;
  fullName: string;
  email: string;
  avatarUrl: string;
  role: string;
  organization: string;
  sessionToken?: string;
  tokenExpires?: string;
  authProvider?: 'clerk' | 'google' | string;
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
  authProvider: 'clerk',
};

export const GOOGLE_USER_PROFILE: ClerkUserProfile = {
  id: 'user_google_oauth',
  fullName: 'Google User',
  email: 'user@gmail.com',
  avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=128&auto=format&fit=crop&q=80',
  role: 'Developer',
  organization: 'Workspace',
  authProvider: 'google',
  sessionToken: '',
  tokenExpires: '',
};

export const isGoogleUser = (user?: ClerkUserProfile | null): boolean =>
  user?.authProvider === 'google';

export const GoogleGIcon: React.FC<{ className?: string }> = ({ className = 'w-3.5 h-3.5' }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path
      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
      fill="#4285F4"
    />
    <path
      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      fill="#34A853"
    />
    <path
      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
      fill="#FBBC05"
    />
    <path
      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
      fill="#EA4335"
    />
  </svg>
);

export interface ClerkUserPillProps {
  user?: ClerkUserProfile | null;
  onSignIn: () => void;
  onGoogleSignIn?: () => void;
  onSignOut: () => void;
  onCopyToken?: () => void;
}

export const ClerkUserPill: React.FC<ClerkUserPillProps> = ({
  user = DEFAULT_CLERK_USER,
  onSignIn,
  onGoogleSignIn,
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

  const isGoogle = isGoogleUser(user);

  if (!user) {
    return (
      <div className="relative inline-block" ref={popoverRef}>
        <button
          type="button"
          onClick={() => setIsOpen(!isOpen)}
          aria-expanded={isOpen}
          aria-haspopup="true"
          className="inline-flex items-center gap-2 px-3.5 py-1.5 text-[12.5px] font-medium text-zinc-700 bg-white/90 hover:bg-white hover:text-zinc-950 border border-black/[0.08] hover:border-black/[0.14] rounded-full shadow-xs transition-all cursor-pointer group"
        >
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          <Lock className="w-3.5 h-3.5 text-zinc-400 group-hover:text-indigo-600 transition-colors" />
          <span>Sign In</span>
        </button>

        {isOpen && (
          <div className="absolute right-0 mt-2 w-80 bg-white/98 backdrop-blur-xl border border-black/[0.08] rounded-2xl shadow-2xl p-4 z-50 animate-in fade-in zoom-in-95 duration-150 text-zinc-900">
            <div className="pb-3 border-b border-black/[0.06]">
              <div className="text-[13px] font-semibold text-zinc-900 leading-tight">
                Authentication
              </div>
              <div className="text-[11px] text-zinc-500 mt-0.5">
                Connect your account to sync Otto workspaces &amp; IDE extensions.
              </div>
            </div>

            <div className="py-3 space-y-2">
              {/* Google Sign-In Option */}
              <button
                type="button"
                onClick={() => {
                  setIsOpen(false);
                  if (onGoogleSignIn) {
                    onGoogleSignIn();
                  } else {
                    onSignIn();
                  }
                }}
                className="w-full flex items-center justify-between p-2.5 rounded-xl border border-zinc-200/90 bg-white hover:bg-zinc-50/90 shadow-2xs hover:shadow-xs transition-all cursor-pointer group text-left"
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-7 h-7 rounded-lg bg-zinc-50 border border-black/[0.06] flex items-center justify-center shrink-0">
                    <GoogleGIcon className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-[12.5px] font-semibold text-zinc-900">
                      Continue with Google
                    </div>
                    <div className="text-[10.5px] text-zinc-500">
                      Olani Shambel · Antigravity
                    </div>
                  </div>
                </div>
                <span className="text-[9.5px] font-medium text-blue-700 bg-blue-50 border border-blue-200/70 rounded-full px-2 py-0.5 shrink-0">
                  Google
                </span>
              </button>

              {/* Clerk Sign-In Option */}
              <button
                type="button"
                onClick={() => {
                  setIsOpen(false);
                  onSignIn();
                }}
                className="w-full flex items-center justify-between p-2.5 rounded-xl border border-zinc-200/70 bg-zinc-50/60 hover:bg-zinc-100/70 shadow-2xs hover:shadow-xs transition-all cursor-pointer group text-left"
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-7 h-7 rounded-lg bg-white border border-black/[0.06] flex items-center justify-center shrink-0">
                    <Lock className="w-3.5 h-3.5 text-zinc-600 group-hover:text-indigo-600 transition-colors" />
                  </div>
                  <div>
                    <div className="text-[12.5px] font-semibold text-zinc-900">
                      Continue with Clerk
                    </div>
                    <div className="text-[10.5px] text-zinc-500">
                      Alex Vance · RS256 JWT
                    </div>
                  </div>
                </div>
                <span className="text-[9.5px] font-mono text-zinc-600 bg-zinc-100 border border-zinc-200/70 rounded-full px-1.5 py-0.5 shrink-0">
                  Clerk
                </span>
              </button>
            </div>

            <div className="pt-2 border-t border-black/[0.06] flex items-center justify-between text-[10px] text-zinc-400">
              <span>Otto Security Engine</span>
              <span>OAuth2 · PKCE · RS256</span>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="relative inline-block" ref={popoverRef}>
      {/* Navbar User Pill */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        aria-haspopup="true"
        className="inline-flex items-center gap-2 pl-1 pr-3 py-1 text-[12.5px] font-medium text-zinc-800 bg-white/90 hover:bg-white border border-black/[0.08] hover:border-black/[0.14] rounded-full shadow-xs transition-all cursor-pointer group"
        title={isGoogle ? 'Google Antigravity Connected' : 'Clerk Authentication & Session Profile'}
      >
        <img
          src={user.avatarUrl}
          alt={user.fullName}
          className="w-5 h-5 rounded-full object-cover ring-1 ring-black/10"
        />
        <span className="max-w-[85px] sm:max-w-[110px] truncate">{user.fullName}</span>
        {isGoogle ? (
          <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[9.5px] font-medium bg-blue-50 text-blue-700 border border-blue-200/60">
            <GoogleGIcon className="w-2.5 h-2.5" />
            Google
          </span>
        ) : (
          <span className="inline-flex items-center px-1.5 py-0.5 rounded-full text-[9.5px] font-mono font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60">
            Clerk
          </span>
        )}
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
                className={`w-9 h-9 rounded-full object-cover ring-2 ${
                  isGoogle ? 'ring-blue-500/20' : 'ring-indigo-500/20'
                }`}
              />
              <div>
                <div className="text-[13px] font-semibold text-zinc-900 leading-tight">
                  {user.fullName}
                </div>
                <div className="text-[11px] text-zinc-500 font-mono truncate max-w-[155px]">
                  {user.email}
                </div>
              </div>
            </div>
            {isGoogle ? (
              <span className="inline-flex items-center gap-1 text-[10px] font-medium text-blue-700 bg-blue-50 border border-blue-200 rounded-full px-2 py-0.5">
                <GoogleGIcon className="w-3 h-3" />
                Google
              </span>
            ) : (
              <span className="inline-flex items-center gap-1 text-[10px] font-medium text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-full px-2 py-0.5">
                <ShieldCheck className="w-3 h-3 text-emerald-600" />
                Verified
              </span>
            )}
          </div>

          {/* Indicator showing "Google Antigravity Connected" */}
          {isGoogle && (
            <div className="mt-2.5 flex items-center justify-between px-2.5 py-1.5 rounded-lg bg-emerald-50/80 border border-emerald-200/70 text-[11px] text-emerald-900 font-medium">
              <div className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <Sparkles className="w-3 h-3 text-emerald-600" />
                <span>Google Antigravity Connected</span>
              </div>
              <span className="text-[9.5px] font-mono text-emerald-700 bg-white/80 px-1.5 py-0.5 rounded border border-emerald-200/60">
                ACTIVE
              </span>
            </div>
          )}

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
              <span className="font-medium text-indigo-600">
                {isGoogle ? 'Google OAuth2 · Antigravity' : 'Clerk RS256 JWT'}
              </span>
            </div>
          </div>

          {/* Token Copy Section for IDE Extension */}
          {user.sessionToken && (
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
                Paste into your IDE extension settings (<code className="text-zinc-600">{isGoogle ? 'otto.googleToken' : 'otto.clerkToken'}</code>) to link this session.
              </p>
            </div>
          )}

          {/* Provider Switch CTA */}
          <div className="pt-2 border-t border-black/[0.06] space-y-2">
            {isGoogle ? (
              <button
                type="button"
                onClick={() => {
                  setIsOpen(false);
                  onSignIn();
                }}
                className="w-full flex items-center justify-center gap-1.5 px-2.5 py-1.5 text-[11px] font-medium text-zinc-700 bg-zinc-50 hover:bg-zinc-100 border border-zinc-200 rounded-lg transition-colors cursor-pointer"
              >
                <Lock className="w-3 h-3 text-zinc-500" />
                <span>Switch to Clerk session</span>
              </button>
            ) : (
              <button
                type="button"
                onClick={() => {
                  setIsOpen(false);
                  if (onGoogleSignIn) {
                    onGoogleSignIn();
                  }
                }}
                className="w-full flex items-center justify-center gap-1.5 px-2.5 py-1.5 text-[11px] font-medium text-zinc-700 bg-zinc-50 hover:bg-zinc-100 border border-zinc-200 rounded-lg transition-colors cursor-pointer"
              >
                <GoogleGIcon className="w-3 h-3" />
                <span>Switch to Google account</span>
              </button>
            )}

            {/* Sign Out CTA */}
            <div className="flex items-center justify-between pt-1">
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
        </div>
      )}
    </div>
  );
};
