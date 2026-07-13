# 06 — EOS/Rocks Feature Set + LeaveBalanceApp Integration

Answers two questions raised after docs 01–05: (a) what does shipping EOS/Rocks support
actually consist of, and (b) should it live inside — or integrate with —
**LeaveBalanceApp** (`~/2026/leavebalance/LeaveBalanceApp`), the portfolio's Rails 8
multi-tenant HR-ops SaaS.

## A. What "EOS features" means concretely

EOS is more than Rocks. The tool-relevant objects, in priority order:

| # | Object | What it is | Status vs doc-03 schema |
|---|---|---|---|
| 1 | **Rocks** | 3–7 binary, committed, 90-day priorities per company/team/person | ✅ Already supported: `goals` with `contract=committed`, `measures.kind=binary`, 90-day `cycles` |
| 2 | **Scorecard** | 5–15 weekly leading-indicator numbers, owner + threshold, red/green, 13-week trailing | ✅ Already specced: `scorecards`/`scorecard_rows` over `metric_nodes` |
| 3 | **Weekly check-in / L10 meeting view** | Fixed agenda: scorecard → rock status → headlines → to-do review → **IDS** (identify-discuss-solve issues), 90 min | ⚠️ Partially: check-ins exist; the *meeting surface* (agenda walker) is new UI; **Issues list (IDS)** is a new object |
| 4 | **To-dos** | 7-day commitments made in the meeting, reviewed next week (done rate target ~90%) | ➕ New lightweight object (`todos`: owner, due ≤7d, source_meeting) — deliberately NOT a task tracker; they expire, they don't nest |
| 5 | **Issues list** | Standing backlog of obstacles/ideas, prioritized and IDS'd in meetings | ➕ New object (`issues`: title, raised_by, status open/solved/dropped, solved_in_meeting) — close cousin of doc-03 `obstacles`, but workspace/team-level, not goal-bound |
| 6 | **V/TO** (Vision/Traction Organizer) | Core values, 10-yr target, 3-yr picture, 1-yr plan, quarterly rocks on one page | ⚠️ A structured document; maps to nested `cycles` (annual ⊃ quarterly) + a rich-text vision doc. Fine as a template, low engineering cost |
| 7 | People/Accountability Chart, quarterly conversations | The HR-ish edges of EOS | ❌ Out of scope — this is where F4 (goals-as-reviews) contamination starts |

**Net new build beyond docs 01–03:** the meeting surface (one screen that walks
scorecard → rocks → to-dos → issues), plus two small tables (`todos`, `issues`). The
heavy objects (Rocks, Scorecard) were already in the schema — which is the point of the
framework-agnostic core.

### Trademark / naming caution (real, not theoretical)

"EOS" and the framework vocabulary are aggressively protected by EOS Worldwide —
**Traction Tools was forced to rebrand to Bloom Growth** over exactly this; Ninety.io
operates as an official partner. `[verify current EOS Worldwide software-partner terms]`
Implications:
- Do **not** market as "EOS software" without a partnership/license.
- Use generic vocabulary in product and marketing — "90-day priorities", "weekly
  scorecard", "leadership meeting" — and let admins rename labels. LeaveBalanceApp
  already has the exact mechanism for this: the **renamable org vocabulary** pattern
  (`account.team_label`-style `_label` helpers) — reuse it for `rock_label`,
  `scorecard_label`, `meeting_label`.
- This is another argument for the doc-02 stance: framework support as a template layer,
  not as branded "EOS mode".

## B. The LeaveBalanceApp question

### What LeaveBalanceApp actually is (from the code, 2026-07)

Bigger than "leave": a multi-tenant HR-ops platform — Account (tenant, with
subscriptions/billing) → Locations / Departments / Teams → Employees, plus attendance
devices + records, compliance rules/alerts, expenses, onboarding tasks, flexible-working
requests, **webhook_endpoints and api_keys already built**, a mature ViewComponent design
system (80+ components), renamable vocabulary, Rails 8 + Postgres. Its customers are
exactly EOS's demographic: SMBs, often non-tech.

That means it already owns the four hardest non-product assets a goals tool needs:
**tenanted org directory, auth/billing, an SMB customer base, and a design system.**

### Three integration paths

**Path A — Goals as a module inside LeaveBalanceApp** (a `Goals::`/`Traction::` section
in the same app, doc-03 tables added to its schema, scoped by `account_id`)

- ✅ Fastest possible distribution: ship to existing paying SMB tenants as a feature
  flag / add-on; discovery interviews become "turn it on for 5 friendly customers".
- ✅ Directly tests doc-05's **kill-criterion #1 (engagement)** with real orgs at near-zero
  CAC — this is the cheapest possible falsification of the whole thesis.
- ✅ Attendance data is an in-process metric source: scorecard rows like "unplanned
  absences this week", "attendance regularizations", "open compliance alerts" work on
  day one with no connector infra.
- ⚠️ F4 perception risk is *low but nonzero*: leave/attendance is HR-ops, not performance
  review — goals next to leave balances is not goals next to comp reviews. Keep rock
  attainment off anything payroll/compliance-adjacent.
- ❌ Couples the greenfield product to leavebalance's roadmap, brand, and monolith;
  standalone sale later requires extraction; the metric-connector moat (external
  warehouses/Stripe/Jira) is unnatural to build inside an HR app.

**Path B — Standalone goals app, LeaveBalanceApp as first-class integration**

- Directory sync (employees/teams/departments via its existing API + webhooks), SSO
  between the two, and **LeaveBalanceApp as a metric connector** (absence/attendance
  metrics as `metric_sources.kind=leavebalance`). Cross-sell bundle pricing.
- ✅ Keeps the doc-01/04/05 thesis intact (connectors moat, framework-agnostic,
  standalone company). ✅ LeaveBalanceApp becomes proof-connector #1 and warm-lead
  channel. ❌ Slowest to first real user; two products to run; the SMB buyer must adopt
  a second app.

**Path C — Module now, extraction-ready (A executed with B's schema discipline)**

- Build Path A, but as an **isolated Rails engine / namespaced tables**
  (`goals_*` tables, no FKs into leave tables except `account_id`/`employee_id`,
  metric access behind an adapter interface) so the doc-03 schema stays portable.
  Attendance metrics implemented *through* the `metric_sources` abstraction (kind:
  `internal_attendance`) rather than direct joins — so external connectors slot in
  later and extraction to standalone is a lift-out, not a rewrite.

### Recommendation: **Path C**

The single most valuable thing LeaveBalanceApp offers is not code reuse — it's **live SMB
tenants to test the engagement thesis against** (doc 05 says that assumption decides
everything, before any v2 spend). Path C buys that test at minimum cost while keeping the
standalone option open. Decision checkpoint after one 90-day cycle with pilot tenants:

- Engagement gate passes (≥50% of pilot teams sustain weekly check-ins for 8+ weeks) →
  decide *then* between "growth feature of leavebalance" (raises its ACV/retention;
  beachhead B from doc 04 via its customer base) and extraction to standalone (doc 04's
  option A/C path with a proven loop).
- Gate fails → doc-05 kill logic applies, and the sunk cost is one engine inside an app
  that keeps its day job.

### v1 module scope (inside LeaveBalanceApp, one 90-day pilot cycle)

1. **Rocks**: company + team + personal, 3–7 cap with nudge, binary, 90-day cycle
   aligned to `account_fiscal_years` quarters; owner = `Employee`.
2. **Scorecard**: manual rows + 2–3 built-in attendance/absence metrics via the adapter;
   weekly red/green, owner, 13-week trail.
3. **Weekly check-in**: rock status (on/off track + note) + scorecard fill, with email
   nudge (leavebalance has no Slack presence — email/in-app first, matching its
   existing notification patterns `[verify]`).
4. **Meeting view**: one screen walking scorecard → rocks → to-dos → issues; to-dos and
   issues as the two new lightweight tables.
5. **Vocabulary**: all labels via the `_label` renamable pattern; no EOS branding.
6. Built with existing `Ui::`/`Forms::` ViewComponents; UI effort is mostly the meeting
   view and scorecard grid.

Explicitly deferred: V/TO document, external connectors, AI drafting (the pilot tests
*behavior*, not the moat), org-chart cascades.

## Doc-04/05 updates this implies

- Beachhead: Path C effectively runs **option B (EOS-shaped SMB)** as the *test* while
  deferring the A-vs-C standalone decision — with distribution we own, which was option
  B's missing piece (we no longer need the EOS Implementer channel to reach the
  demographic; we sidestep the licensing issue by staying generic).
- Viability: pilot cost drops the discovery phase from "build v1 + acquire testers" to
  "build an engine + flag it on for existing tenants".
