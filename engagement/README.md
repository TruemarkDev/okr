# engagement/

Per-engagement working area for the fluxday upgrade pilot (agency software-factory).
Client-facing delivery artifacts live here; reusable cross-client knowledge goes to the
agency brain (`shared-knowledge` gbrain), and work items go to `.beads/`.

- `roadmap.md` — the **Roadmap** audit deliverable (version-gap, gem compat, coverage
  gate, prioritized dual-estimated task list). Currently **draft-v0-static-pass** —
  finalizes to v1 once the app boots (Task 0).
- `task-briefs/` — per-task briefs handed to engineer agents.
- `task-logs/` — what each task actually did (append-only).
- `handoffs/` — session handoffs.

Pipeline: intake + coverage gate → **Roadmap** → dual-boot → incremental upgrade lanes
(one minor at a time) → load_defaults ramp → dual-CI verify → handoff/maintenance.
