# 03 — Framework-Agnostic Data Model

The schema that makes doc 02's synthesis concrete. Design inversion vs fluxday and the
2016 generation: **metrics are permanent, goals are ephemeral targets pinned to them.**

## Entity overview

```
Workspace ── FrameworkTemplate (terminology pack + defaults)
   │
   ├─ MetricNode ◄── MetricEdge (the persistent metric graph)
   │     └─ MetricSource (connector binding) ──► MetricPoint (time series)
   │
   ├─ Cycle (annual / quarterly / 6-week, nestable)
   │
   ├─ Goal (cycle-bound, team- or person-owned, rich-text body)
   │     ├─ Measure  (kind: metric|binary, role: lead|lag, → MetricNode?)
   │     │     └─ CheckIn (value, confidence, note, author, at)
   │     ├─ Obstacle (named risk; check-ins can reference)
   │     ├─ AlignmentEdge (goal →contributes_to→ goal, cross-team, many-to-many)
   │     └─ InitiativeLink (→ external Jira/Linear/GitHub item, live status)
   │
   ├─ Scorecard ── ScorecardRow (→ MetricNode, weekly threshold, owner)
   │
   └─ Team / Membership / User (org structure; loose, not a cascade authority)
```

## Tables

### The metric layer (permanent)

**metric_nodes** — a business metric, independent of any goal or cycle.
| column | notes |
|---|---|
| workspace_id, name, description | "Weekly active teams creating a doc" |
| unit, direction | `count/%/currency/duration`; `up_is_good` / `down_is_good` |
| owner_team_id, owner_user_id | accountability without hierarchy |
| north_star | boolean — at most a handful per workspace |

**metric_edges** — `parent_node_id → child_node_id, relation: input_to`. Renders the
North Star / input-metric tree; also lets 4DX lead measures point at their lag.

**metric_sources** — connector binding, one active per node.
| column | notes |
|---|---|
| metric_node_id, kind | `warehouse_sql / posthog / ga / amplitude / stripe / jira / linear / github / sheet / webhook / manual` |
| config (jsonb), refresh_cron | query text, event name, cell ref… |
| last_sync_at, last_error | health surfaced in UI |

**metric_points** — the time series: `metric_node_id, value, at, source (synced|manual)`.
Append-only.

### The goal layer (ephemeral)

**cycles** — `workspace_id, name, starts_on, ends_on, parent_cycle_id` (annual ⊃
quarterly ⊃ 6-week), `state: planning|active|scoring|closed`.

**goals**
| column | notes |
|---|---|
| workspace_id, cycle_id | |
| owner_type/owner_id | team or user |
| title, body (rich text) | body carries NCT Narrative / V2MOM sections |
| contract | `committed` \| `aspirational` — makes the ambition contract explicit (F4) |
| state | `draft → proposed → active → scored → archived` (`proposed` enables Hoshin catchball later) |
| score, retro_note, carry_decision | cycle-end ritual: `done | carry_forward | archived` |
| visibility | `workspace` default; `private` is the rare exception (FAST) |

**measures**
| column | notes |
|---|---|
| goal_id, position, name | |
| kind | `metric` (from X to Y) \| `binary` (done/not — NCT commitments, EOS Rocks) |
| role | `lead` \| `lag` (4DX); nullable |
| metric_node_id | nullable — bound measures auto-update from metric_points |
| start_value, target_value, current_value | current denormalized from latest check-in/point |
| confidence | latest, denormalized; history lives on check-ins |

**check_ins** — the atomic unit of the product.
| column | notes |
|---|---|
| measure_id (or goal_id for binary/goal-level), author_id, at | |
| value | nullable when connector-fed |
| confidence | `on_track / at_risk / off_track` (or 1–10) |
| note | the one-line "why / what changed" |
| origin | `human / slack / ai_draft_confirmed / auto_sync` — tracks how much toil AI removed |
| obstacle_id | nullable — "obstacle #2 materialized" |

**obstacles** — `goal_id, description, status: open|materialized|cleared` (V2MOM steal).

**alignment_edges** — `from_goal_id →contributes_to→ to_goal_id`, many-to-many,
cross-team. **No tree table.** Tree/org views are renderings over these edges (F3).

**initiative_links** — `goal_id or measure_id, provider (jira|linear|github),
external_ref, cached_status, cached_title, synced_at`. We never store tasks (doc 01: no
task tracker).

### Rituals and framing

**scorecards / scorecard_rows** — `scorecard_id, metric_node_id, owner_id,
expected_value, comparator, position`. Weekly red/green + 13-week trailing view falls out
of metric_points. Serves EOS and the KPIs-only crowd with the same object.

**framework_templates** — the ~15% skin: `workspace_id, base: okr|nct|eos|4dx|custom`,
jsonb of labels (`goal_label: "Rock"`, `measure_label: "Commitment"`), defaults
(`default_contract`, `default_measure_kind`, `max_goals_warning`, `cadence`), and which
surfaces are on (scorecard, meeting view, narrative field).

## How each framework maps

| Framework | Configuration over the same schema |
|---|---|
| Classic OKR | goals=Objectives, measures kind=metric contract=aspirational, quarterly cycles |
| NCT | body=Narrative (required), measures kind=binary contract=committed, task layer = initiative_links only |
| EOS | goals=Rocks (binary, committed, 90-day), scorecard on, meeting view on |
| 4DX | 1–2 goals/team (WIGs), measures role=lead with metric_edges to the lag, weekly commitments = check-in notes |
| V2MOM | body sections V/V/M, obstacles required, measures attached |
| North Star | metric graph is the primary surface; goals are targets pinned to nodes |
| KPIs-only | scorecard only; zero goals — still a valid workspace |

## Design notes

- **Postgres throughout;** metric_points is the only high-volume table (consider
  timescale/partitioning later, not v1).
- **Denormalize** `current_value`/`confidence` onto measures for the one-screen team view
  (doc 01) — that page must render with zero N+1s.
- **Staleness is computed, not stored:** `max(check_ins.at, comments.at)` per goal;
  surfaced as the FAST health signal.
- **Soft-delete/audit:** goals and measures get an immutable `events` audit trail
  (mid-cycle edits are a feature, the trail keeps trust) — not fluxday-style
  `is_deleted + default_scope`, which we know from experience poisons every query.
- **v1 subset:** cycles, goals, measures (manual), check_ins, alignment_edges, Slack
  check-in ingestion. metric_* and scorecards land in v2 with connectors — but design
  measures with `metric_node_id` nullable from day one so v2 is additive, not a
  migration.
