# Production-Ready Desktop OAuth & Authentication Architecture for Otto

## 1. Problem Statement & Root Cause
Previous iterations contained:
1. Hardcoded identity strings and environment fallbacks (`olaaniishaambal@gmail.com`) that automatically pre-populated the sign-in screen with a fake pre-connected card.
2. `detectUserIdentity()` in `cmd/daemon/main.go` that scraped the local workstation's `git config user.email` and OS usernames, creating an unwanted persistent identity.
3. A simulated 1-click button that bypasses real OAuth consent, failing to open the system browser or OAuth popup.

## 2. Production Architecture (Industry Standard: VS Code / Antigravity / GitHub Desktop)

### 2.1 RFC 8252 Loopback OAuth Flow
Modern desktop IDEs (VS Code, Google Antigravity, JetBrains, GitHub CLI) follow the **OAuth 2.0 for Native Apps (RFC 8252)** standard:
1. **Zero Hardcoded Identities**: The app starts in a clean, unauthenticated state with zero pre-filled accounts or hidden connections.
2. **System Browser Launch**: When the user clicks "Sign in with Google" or "Sign in with GitHub":
   - The desktop app instructs the native Go daemon to prepare an OAuth state token.
   - The desktop app opens the user's default browser (Chrome, Edge, Firefox) using the native OS browser launcher.
   - The browser navigates directly to the OAuth authorization endpoint (Clerk Social OAuth or Google OAuth 2.0).
3. **Browser Consent**: The user interacts with Google's real authentication UI in their browser, supporting multi-factor authentication, security keys, passkeys, and account switching.
4. **Loopback Callback (`http://localhost:3000/auth/callback`)**:
   - The provider redirects back to the Otto daemon listening locally at `http://127.0.0.1:3000/auth/callback`.
   - The daemon validates the authorization code/JWT against Clerk/Google verification keys.
   - The browser displays a clean "Authentication Successful — You may close this tab and return to Otto" page.
5. **Real-Time Notification & Workspace Activation**:
   - The daemon emits an `auth_success` event via the local SSE stream.
   - The Flutter client transitions into the workspace shell with the real user profile.
   - Secure token storage via Windows DPAPI / Windows Credential Manager (`flutter_secure_storage`).

## 3. Immediate Purge of Residual User Data
- Complete removal of `olaaniishaambal@gmail.com` across all source files, fallbacks, and tests.
- Complete removal of `detectUserIdentity()` scraping logic from `cmd/daemon/main.go`.
- Reset of `.data/atomik-state.json` to `user: null`, `connected: false`.
