# 01 — Product Research

What a from-scratch org goal-tracking product should be in 2026, organized around the
documented failure modes of the last generation (including fluxday itself).

## 1. Design against the failure modes

Most OKR deployments and OKR tools die the same four deaths. Every core product decision
below traces back to one of these.

### F1. Set-and-forget
Goals are written in planning week and revisited at cycle end. The tool becomes a
graveyard; usage graphs show two spikes per quarter.
**Countermeasure:** the product's atomic unit is the *check-in*, not the goal. Everything
else (dashboards, rollups, reviews) derives from the check-in stream.

### F2. Manual metric updates
If a human must type "62%" every week, they stop within ~6 weeks. Manual-entry KRs are
the single biggest churn driver.
**Countermeasure:** measures bind to data sources (warehouse SQL, product analytics,
billing, issue trackers, spreadsheets) and update themselves. Manual entry is the
fallback, not the default.

### F3. Cascading theater
Rigid top-down trees (fluxday's `Okr#update_children` cascade is the archetype) produce
alignment *paperwork*: goals written to satisfy the parent node, not to describe real
work. Cross-team dependencies don't fit a tree at all.
**Countermeasure:** loose alignment — any goal can declare "contributes to" any other
goal, cross-team, many-to-many. Tree views are a rendering, not the storage model.

### F4. OKRs-as-performance-review
The moment goal attainment feeds compensation, people sandbag targets and the data
becomes fiction.
**Countermeasure:** keep scoring visibly decoupled from HR objects; no per-person
attainment leaderboards; make the ambitious/committed contract explicit per goal
(see doc 02) so a 60% on a stretch goal reads as healthy.

## 2. Core product decisions

### Check-in-first, not dashboard-first
The weekly check-in is: current value, **confidence** (on-track / at-risk / off-track or
1–10), and a one-line "why / what changed". Tability and Perdoo both converged here
independently; it is the strongest UX lesson of the 2016–2024 tool generation.

**Confidence over percentage.** A KR at 40% in week 3 with high confidence is healthy;
one at 80% with low confidence is a problem. Percent-complete alone hides both. Track and
chart confidence trend as prominently as value trend.

### Metric connectors are the moat
KRs/measures bind to: warehouse queries (Postgres/BigQuery/Snowflake), product analytics
(PostHog/GA/Amplitude), billing (Stripe MRR), issue trackers (Jira/Linear/GitHub),
spreadsheet cells, generic webhooks. This is what separates a real 2026 tool from a
glorified spreadsheet, and it is the prerequisite for the scorecard and metric-graph
objects (docs 02/03).

### Outcomes and work are linked, not merged
Do **not** rebuild a task tracker (fluxday's Task/WorkLog layer is the cautionary tale —
OKR apps that grow task systems become mediocre at both). Goals live here; work lives in
Jira/Linear/GitHub; a measure shows its linked initiatives and their live status via
integration.

### Flexible cadence, mutable goals
Quarterly default; support annual strategic objectives with quarterly or 6-week tactical
cycles beneath. Mid-cycle edits are allowed with an audit trail — goals *should* change
when you learn something; immutability is the old dogma.

### AI as the check-in engine, not a chatbot
Ranked by value:
1. **Goal-writing coach** — draft KRs from a fuzzy objective; lint "that's an output, not
   an outcome — measured how?"; enforce "from X to Y by date" shape.
2. **Auto-drafted check-ins** — from connected metric movement + linked-initiative
   activity, draft the weekly note for one-click confirm/edit.
3. **Health flags** — stale (no discussion in N weeks), sandbagged (hit 100% three cycles
   running), at-risk (confidence trending down), lead/lag hypothesis broken (see 4DX in
   doc 02).
4. **Exec digest** — the auto-written weekly rollup that replaces the status meeting deck.
An "ask questions about our goals" chat is the *least* valuable AI feature; ship it last.

## 3. Maximum-UX bets (concrete)

- **Live where people work.** Slack/Teams check-in prompts with inline reply. The web app
  is for planning and review; the weekly update must not require opening it.
- **One-screen team view**: this cycle's goals, confidence sparklines, last check-in note,
  days-since-update. This page *is* the Monday meeting — no drill-down needed to run it.
- **Progressive disclosure of hierarchy**: an IC sees their 1–3 goals and their team's;
  the org-tree view exists but is the CEO's screen, not the default.
- **Guardrails at creation time**: KR templates ("from X to Y by date"), outcome-vs-output
  linter, limit nudges (≥4 objectives per team → warning). Bad goals are an input-time UX
  problem.
- **Cycle-end ritual built in**: scoring flow with retro notes, and a forced
  carry-forward / archive / done decision per goal so nothing zombie-rolls into next
  quarter.
- **Staleness as a first-class signal** (FAST's core finding — see doc 02): "not discussed
  in 3 weeks" surfaces as prominently as "at 40%".

## 4. Build sequencing

1. **Discovery (1–2 wks):** interview 5–10 orgs that *abandoned* an OKR tool — churn
   reasons are the spec. Decide the beachhead (doc 04); this determines whether SSO/SCIM
   is v1 or v3.
2. **v1 — the loop:** goals + measures + weekly check-ins + confidence, Slack
   integration, the one-screen team page. Manual metrics only. Success gate: teams check
   in 8 consecutive weeks. That retention curve is the whole company.
3. **v2 — the moat:** metric connectors (spreadsheet + one warehouse + Jira/Linear
   first), AI check-in drafts + goal linting, exec digest.
4. **v3 — the sale:** framework templates (doc 02), org rollups, SSO/SCIM, public API.
