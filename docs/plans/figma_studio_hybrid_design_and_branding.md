# Architecture Plan: Figma Studio Hybrid Design Implementation & Otto Branding

## Overview
This plan specifies the implementation of the official Figma design "5 · Studio — Recommended hybrid" (Node `211:249`, File Key `hz5s1mzWih4HClYVopwd5I`) in the Otto Flutter Windows desktop application, including the extraction and usage of the official Otto logo (Node `211:250`).

---

## 1. Top Title Bar Specification (Node `211:249`, height: 32px, bg: `#1B1B1B`, border: `#3A3A3A`)
- **Branding**:
  - Official Otto SVG/PNG logo asset placed at `left: 11px, top: 3px, width: 23px, height: 24px`.
- **Navigation Controls**:
  - Back (`Icon/back`) and Forward (`Icon/fwd`) buttons positioned at `47px` and `75px`.
- **Desktop Menus**:
  - `File`, `Edit`, `View`, `Help` text buttons (12px, white) with hover physics.
  - `File` menu provides shortcuts to "Open Repository..." (invoking native Windows folder picker), "Recent Projects", and "Exit".
- **Centered Command Search Box**:
  - Max width `420px`, height `24px`, background `#2B2B2B`, border `#3A3A3A`, border-radius `6px`.
  - Prefix search icon (14px, `#8A8A8A`), placeholder text "Search commits, diffs, stacks…", and keyboard shortcut chip "Ctrl+K".
  - Interactive: clicking triggers command search filter / palette.
- **Right Identity & Window Controls**:
  - Side panel toggle icon (`16px`, `#8A8A8A`).
  - Identity / Avatar circle with user initials (e.g., "OS" or connected Google/Clerk profile).
  - Native Windows 11 caption buttons (Min, Max, Close) with precise hover physics.

---

## 2. Left Icon Rail (Node `211:282`, width: 48px, bg: `#1B1B1B`, border-right: `#3A3A3A`)
- **Top Actions**:
  1. Stacks (`layers`) - Node `211:285`
  2. Diffs (`diff`) - Node `211:287`
  3. Branches (`branch`) - Node `211:289`
  4. AI Agents (`sparkle`) - Node `211:294`
  5. Rebase / Sync (`refresh`) - Node `211:296`
- **Active State Indicator**:
  - `#60CDFF` vertical pill (width `3px`, height `16px`, border-radius `2px`) on left edge.
  - Active button background: `#2B2B2B` with 8px corner radius.
- **Bottom Actions**:
  - Settings (`gear`) - Node `211:298`
  - Profile avatar - Node `211:300`

---

## 3. Asset Bundling & Executable Release
- Register `assets/images/` in `frontend_flutter/pubspec.yaml`.
- Bundle `otto_logo.png` and `otto_logo.svg`.
- Compile fresh release binary via `flutter build windows --release` to produce updated `otto_frontend.exe`.
