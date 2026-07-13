---
title: fluxday — Upgrade Proposal
type: proposal
client: fluxday (Foradian OSS OKR / task tracker)
prepared: 2026-07-07
based_on: engagement/roadmap.md (v0 static-pass) + engagement/coverage-gate.md (Phase A)
pricing_basis: provisional range (v0 Roadmap — fixed price follows the v1 Roadmap after Task 0)
blended_day_rate: $<RATE>/day — illustrative math below uses $1,200/day; swap for your rate
---

# Upgrade Proposal — fluxday

## 1. The outcome

A **secure, actively-supported Rails 8 stack you can hire for and build on** — with a real
test safety net underneath it. Today fluxday runs on **Rails 4.1 and Ruby 2.3, both years past
end-of-life** (unpatched interpreter CVEs, a known OmniAuth CSRF advisory, six unsupported
Rails majors) and, critically, has **no working test coverage** — so nothing today can prove a
change didn't break it. This engagement fixes both, in shippable phases, keeping the app
running the entire way.

## 2. Where you are today

From the attached Roadmap (`roadmap.md`) and coverage audit (`coverage-gate.md`):

- **6 majors / ~10 minor versions behind** — Rails 4.1.16 → 8.0 — on an **EOL Ruby 2.3**.
- **The app does not boot on modern hardware** (Ruby 2.3 + `therubyracer` won't build) — the
  first, blocking task.
- **Test coverage is effectively 0%.** The 41 test files are Rails scaffold stubs with no real
  assertions, and the few that assert are auth-/fixture-broken. There is **no behavioral safety
  net** — the single biggest risk to any upgrade.
- **Auth is the hotspot** — devise 3.5, a doorkeeper 1.1 OAuth *server*, OmniAuth <2.0 (CSRF),
  and a git-sourced `omniauth-fluxapp` strategy all cluster in the highest-blast-radius code.

## 3. Scope of work

**In scope** — the Roadmap §7 task list, grouped into three phases (§5).

**Out of scope** (separate estimates if wanted)
- New features, UI/UX redesign, or behavior changes.
- Replacing the PDF engine (`wkhtmltopdf`) — we *evaluate and recommend*; swapping it is its own project.
- ActiveStorage migration off CarrierWave (optional; deferred).
- Data migrations, infra/hosting/deploy changes beyond standing up dual-CI.
- Performance work beyond what an upgrade requires.

**Assumptions**
- Repo + CI access, and a staging DB dump / working seeds.
- Task 0 (Dockerized boot) is achievable within its 1–3 day budget.
- The git-sourced `omniauth-fluxapp` source stays reachable to vendor + pin.
- Google OAuth test credentials available for the auth-path tests.
- ≥60% coverage is reachable on this codebase; client review turnaround ≤ 3 business days.

## 4. Approach

Coverage gate → dual-boot (`Gemfile.next`) → **one minor at a time** → `load_defaults` ramp →
dual-CI verify. Old and new Rails run **side-by-side** the whole way, so **the app is always
shippable** — no big-bang cutover, no long-lived broken branch.

## 5. Phases, milestones & price

Estimates are **inherited from the Roadmap** (dual best/worst engineer-days), with the coverage
line revised per the coverage audit. Because they rest on a **v0 (static-pass) Roadmap**, prices
are a **provisional range**; a **fixed** number follows the **v1 Roadmap** once the app boots and
real coverage is measured (Phase 0 itself produces that). Dollar figures are **illustrative at
$1,200/day** — set your blended rate to finalize.

| Phase | Scope (Roadmap tasks) | Acceptance | Eng-days (best/worst) | Illustrative price |
|---|---|---|---|---|
| **0 — Foundation & safety net** | Task 0 boot (Docker, drop therubyracer) · Task 1 coverage gate (sign-in harness + fixtures, backfill ~0%→≥60%, auth/RBAC first) · Task 2 dual-boot scaffold | App boots in Docker; suite green at **≥60%** coverage; dual-CI running | **7 / 17** | **$8.4k – $20.4k** |
| **1 — Climb to Rails 6.1** | Tasks 3–7 (4.1→4.2→5.0→5.1→5.2→6.0→6.1) incl. Zeitwerk + Ruby→2.7 + gem cluster (mysql2/devise/cancancan/ransack) · Task 10 doorkeeper 1.1→5.x OAuth migration | Dual-CI green on **6.1**; OAuth server on doorkeeper 5.x | **10.5 / 21** | **$12.6k – $25.2k** |
| **2 — Reach supported Rails 8.0** | Tasks 8–9 (6.1→7.0→7.1→7.2→8.0) incl. asset pipeline (sprockets→Propshaft, turbolinks→turbo) + Ruby→3.3 · Task 11 dependency tail · Task 12 verify + handoff | Dual-CI green on **8.0**; Zeitwerk/Propshaft done; dual-CI removed; handoff docs | **9 / 18** | **$10.8k – $21.6k** |
| | **Total** | | **26.5 / 56** | **≈ $31.8k – $67.2k** |

> **Phase 0 is the real de-risking and is non-negotiable.** Clients under-value "get it booting
> + test coverage," but with **0% coverage today** it is the work that makes every later phase
> safe. We recommend contracting **Phase 0 first**, then finalizing Phases 1–2 to *fixed* prices
> off the v1 Roadmap that Phase 0 produces.

**Optional parallel wedge — Security audit** (brakeman + bundler-audit + ruby_audit +
bundler-leak): **2 / 3 eng-days**, ~**$2.4k – $3.6k**, sellable standalone and runnable now.

## 6. Timeline

Phases are **sequential** (each hop depends on the last). At ~1 engineer:

- **Phase 0:** ~1.5–3.5 weeks — and it unblocks the fixed-price quote for the rest.
- **Phase 1:** ~2–4.5 weeks.
- **Phase 2:** ~2–4 weeks.
- **End to end:** roughly **6–12 weeks**, matching the ~26.5–56 eng-day range.

## 7. Terms

- **Payment:** deposit to start Phase 0; balance **per phase on milestone acceptance** (dual-CI green).
- **Change requests:** anything in §3 "out of scope" is a separate estimate — no silent scope creep.
- **Handoff:** upgrade log, updated engagement docs, dual-CI removed, and a **Maintenance
  retainer** option (dependency health + deprecations + debt paydown) offered at close.
- **Confidentiality:** NDA on request (`pm-toolkit` draft-nda).

## Appendix

Attached technical basis:
- `engagement/roadmap.md` — full version-gap audit, gem-compat inventory, task list (v0 static pass).
- `engagement/coverage-gate.md` — coverage audit (gate 🔴, ~0% asserting; the Phase-0 estimate driver).
