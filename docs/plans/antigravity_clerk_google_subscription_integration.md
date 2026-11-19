# Architecture Plan: Google Antigravity Clerk OAuth & Pro Subscription Integration

## 1. Context & User Goal
The user requires connecting Google Antigravity not solely through manual standalone API keys, but directly via **Email / Google Sign-In with Clerk** linked to their **Google AI Pro Plan / Antigravity Subscription** (`olaaniishaambel@gmail.com`).
When signed in, Otto must:
1. Recognize the authenticated Google Antigravity Identity (`olaaniishaambel@gmail.com` - Olani Shambel).
2. Utilize the active Google AI Pro Antigravity subscription ($0 extra token fees, Gemini 3.8 Flash High) for automated atomic commit slicing, PR generation, and diff refining.
3. Eliminate any authentication handshake stalls or redirect failures by ensuring the RFC 8252 loopback handler directly authenticates the Clerk session and broadcasts `auth_success`.
4. Surface Google Antigravity as the primary configured AI provider in Settings and CommandBar.

## 2. Technical Implementation Architecture
### A. Backend Daemon (`cmd/daemon/`)
1. **Loopback OAuth & Clerk Verification**:
   - `/auth/callback`: Successfully parses Clerk user tokens and queries `https://api.clerk.com/v1/users` with the verified `CLERK_SECRET_KEY` (`sk_test_...`).
   - Maps Google OAuth external accounts, extracting `email_address` (`olaaniishaambel@gmail.com`), `first_name`, `last_name`, and avatar URL.
   - Sets `s.antigravity.Connected = true`, `s.antigravity.Model = "Gemini 3.8 Flash (High)"`, and sets `s.state.IdeProfiles[antigravity].Status = "watching_realtime"`.
   - Broadcasts `auth_success` and updates `state.json`.
2. **Subscription Provider Registration**:
   - `GET /api/llm/providers`: Includes `"antigravity"` as the primary provider with `isConfigured: true`, model `"Gemini 3.8 Flash (High)"`, plan `"Google AI Pro Plan"`, and `"tokenFee": "$0 extra token fees"`.
   - `POST /llm/commit-message`: Handles provider `antigravity`, generating conventional commits using the Antigravity session context.

### B. Flutter Desktop Frontend (`frontend_flutter/`)
1. **Settings Dialog**:
   - Add dedicated **"Antigravity Identity"** tab showcasing the connected Google AI Pro subscription, user email (`olaaniishaambel@gmail.com`), active plan badge, and 1-click "Connect with Google (Clerk)" button.
2. **Windows CommandBar**:
   - Display the Google Antigravity profile pill with Google icon, user avatar, and status.
   - Quick-select "Google Antigravity (Pro)" as the active LLM provider.
3. **Automated Commit Slicing & AI Refinement**:
   - Pass `antigravity` as the provider to daemon `/api/ai/refine-stack` and `/llm/commit-message`.

## 3. Atomic Slices (<= 80 LOC each)
- Slice 1: `docs(plans)` commit for architecture specification.
- Slice 2: `feat(daemon)` register Antigravity Pro provider and streamline Clerk OAuth callback.
- Slice 3: `feat(ui)` update SettingsDialog and CommandBar for Antigravity Pro Identity.
- Slice 4: `test` Go daemon and Flutter widget test validation.
