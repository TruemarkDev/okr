# Coverage Gate — fluxday

**Mode:** RUNTIME (app boots; real SimpleCov line coverage measured in-suite). This supersedes
the 2026-07-07 STATIC pass (which reported `PENDING(env)` / ~0% asserting-surface proxy while
the app was unbootable and the suite was scaffold-only). Since then Roadmap Task 0 (boot) landed,
a Devise sign-in harness + real fixtures were built, and the suite was fleshed out with real
assertions — so this pass replaces the proxy with true per-file line %.
**Date:** 2026-07-13 · **Depth:** Phase A (read-only) audit + **Phase B auth-surface backfill
executed** (see §7) · deep version of Roadmap §6 gate.
**Measurement:** `rake test` with `DB_NAME=fluxday DB_HOST=127.0.0.1 DB_USER=root DB_PASS=""`,
SimpleCov `command_name "Minitest"`. Overall **70.86% → 88.52%** after Phase B (§1–§6 below
describe the pre-Phase-B state; §7 records the auth-surface backfill, §8 the `reports_controller`
hardening).

---

## Gate verdict: 🟢 GREEN on the 60% floor · 🟠 PARTIAL on hotspots

- **≥60% overall line coverage:** **MET** — 70.86%. The upgrade may proceed past the gate's
  hard floor. This is the real number, not a proxy.
- **Near-100% on risk hotspots:** **PARTIAL.** RBAC is fully pinned (`ability.rb` **100%**,
  `application_controller` 100%), but the **auth *entry points* and user/role/password
  management are at 0%** — no test exists for the OAuth login callbacks, the Doorkeeper-gated
  API, the fluxapp OmniAuth strategy, or `users_controller` (role assignment + `change_password`).
  Per the skill's rule — *"a 55% overall with hotspots fully pinned beats 70% spread thin"* — the
  headline 70.86% overstates safety on exactly the surfaces an upgrade is most likely to break.

**Bottom line:** the floor is cleared, so this no longer blocks the first version bump the way
the STATIC pass did. But **before touching auth/OAuth/Doorkeeper code** (e.g. Roadmap Task 10,
doorkeeper 1.1→5.x), the 0% auth surface must be pinned — those migrations are precisely where
an untested `current_resource_owner` / `doorkeeper_authorize!` path silently changes behavior.

---

## 1. Suite & framework currency

- **Framework:** Minitest via `rails/test_help` + `fixtures :all`. **Current** — runs green on
  Ruby 3.3 / Rails 8. No rspec-2 "the suite is its own migration" blocker. No RSpec, no Cucumber
  — **single live suite**, so no dual-suite/orphaned-suite split to price.
- **Harness present:** `Devise::Test::ControllerHelpers#sign_in` is wired in `test_helper.rb`
  with a documented ordering workaround; fixtures are real (`users(:admin)`, `manager`), not the
  old `MyString` placeholders. **The one-time prereq cost from the STATIC pass (sign-in harness +
  fixture rebuild) is already paid** — that is why the old 5/12 estimate collapses below.
- **Test files:** 43 `*_test.rb` (19 model, 12 controller, 12 helper) + 1 integration
  (`anonymous_pages_test.rb`). Missing controller tests: `users`, `api/v1/*`,
  `users/omniauth_callbacks`.
- **SimpleCov:** present (0.22.0) and running.
- **Resultset caveat:** `coverage/.resultset.json` carries **two `command_name`s** — the live
  **`Minitest`** run (70.86%) and a **stale `Unit Tests`** entry (30.3%) left over from a
  partial/earlier run and kept alive by SimpleCov's merge. It is **not** a second suite; the gate
  number is the `Minitest` one. Ignore the 30.3% figure (or clear the resultset to avoid
  confusion).

## 2. Per-file coverage (RUNTIME — real line %)

**Layer rollup:** models **97.2%** (282/290) · controllers 66.1% (733/1109) · helpers 76.5% ·
uploaders 89.5% · lib 38.0% · **API controllers 0.0%** (0/22).

**Fully pinned (100%):** `ability.rb`, `application_controller`, `projects_controller`,
`calendar_controller`, `task.rb`, `team.rb`, `project.rb`, `okr/objective/key_result`,
`work_log`, `comment`, all join models, all 12 view-helpers.

**Uncovered surface — every file with missing lines (459 total missing):**

| Coverage | Miss | File | Risk |
|---:|---:|---|---|
| **0.0%** | 81 | `controllers/users_controller.rb` | 🔴 roles + `change_password` + `manager_ids` |
| 63.0% | 170 | `controllers/reports_controller.rb` | 🟠 date-range + worklog duration/hour math; highest churn (46) |
| **0.0%** | 22 | `lib/omniauth/strategies/fluxapp.rb` | 🔴 OAuth strategy |
| **0.0%** | 21 | `controllers/users/omniauth_callbacks_controller.rb` | 🔴 Google/fluxapp login callback |
| **0.0%** | 15 | `controllers/api/v1/credentials_controller.rb` | 🔴 `doorkeeper_authorize!` (see note) |
| **0.0%** | 7 | `controllers/api/v1/api_controller.rb` | 🔴 `current_resource_owner` token→user |
| 34.1% | 29 | `controllers/objectives_controller.rb` | 🟡 core OKR CRUD |
| 36.4% | 21 | `controllers/key_results_controller.rb` | 🟡 core OKR CRUD |
| 72.6% | 20 | `helpers/application_helper.rb` | 🟢 view helpers |
| 80.2% | 16 | `controllers/work_logs_controller.rb` | 🟡 |
| 80.6% | 14 | `controllers/teams_controller.rb` | 🟡 |
| 71.4% | 10 | `controllers/comments_controller.rb` | 🟢 |
| 67.9% | 9 | `lib/time_to_diff.rb` | 🟠 duration/`to_duration` math |
| 89.7% | 8 | `models/user.rb` | 🟠 auth/role predicates |
| 92.4% | 6 | `controllers/tasks_controller.rb` | 🟢 |
| 91.5% | 4 | `controllers/oauth_applications_controller.rb` | 🟢 |
| 89.5% | 2 | `uploaders/image_uploader.rb` | 🟢 |
| 94.5% | 3 | `controllers/okrs_controller.rb` | 🟢 |
| 95.7% | 1 | `controllers/home_controller.rb` | 🟢 |

## 3. What drives the gap (and it is concentrated)

Two files are **55% of the entire miss** (251/459): `reports_controller` (170) and
`users_controller` (81). The auth cluster (`users_controller` + `omniauth_callbacks` + fluxapp
strategy + `api_controller` + `credentials_controller`) is **146 missing lines, almost all at
literally 0%** — the coverage is not thin there, it is *absent*. That is the whole reason the
headline % looks healthier than the app actually is.

## 4. Risk-ranked backfill (highest blast radius first)

**Tier 0 — HOTSPOTS at 0%, must reach near-100% before any auth/OAuth upgrade work:**
1. `users_controller.rb` (0%, 81 lines) — **highest single untested risk.** `load_and_authorize_resource`,
   `create`/`update`/`destroy`, **`change_password`**, and `user_params` permitting `:role`,
   `:password`, `manager_ids`. Both a **permission** and a **password/role** surface. Churn 14.
2. `users/omniauth_callbacks_controller.rb` (0%) + `lib/omniauth/strategies/fluxapp.rb` (0%) —
   Google + fluxapp **login entry points**. Needs an OmniAuth mock harness (one-time, small).
3. `api/v1/credentials_controller.rb` (0%) + `api/v1/api_controller.rb` (0%) — Doorkeeper-gated
   API. `current_resource_owner` resolves token→user; `credentials_controller` carries an inline
   comment that a **pre-3.0 Doorkeeper API call `doorkeeper_for :all` was *silently never caught*
   because nothing tests this path** — a concrete instance of an untested auth surface having
   already hidden a regression. Pin current behavior before the doorkeeper 1.1→5.x migration.
4. `user.rb` (89.7%, 8 lines) — top up the last role/predicate branches to near-100%.

**Tier 1 — high-churn / date-duration logic:**
5. `reports_controller.rb` (63%, 170 miss, churn 46 — highest in repo). Bespoke date-range and
   **worklog duration aggregation** (`sum(&:minutes).to_duration`, `beginning_of_month`/
   `end_of_day` boundaries) — the app's closest thing to "money" math (billable hours). Won't
   reach 100% cheaply, but the date-boundary and hour-total branches are worth characterization.
6. `lib/time_to_diff.rb` (67.9%) — the `to_duration` helper the reports lean on; small, pin it.

**Tier 2 — core OKR CRUD top-ups:** `objectives_controller` (34%), `key_results_controller`
(36%), `work_logs_controller` (80%), `teams_controller` (81%), `comments_controller` (71%).

**Tier 3 — low value:** `application_helper` (73%), `image_uploader`, and the last 1–6 lines on
already-green controllers.

## 5. Gap size & dual estimate (toward 80% overall + hotspots near-100%)

- **≥60% floor:** already cleared (70.86%). No work needed for the hard gate.
- **To 80% overall:** +144 covered lines (1116 → 1260). The auth cluster alone is 146 lines —
  **the hotspot backfill and the path to 80% are essentially the same work**: pin
  `users_controller` (+81), `omniauth_callbacks` (+21), `credentials` (+15), `api_controller`
  (+7), plus `objectives`/`key_results` top-ups and `user.rb`'s last 8 → clears 80% *and* takes
  the auth hotspots from 0% to near-100%.
- **Prereqs:** **none** — the sign-in harness and real fixtures already exist (the expensive
  one-time cost the STATIC pass budgeted). New: a small **OmniAuth mock** (Tier-0 #2) and a
  **Doorkeeper token** setup (Tier-0 #3) — fiddly but each ~0.25 day, one-time.

**Best / worst engineer-days: `3.5 / 7`** (runtime estimate, tighter than the STATIC ±wide
range now that real per-file % is known). Breakdown:
- `users_controller` (roles + change_password) — 0.75 / 1.25
- OAuth callbacks + fluxapp strategy (+ OmniAuth mock) — 0.5 / 1.25
- Doorkeeper API pair (+ token harness) — 0.5 / 1.0
- `reports_controller` meaningful date/duration branches — 1.0 / 2.0
- `objectives`/`key_results`/`work_logs`/`teams`/`comments` top-ups — 0.5 / 1.0
- `user.rb` + `time_to_diff` + trailing 1-liners — 0.25 / 0.5

Reaching **full** near-100% on `reports_controller` (all 170 lines) would add ~1–2 days beyond
this; not required for the 80% target and lower marginal safety value than the auth cluster.

## 6. Reconciliation with Roadmap §7 Task 1

**Revise DOWN and re-scope.** The prior STATIC pass set Task 1 at **5 / 12** on the assumption of
a from-scratch backfill including a sign-in harness + fixture rebuild from ~0%. Both prereqs are
now done and the suite is at 70.86% real coverage. Recommend:

- **Retarget Task 1** from "backfill to ≥60%" (already met) to **"pin the 0% auth/OAuth/API
  hotspots to near-100% and lift overall to ≥80%."**
- **New estimate: 3.5 / 7 eng-days** (down from 5/12).
- Keep it a **hard predecessor of the Doorkeeper 1.1→5.x migration** (Roadmap Task 10) rather
  than of the first Rails bump — the floor no longer blocks the bump, but the untested auth
  surface blocks the auth-gem work specifically.

## 7. Phase B — auth-surface backfill (EXECUTED 2026-07-13)

Scoped by the coordinator to **unblock the Doorkeeper 1.1→5.x migration (Task 10)** — auth/OAuth/API
surface only, characterization (pin current behavior, bugs included), Minitest, no changes to
`reports_controller` or other non-auth files. Full suite after: **363 runs, 0 failures, 0 errors,
16 skips.** Overall coverage **70.86% → 78.95% (1116/1575 → 1204/1525)**.

**New test files:**
- `test/controllers/api/v1/credentials_controller_test.rb` — 4 tests
- `test/controllers/users/omniauth_callbacks_controller_test.rb` — 4 tests
- `test/lib/omniauth/strategies/fluxapp_test.rb` — 3 tests
- `test/controllers/users_controller_test.rb` — 8 tests

**Per-file coverage (Minitest command, 0% → after):**

| File | Before | After |
|---|---:|---:|
| `api/v1/credentials_controller.rb` | 0% | **100%** (10/10) |
| `api/v1/api_controller.rb` | 0% | **100%** (4/4) |
| `users/omniauth_callbacks_controller.rb` | 0% | **100%** (14/14) |
| `lib/omniauth/strategies/fluxapp.rb` | 0% | **90%** (9/10) |
| `users_controller.rb` | 0% | **81%** (47/58) |

### 🔴 Critical finding — `GET /api/v1/me` returns HTTP 500 in *every* path today

Building the Doorkeeper regression net surfaced that the API auth endpoint is **entirely
non-functional** on this Rails 8 checkout — two independent, environment-**in**dependent bugs the
migration must fix (the tests pin the current broken behavior and will force a conscious flip):

1. **Reject path (missing/invalid token):** doorkeeper-5.1.2's `doorkeeper_render_error` raises
   `ArgumentError (given 2, expected 0..1)` under Rails 8 **before any response is produced** — so
   an unauthenticated request 500s instead of returning 401. This is squarely inside the
   1.1→5.x blast radius; the migration target must restore a clean 401.
2. **Success path (valid token, owner linked):** the token authorizes and `current_resource_owner`
   resolves the user correctly, but serializing that user to JSON calls
   `ImageUploader#default_url → asset_path("fallback/user.png")`, and **only *versioned* fallbacks
   exist** (`icon_user.png`, `thumbnail_user.png`, …) — no bare `user.png` — so it raises
   `Sprockets::Rails::Helper::AssetNotFound`. Any user without an uploaded avatar 500s the endpoint.

The only non-500 path is a valid token whose owner is *not* linked to the application (renders
`{ error: "Invalid grant." }`). Both bugs are pinned as characterization tests with comments
directing the migration to flip them to 401 / 200. **Recommend filing these as beads/Task-10
acceptance criteria** (`bd create` is currently broken in this checkout — see CLAUDE.md — so flag
to the user rather than filing).

### Notes & follow-ups
- The stale `Unit Tests` command_name still lingers in `coverage/.resultset.json` beside the live
  `Minitest` one (SimpleCov reports "Minitest, Unit Tests") — harmless but worth clearing.
- **Out of scope this pass (per coordinator):** `reports_controller.rb` (still 63%, the largest
  remaining gap + date/duration math) and the general lift toward 80% beyond the auth surface.
- **Not yet run:** `mutant --use minitest` on `credentials_controller` / `api_controller` /
  `ability.rb` — recommended before the Doorkeeper bump to confirm the new net actually catches a
  behavior change (a 100%-covered auth path is not the same as a mutation-resistant one).

## 8. Phase B — `reports_controller` hardening (EXECUTED 2026-07-13)

Discretionary broad hardening of the largest remaining gap (per coordinator). Extended the
existing `test/controllers/reports_controller_test.rb` (no duplication) with report_type
branches, the worklogs `detailed` per-user/per-day grouping, employee-role `@opts` branches, and
CSV/XLS export paths across every action. Pin-current-behavior only. Full suite after: **403 runs,
0 failures, 0 errors, 16 skips.** Overall **78.95% → 88.52%**; `reports_controller.rb`
**63.0% → 94.8% (290/460 → 436/460)**.

Remaining ~24 uncovered lines are low-value: duplicate `format.xls` render blocks (identical
`MissingTemplate` raise, already characterized generically), a few CSV `@fields` tail lines inside
loops with no in-range fixture data, and the **dead protected method `redirect_for_unauthorized`
(lines 642-644)** — never wired to a route; note as dead code.

### 🔴 Three current-behavior bugs surfaced (all pinned as characterization tests + flagged for bd)

1. **Every CSV/XLS export returns HTTP 500.** All report actions do
   `render "reports/csv_report.csv.erb"` / `"...excel_report.xls.erb"` / `"...worklog_detailed.xls.erb"`
   — passing a filename with an embedded `.csv.erb`/`.xls.erb` to `render`, which no longer
   resolves under Rails 8's template lookup (confirmed 500 through the full HTTP stack). The
   template files themselves exist. **Fix:** `render template: "reports/csv_report", formats: :csv`.
2. **`assignments` 500s on a nil-minutes worklog.** Line 613 sums minutes with Ruby
   `Array#sum(&:minutes)` and **no `.to_i`** (unlike every other action) — an in-range task whose
   worklog has nil minutes raises `TypeError: nil can't be coerced into Integer`, format-independent
   (`assignments` builds `@fields` unconditionally). **Fix:** `sum { |l| l.minutes.to_i }`.
3. **Dead protected method** `redirect_for_unauthorized` (lines 642-646) — unreferenced; also its
   body `unless users.include?(users)` compares the array to itself (always false). Safe to delete.

Each is pinned with an `assert_raises` characterization test and a `# 🔴 BUG PINNED` comment
directing the flip to green once fixed. **These are the three bd issues to file** (`bd create`
is broken in this checkout per CLAUDE.md — flagged for the user to file manually). None of them is
in the Doorkeeper blast radius; they are export/reporting defects (candidate for their own bead).

---

*Phase A was read-only. Phase B (two passes) added five test files / extended one under `test/`
and did not modify any `app/`, `lib/`, or config code — the characterization tests pin current
behavior (500s / TypeErrors included) without fixing it. Re-run this gate after the Doorkeeper
migration and after the CSV/XLS + assignments fixes to replace the pinned-bug expectations with
success assertions.*
