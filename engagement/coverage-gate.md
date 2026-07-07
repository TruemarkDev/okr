# Coverage Gate — fluxday

**Mode:** STATIC (app does not boot on this machine — Ruby 2.3 missing, `bundle` unresolvable).
Real line coverage is **`PENDING(env)`**. All percentages below are a **tested-surface proxy**,
not line coverage. Read the honesty note before quoting any number.
**Date:** 2026-07-07 · **Depth:** Phase A (read-only) · deep version of Roadmap §6 gate.

---

## Gate verdict: 🔴 RED

The gate (**≥60% line coverage overall + near-100% on auth/permission/money hotspots**) is
**not met, and not remotely close.** Real line coverage is `PENDING(env)`, but the static
proxy — measured *honestly* (asserting tests only) — is **effectively 0%**. There is **no
behavioral safety net** anywhere in this codebase today. Do not touch a single line of
product code (let alone start a version bump) until this is backfilled.

---

## 1. Suite & framework currency

- **Framework:** Minitest via `rails/test_help` + `fixtures :all` (Rails 4.1 default). No RSpec.
- **SimpleCov:** **absent** (not in Gemfile). Nothing measures coverage today.
- **Test files:** 41 total — 17 model, 12 helper, 12 controller. `test/integration/` and
  `test/mailers/` contain only `.keep` (empty).
- **Currency flag (amber):** Minitest itself is current and runs on modern Ruby, so this is
  **not** an rspec-2 style "the suite is its own migration" blocker. **However** the scaffold
  controller tests use the **pre-Rails-5 positional functional-test syntax**
  (`get :index`, `post :create, project: {...}`) which **breaks in Rails 5+** (requires
  `get :index, params: {...}`). Any test written now must anticipate that rewrite — it is
  already implied by Roadmap Task 4 (4.2→5.0). Write new tests in a form that survives it.

## 2. Surface map & the proxy (READ THE HONESTY NOTE)

**Source units** (`app/models` + `app/controllers` + `app/helpers` + `app/mailers` + `lib`):

| Layer | Units | Test files present | **File-match** (naive) | **Asserting** (honest) |
|---|---:|---:|---:|---:|
| Models | 18 | 17 (all but `ability.rb`) | 94% | **0%** — all 17 are empty `# test "the truth"` stubs |
| Controllers | 17 | 12 | 71% | ~0% — see below |
| Helpers | 13 | 12 (all but `application_helper`) | 92% | **0%** — all 12 are 4-line empty stubs |
| Mailers | 0 | — | — | — |
| Lib | 2 | 0 | 0% | **0%** |
| **Total** | **50** | **41** | **82%** | **≈ 0%** |

> **HONESTY NOTE — the 82% is theater, do not quote it.** The naive file-match proxy reads
> 82% only because Rails' scaffold generator dropped a stub file next to almost every unit.
> Grep for real (uncommented) assertions in the model and helper tests returns **zero**. The
> only files containing any `assert` are 9 controller tests carrying the standard scaffold
> CRUD block (`should get index`, `should create`, …) plus 3 with a 2-line smoke test. And
> even those **cannot pass**:
> - `ApplicationController` has a global `before_filter :authenticate_user!` with **no sign-in
>   helper** in `test_helper.rb` or any setup → every `assert_response :success` redirects to
>   login → **RED**.
> - Fixtures are generator placeholders (`projects.yml` = `name: MyString`, `code: MyString`)
>   and the tests reference `projects(:one)` etc. against junk data — model validations and
>   custom controller actions will not behave.
>
> **The trustworthy tested-surface proxy is ~0%.** Report `PENDING(env)` for line coverage
> and **0% asserting-surface** as the proxy. The 82% file-match number exists only to be
> explicitly discounted.

## 3. Risk-ranked backfill (highest blast radius first)

Auth / permissions / OAuth surfaces first (devise + doorkeeper + omniauth + cancancan are all
present), then churn, then fan-in. These are the **near-100% hotspots** the gate demands.

**Tier 0 — HOTSPOTS, must reach near-100% (auth / permissions / OAuth):**
1. `app/models/ability.rb` — **CanCan RBAC**, admin/manager/employee branching, block-based
   rules over `project_ids`/`team_ids`/`user_ids`. Highest permission blast radius. **No test
   file at all.** churn 15.
2. `app/models/user.rb` — devise (`database_authenticatable`, `omniauthable`,
   google_oauth2 + fluxapp), `admin?/manager?/employee?` role predicates that drive Ability,
   role scopes. churn 31 (2nd-highest in repo). High fan-in.
3. `app/controllers/users/omniauth_callbacks_controller.rb` — OAuth login callback (Google +
   fluxapp). Untested. Auth entry point.
4. `app/controllers/api/v1/credentials_controller.rb` + `api_controller.rb` — doorkeeper-guarded
   API. Untested.
5. `app/models/doorkeeper_application.rb`, `oauth_application.rb`, `user_oauth_application.rb`,
   `oauth_applications_controller.rb` — OAuth-server surface (doorkeeper 1.1, itself slated for
   a 1.1→5.x migration in Roadmap Task 10). Pin current behavior before that migration.

**Tier 1 — high churn / high fan-in core domain:**
6. `app/controllers/reports_controller.rb` — **highest-churn controller (43)**, reporting logic.
7. `app/controllers/tasks_controller.rb` (churn 27) + `app/models/task.rb` (churn 24).
8. `app/models/team.rb` (15) + `teams_controller.rb` (18); `work_logs_controller.rb` (16).
9. OKR cluster: `okr.rb`, `objective.rb`, `key_result.rb` + their controllers (core product).

**Tier 2 — remaining CRUD controllers & models to top up to 60%:** projects, comments,
calendar, home, users_controller; join models (task_assignee, task_key_result, project_manager,
reporting_manager, team_member).

**Tier 3 — low value, low risk:** 13 helpers (mostly trivial view helpers), `lib/time_to_diff.rb`.
`lib/omniauth/strategies/fluxapp.rb` is fiddly but low-churn — pin lightly.

## 4. Gap size & dual estimate

- **Distance to gate:** from **~0% asserting → ≥60% line** + Tier-0 hotspots near-100%.
  Essentially a **from-scratch backfill of ~50 units**, not a top-up of a partial suite.
- **Prerequisites (one-time, before any test goes green):**
  - App must boot first — **Roadmap Task 0** is a hard dependency; this estimate assumes it.
  - Build a **sign-in test helper** (Devise `sign_in` / integration login) — without it every
    controller test is red.
  - **Rebuild fixtures** with valid data (current ones are `MyString` placeholders).
- **Strategy:** lead with **controller functional/integration tests** — they cascade coverage
  through models + helpers + views in one pass, so ~10–12 good ones plus targeted Ability/User
  unit tests realistically clear 60% on an app this small. Do **not** chase all 13 helpers.

**Best / worst engineer-days: `5 / 12`** (heuristic ~0.25 day thin unit → ~0.75 day hotspot;
static estimates are wide and tighten to ±20% once the app boots and real per-file SimpleCov
lands). Breakdown: prereqs (sign-in helper + fixtures) 0.5–1 · 12 controller tests 3.5–6 ·
Ability+User hotspots 1–1.5 · doorkeeper/omniauth/api auth 1–1.5 · model top-ups 1–2 · lib 0.5.

## 5. Reconciliation with Roadmap §7 Task 1 (best 4 / worst 9)

**REVISE — up, and qualitatively.** The roadmap's Task 1 ("add SimpleCov, run suite, backfill
to ≥60%") implicitly assumed the existing suite is a *partial baseline*. This audit finds it is
**scaffold-only — ~0% asserting coverage** — and that the controller tests are **auth-broken
and fixture-broken**, needing a sign-in harness and rebuilt fixtures before *any* of them can
go green. That raises both ends:

- **Best: 4 → 5** (the free "existing tests already cover some %" assumption is false).
- **Worst: 9 → 12** (prereq harness + fixture rebuild + genuinely from-scratch hotspots).

The most important correction is **qualitative, not the number**: Task 1's starting point is a
green-field, not a top-up. Recommend re-labeling Task 1 as *"Coverage gate: build sign-in
harness + fixtures, then backfill characterization tests from ~0% → ≥60% (auth/RBAC first)"*
and setting **5 / 12**.

## 6. Phase B (NOT run this pass)

Writing the tests is Phase B — **requires explicit user go-ahead** and uses the `tdd` skill.
Characterization tests must **pin current behavior** (bugs included) — do not "fix" the Ability
rules or role logic while backfilling. Re-measure after each batch. Given the stakes on
`ability.rb` and `user.rb`, confirm those hotspot tests with a **mutant** run once green.

---

*Phase A read-only. No SimpleCov was installed and `test_helper.rb` was not modified — the tree
is clean. Real line coverage remains `PENDING(env)` until Roadmap Task 0 (boot) lands; re-run
this gate in RUNTIME mode immediately after boot to replace the 0% proxy with true per-file %.*
