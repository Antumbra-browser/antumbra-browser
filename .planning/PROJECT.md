# Antumbra: GSD project context

> **Task-management reference for GSD only. Not authoritative project documentation.**
> Authoritative documents: [ARCHITECTURE.md](../ARCHITECTURE.md), [ROADMAP.md](../ROADMAP.md), [DECISIONS.md](../DECISIONS.md).
> When this file and any of those disagree, those files are correct and this file is stale.

---

Antumbra is a minimal-patch fork of Firefox ESR, maintained as an ordered patch series applied
to a pinned upstream tag. The project targets LibreWolf-level privacy, Zen-level design, and
onboarding simple enough for a non-technical user.

The upstream base is Firefox ESR 153 (`FIREFOX_153_3_0esr_RELEASE`), pinned in `upstream.conf`.

All architectural decisions are recorded in DECISIONS.md. All milestone scope and sequencing is
in ROADMAP.md. All implementation detail is in ARCHITECTURE.md.

GSD plans under `.planning/phases/` break down milestone checklist items into executable tasks.
They do not add, remove, or override milestone scope.

## Key constraints that affect every phase plan

- The Firefox source tree lives at `D:\dev\antumbra\firefox`, beside (not inside) this repo.
- `./mach build` takes roughly 47 minutes for a full build. Use `./mach build faster` (8 seconds)
  for frontend-only changes. Plans must state which build type verification requires.
- Patch output goes under `patches/` as numbered `.patch` files, not as direct edits to the
  Firefox tree.
- Every pref we set must exist in the upstream tree. `scripts/audit-prefs.py` checks this
  against `D:\dev\antumbra\firefox` and must pass before any phase is complete.
