# 02 — Goal-Framework Landscape (Classic OKRs and the Alternatives)

Each framework: origin, the OKR failure it reacts to, structure, and what it demands from
our product. The invariant across all of them: **a small number of priorities + a measure
+ a review rhythm.** No serious framework rejects that core.

## Why alternatives emerged

Classic OKRs (Grove → Doerr → Google) assume: teams can articulate measurable outcomes
quarterly; ambition-scored goals (0.7 = success) won't get gamed; cascading creates
alignment; quarterly contact with the goal is enough. Each alternative attacks one or
more of those assumptions.

---

## NCTs — Narratives, Commitments, Tasks

- **Origin:** Ravi Mehta (ex-CPO Tinder, ex-Facebook), ~2021–22. The most credible "OKR
  replacement" in product-org circles.
- **Reacts to:** fake measurability (teams mid-discovery can't honestly write metric KRs)
  and the accountability vacuum of "70% is fine" scoring.
- **Structure:**
  - **Narrative** — a qualitative *paragraph* (not one line): what we're doing this
    quarter and why it matters strategically. The reasoning lives here, not in a number.
  - **Commitments** — 3–5 objectively verifiable, **binary, committed** deliverables
    ("ship pricing A/B to 100% of traffic"). ~100% completion expected. Done or not done.
  - **Tasks** — working-level breakdown, explicitly *not* reviewed by leadership; lives
    in Jira/Linear.
- **Trade-off:** commitments are outputs. NCTs accept output-tracking in exchange for
  honesty and accountability, betting the Narrative keeps outputs tethered to outcomes.
- **Product demands:** rich-text narrative as a first-class field; binary (done/not-done)
  measures; review views that hide the task layer.

## FAST — Frequently discussed, Ambitious, Specific, Transparent

- **Origin:** Donald & Charles Sull, MIT Sloan Management Review, 2018.
- **Reacts to:** SMART/OKR practice optimizing for well-formed-at-creation while research
  shows **discussion frequency and transparency** predict performance, not goal-statement
  quality.
- **Structure:** not a data structure — four properties layered onto any goal shape.
- **Product demands:** transparency-by-default (everyone sees everyone's goals, incl. the
  CEO's; private goals are the rare exception); **discussion-recency as a health metric**
  ("not mentioned in 3 weeks" as prominent as "at 40%"). Our check-in loop *is* FAST
  operationalized.

## EOS Rocks + Scorecard (Entrepreneurial Operating System)

- **Origin:** Gino Wickman, *Traction* (2007). Dominant in SMBs (10–250 employees, often
  non-tech). Huge installed base; Ninety.io is an entire company serving only EOS.
- **Reacts to:** OKRs being too abstract and metric-demanding for small companies. Trades
  elegance for extreme prescriptiveness (exact meetings, exact agendas).
- **Structure:**
  - **Rocks** — 3–7 per person/team per **90 days**, binary done/not-done ("hire a sales
    manager"). Company → departmental → individual.
  - **Scorecard** — 5–15 **weekly leading-indicator numbers** with owners and thresholds,
    reviewed every week *regardless of Rocks*. A standing metrics ritual not attached to
    any goal — the structurally interesting object.
  - **Level 10 Meeting** — fixed 90-min weekly agenda: scorecard → rocks → issues (IDS:
    identify-discuss-solve).
  - **V/TO** above it all: 10-year target, 3-year picture, 1-year plan.
- **Product demands:** a **Scorecard** object (recurring metric rows, weekly expected
  values, red/green vs threshold, owner, 13-week trailing view) and a **meeting surface**
  (agenda view walking scorecard → rocks → issues). Table stakes for SMB; the natural
  consumer of metric connectors.

## 4DX — The 4 Disciplines of Execution

- **Origin:** McChesney/Covey (FranklinCovey), 2012. Ops-heavy orgs: retail, hospitality,
  healthcare, field sales.
- **Reacts to:** the "whirlwind" (day-job urgency) eating goals, and lag measures
  (revenue, NPS) being un-actionable week to week.
- **Structure:**
  - **WIG** (Wildly Important Goal) — one or two max, "from X to Y by when".
  - **Lead measures** — predictive of the lag *and* influenceable this week ("12
    discovery calls/wk" vs "revenue"). The framework's real contribution.
  - **Compelling scoreboard** — simple, visible, team-owned "are we winning right now".
  - **Cadence of accountability** — ≤30-min weekly: report commitments, review board,
    commit to next week.
- **Product demands:** explicit `role: lead | lag` on measures; lead measures declare
  which lag they hypothesize to drive; **hypothesis-health AI flag** ("lead green 8
  weeks, lag flat — hypothesis may be wrong" — nobody has built this well); lightweight
  weekly personal commitments attached to check-ins.

## V2MOM — Vision, Values, Methods, Obstacles, Measures

- **Origin:** Marc Benioff, Salesforce, 1999; still company-wide, internally public.
- **Reacts to:** OKRs dropping *why*, *what we won't compromise*, and *what might stop
  us*. Alignment mechanism: write yours after reading the level above's.
- **Structure:** Vision (what) / Values (trade-off arbiters) / Methods (actions ≈
  objectives) / Obstacles (named risks) / Measures (numbers, attached to methods).
- **Product demands:** goals-as-rich-document with embedded measures; **Obstacles** is
  worth stealing as a field for every framework — named risks that check-ins can
  reference ("obstacle #2 materialized").

## Hoshin Kanri (Policy Deployment)

- **Origin:** Japanese manufacturing (Toyota et al.), 1960s — the grandparent of
  cascading.
- **Structure:** 3–5yr breakthrough objectives → annual → cascaded via **catchball**
  (proposals down, feedback up, iterate to agreement — genuinely bidirectional) →
  **X-matrix** one-page visualization.
- **Product demands:** catchball as a negotiation *workflow* (draft → propose-up →
  feedback → agree, with state) rather than edit-in-place; multi-year → annual →
  quarterly nesting. Enterprise/v3+ territory, not core.

## North Star Metric + input-metric trees

- **Origin:** growth community (Sean Ellis lineage), formalized in Amplitude's *North
  Star Playbook*; same shape as Amazon's Weekly Business Review (controllable **input
  metrics** driving output metrics).
- **Reacts to:** quarterly goal-resets being artificial — the metric structure of the
  business doesn't change quarterly. Make the **metric tree permanent**; goals are just
  target-values pinned to nodes for a period.
- **Structure:** one North Star (value-exchange metric) decomposed into owned input
  metrics (breadth × depth × frequency × efficiency). Goal = "move node X from a to b by
  date."
- **Product demands:** the deepest architectural implication — see doc 03. If the core is
  a persistent metric graph with connectors, then OKRs, WIGs, scorecards, and North Star
  trees are all *views over the same graph*. Metrics permanent, goals ephemeral.

## Briefly

- **GIST** (Gilad): Goals / Ideas / Step-projects / Tasks — adds an evidence-ranked idea
  bank; more a PM planning system than a goal system.
- **Shape Up** (Basecamp): anti-framework — 6-week bets, fixed appetite, no metric
  targets. Reminder that some strong engineering cultures refuse metric goals; the
  linked-initiatives layer must tolerate teams that only track bets.
- **KPIs-only / scorecard-only:** a real post-OKR-fatigue position — run the business on
  ~15 standing health metrics, skip goal ceremony. The EOS scorecard object serves these
  users for free.

---

## Synthesis — the five axes

| Axis | Spread |
|---|---|
| Measure type | metric ("from X to Y") ↔ binary commitment (done/not) |
| Ambition contract | stretch, 70% ok (OKR) ↔ committed, 100% expected (NCT, Rocks) |
| Context richness | one-line objective ↔ full narrative doc (NCT, V2MOM) |
| Metric persistence | reset per cycle (OKR) ↔ standing metrics + pinned targets (North Star, Scorecard, WBR) |
| Alignment mechanism | tree cascade ↔ loose links ↔ negotiated catchball |

Framework-agnostic core: **Goal** (rich text, cycle-bound, `contract: committed |
aspirational`) → **Measures** (`kind: metric | binary`, `role: lead | lag`, optionally
bound to a persistent metric node) → **Check-ins** (value + confidence + note) →
free-form **alignment edges** → linked external **initiatives**. Terminology packs
("Objective/KR", "Rock/Scorecard", "Narrative/Commitment", "WIG/Lead measure") are
per-workspace templates that pre-configure flags and relabel the UI — roughly 15% of the
build, on one schema. Full schema in doc 03.

**Two market warnings** (expanded in doc 04):
1. "Supports every framework" sells worse than it builds. Tability won by being
   opinionated about check-ins; Ninety by being *only* EOS. Pick one framework community
   as the beachhead; the flexible schema is the expansion path, not the pitch.
2. Scorecard/metric-graph objects only earn their keep once connectors exist —
   manual-entry scorecards die exactly like manual-entry KRs.
