# Plan: Agent Connection & Two-Way Confirmation Handshake Protocol

## Overview
Transform the AI agent connection from an immediate local boolean flip to an authentic two-way authorization handshake:
1. When "Connect" is initiated in Otto, generate a cryptographically valid handshake token and transition the agent to `awaiting_confirmation`.
2. Redirect the user to the agent confirmation interface (`http://localhost:3000/agents/authorize` + `antigravity://open?workspace=...`).
3. Display scope permissions, workspace path, and an explicit **"Authorize & Confirm Connection"** button.
4. Upon confirmation (`POST /api/agents/confirm`), verify the handshake token, update state to `connected: true` and `status: "watching_realtime"`, provision `.agents/rules/otto.md`, and notify Otto desktop via SSE.
5. In Flutter UI, show an active handshake dialog awaiting agent confirmation, transitioning automatically once approved.

## Endpoints
- `POST /api/agents/connect`: Initiates connection, returns `handshakeToken` and `authUrl`.
- `GET /agents/authorize`: Web/IDE interactive authorization screen with scope inspection.
- `POST /api/agents/confirm`: Approves connection, verifies token, sets agent to active.
- `POST /api/agents/cancel-handshake`: Cancels pending handshake.

## Slicing Plan (<= 80 LOC per commit)
1. `docs(plans)`: This document.
2. `feat(daemon)`: Handshake token generation and `GET /agents/authorize` handler.
3. `feat(daemon)`: `POST /api/agents/confirm` verification endpoint and unit tests.
4. `feat(ui)`: Flutter handshake dialog and pending state listener in `WindowsAgentConnector`.
5. `test(ui)`: Update widget tests to verify confirmation flow.
