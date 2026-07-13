# Coverage Gate — fluxday

**Mode:** RUNTIME (app boots; real SimpleCov line coverage measured in-suite). This supersedes
the 2026-07-07 STATIC pass (which reported `PENDING(env)` / ~0% asserting-surface proxy while
the app was unbootable and the suite was scaffold-only). Since then Roadmap Task 0 (boot) landed,
a Devise sign-in harness + real fixtures were built, and the suite was fleshed out with real
assertions — so this pass replaces the proxy with true per-file line %.
**Date:** 2026-07-13 · **Depth:** Phase A (read-only) · deep version of Roadmap §6 gate.
**Measurement:** `rake test` with `DB_NAME=fluxday DB_HOST=127.0.0.1 DB_USER=root DB_PASS=""`,
SimpleCov `command_name "Minitest"`. Overall **70.86% (1116/1575 lines)**.

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

## 7. Phase B (NOT run this pass)

Writing the tests is Phase B — **requires explicit user go-ahead** and uses the `tdd` skill.
Characterization tests must **pin current behavior** (bugs included — e.g. whatever
`credentials_controller` actually returns today) — do not "fix" role logic, the OAuth callbacks,
or the reports duration math while backfilling. Re-measure after each batch. Given the stakes,
confirm the `users_controller`, `ability.rb`, and Doorkeeper-API tests with a **`mutant --use
minitest`** run once green — `ability.rb` reads 100% covered but coverage is not catch-rate, and
a permission file is exactly where a surviving mutant matters most.

---

*Phase A read-only. SimpleCov was already installed and configured (no test-helper changes made
this pass); the tree is clean apart from this deliverable. Real per-file line coverage is now the
source of truth — re-run this gate after each Phase B batch and after any auth-gem migration.*
