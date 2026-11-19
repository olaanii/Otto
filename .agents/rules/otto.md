---
description: Otto Atomic Git & Workflow Integration Rule for Antigravity
trigger: always_on
---

# Otto Atomic Git & Workflow Rules for Antigravity

This rule governs how Antigravity agents collaborate with **Otto**, the autonomous git stack and atomic commit slicing daemon.

---

## 1. Otto Daemon Architecture

- **Daemon Address**: Otto runs locally and listens on `http://localhost:3000`.
- **Purpose**: Otto continuously monitors working tree changes, AST diffs, and developer actions, automatically organizing uncommitted or staged work into clean, reviewable, stacked pull requests.
- **$0 Extra Token Cost Guarantee**: Otto harnesses Antigravity's active development session and utilizes deterministic local AST/diff slicing algorithms. No secondary external LLM calls or duplicate token overheads are incurred for workspace tracking or commit splitting.

---

## 2. Atomic Commit Slicing (<= 80 LOC)

Otto decomposes working changes according to strict atomic commit guardrails:

- **LOC Constraint**: Every atomic commit must contain **$\le$ 80 Lines of Code (LOC)** (additions + deletions combined), with a default cap of at most 3 related files per commit.
- **Single Responsibility**: Each commit unit must represent a single, coherent, compilable semantic change that can be reviewed independently.
- **Conventional Commits**: Every commit message must strictly adhere to the Conventional Commits specification:
  ```text
  <type>(<scope>): <short imperative summary>

  - <rationale bullet 1>
  - <rationale bullet 2>
  ```
  Permitted types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`.

---

## 3. Planning Document Isolation (`docs(plans)`)

Before writing any functional implementation code:

1. **Document First**: Isolate all architectural plans, design specifications, requirements breakdowns, and decision records in `docs/` or standalone `*.md` files.
2. **Dedicated Commit**: Stage and commit documentation plans separately under the Conventional Commit header:
   ```text
   docs(plans): <imperative summary of plan or architecture>
   ```
3. **Sequence**: Ensure the `docs(plans)` commit precedes implementation commits in the git history so reviewers can evaluate the intent and design before inspecting code diffs.

---

## 4. Coupling Unit Tests with Implementation

To maintain test coverage and verifiable diffs without breaking atomic constraints:

- **Direct Coupling**: Always couple unit tests directly with their corresponding implementation files in the same atomic commit unit whenever `impl.LOC + test.LOC <= 80 LOC`.
- **Co-location / Mirroring**: Place unit tests adjacent to implementation files (e.g., `foo.ts` and `foo.test.ts`, or `main.go` and `main_test.go`) or in the project's standard mirror directory structure.
- **Test Integrity**: Never commit untested code. If a complex test suite exceeds the 80 LOC threshold, split the implementation into smaller modular functions and couple the corresponding unit tests with each incremental slice.

---

## 5. Turn Notification Protocol (`POST /api/antigravity/events`)

When Antigravity completes a meaningful agent turn (e.g., finishes planning, generates an implementation, refactors a module, or completes a user request), notify Otto to refresh its stack and trigger atomic slicing:

### Endpoint
- **Method**: `POST`
- **URL**: `http://localhost:3000/api/antigravity/events`
- **Headers**: `Content-Type: application/json`

### Payload Schema
```json
{
  "id": "evt_1700000000000_abc123",
  "timestamp": "2026-11-19T10:00:00.000Z",
  "promptText": "User request or task summary performed by Antigravity",
  "sourceAgent": "antigravity",
  "category": "feature",
  "filesTouched": [
    "path/to/modified_file.ts",
    "path/to/modified_file.test.ts"
  ],
  "locDelta": "+42 -10",
  "agentAction": "turn_completed",
  "generatedCommitIds": []
}
```

### Event Categories
- `feature`: New business logic, components, or API endpoints.
- `bugfix`: Defect resolution and regression prevention.
- `plan`: Architecture notes, plans, and specifications in `docs/` or `*.md`.
- `refactor`: Structural or stylistic changes preserving external behavior.
- `brainstorm`: Exploratory research, spikes, or documentation.

> **Note**: Event dispatching is non-blocking and fail-safe. If the Otto daemon is temporarily stopped or unreachable, Antigravity proceeds without interrupting user execution.

---

## 6. Antigravity Agent Execution Checklist

Before concluding your task or turn:

- [ ] Are planning documents isolated into `docs(plans)` commits before code?
- [ ] Does each code commit adhere to the **<= 80 LOC** limit?
- [ ] Are unit tests coupled directly with their respective implementation files?
- [ ] Is Otto notified via `POST /api/antigravity/events` upon turn completion?
