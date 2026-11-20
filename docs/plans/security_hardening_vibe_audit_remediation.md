# Architectural Plan: Security Hardening & Vibe-Audit Remediation

## Objective
Remediate all vulnerabilities identified during the security audit against the `vibe-security-skill` specification:
1. **P0: Secret Hardening**: Remove hardcoded Clerk secret key fallback in `cmd/daemon/main.go`. Read from `CLERK_SECRET_KEY` env var; return 500 when unconfigured.
2. **P0: CORS Hardening**: Restrict CORS headers to authorized loopback origins (`localhost`, `127.0.0.1`, `tauri://localhost`, etc.) instead of wildcard `*`.
3. **P0: Network Interface Isolation**: Bind `http.ListenAndServe` explicitly to `127.0.0.1:3000` rather than `0.0.0.0:3000`.
4. **P0: Secret Scrubbing in REST & SSE**: Omit raw GitHub Personal Access Tokens and raw LLM API keys from `/api/state` responses and `/api/events` SSE broadcasts. Return safe boolean indicators (`hasToken`, `isConfigured`) and masked previews (`sk-...1234`).
5. **P1: Handshake Token Hardening**: Disallow empty tokens in `cmd/daemon/agent_handshake.go`. Require non-empty tokens and apply `subtle.ConstantTimeCompare`.
6. **P2: Subprocess Metacharacter Validation**: Validate directory paths in `cmd/daemon/agent_launcher.go` before invoking external processes.
7. **P2: In-Memory Rate Limiting**: Introduce a lightweight token-bucket rate limiter middleware on sensitive endpoints (`/api/git/commit`, `/api/llm/configure`, `/api/ai/refine-stack`).
8. **P3: JavaScript Context Injection**: Use `json.Marshal` for variables injected into `<script>` tags in `cmd/daemon/agent_auth_page.go`.

---

## Commit Slicing Strategy (<= 80 LOC per unit)
- **Slice 1**: `docs(plans): isolate security hardening and remediation plan`
- **Slice 2**: `fix(daemon): remove hardcoded secrets and isolate loopback binding`
- **Slice 3**: `fix(daemon): restrict CORS to loopback origins`
- **Slice 4**: `fix(daemon): scrub credentials from state JSON and SSE broadcasts`
- **Slice 5**: `fix(daemon): enforce non-empty constant-time handshake token checks`
- **Slice 6**: `fix(daemon): sanitize agent launcher paths and JS context escaping`
- **Slice 7**: `feat(daemon): add rate limiting middleware for sensitive endpoints`
- **Slice 8**: `test(daemon): add unit tests verifying security hardening constraints`
