---
title: fluxday — Upgrade Roadmap (audit)
type: roadmap
status: draft-v0-static-pass
client: fluxday (Foradian, open-source OKR/task tracker)
prepared: 2026-07-07
current_stack: Rails 4.1.16 / Ruby 2.3.0 / MySQL (mysql2 0.3.21)
target_stack: Rails 8.0 / Ruby 3.3+
methodology: FastRuby-style — coverage gate → dual-boot → one-minor-at-a-time
---

# fluxday — Upgrade Roadmap

> **Product note.** This is the **Roadmap** deliverable — the fixed-price audit that
> opens an upgrade engagement. It sizes the app, plots the version path, inventories
> the breaking changes and gem incompatibilities, checks the test-coverage gate, and
> produces a prioritized, dual-estimated task list. It is **read-only**: no code is
> changed here.

> **⚠ This is a v0 static pass.** The app **does not currently boot on the build
> machine** (see Finding 1). Runtime-derived numbers — SkunkScore hotspots, exact
> SimpleCov %, `next_rails` deprecation counts, `rails_stats` — are **pending a
> bootable environment** and are called out inline as `PENDING(env)`. Everything else
> below is derived from static analysis of the repo and is final.

---

## 1. Executive summary

fluxday is a **small, self-contained** Rails app: ~2,600 LOC of application Ruby
across 17 controllers, 18 models, 13 helpers, 230 view templates, and 35 migrations,
with **33 direct gems** (80 resolved). It is **six major Rails versions and ~10 minor
hops behind** (Rails 4.1.16 → 8.0) and runs an **end-of-life Ruby (2.3, EOL Mar 2019)**.

The small size is the good news: the surface area to migrate is modest and the app is
a strong pilot/case-study candidate. The bad news is concentrated in three places:

1. **It won't boot on modern hardware** — `therubyracer`/`libv8` and a Ruby 2.3
   toolchain don't build on Apple Silicon. This is the **critical-path blocker**;
   nothing else can be measured or verified until it's fixed.
2. **No visible test-coverage instrumentation** — SimpleCov is absent and the suite
   can't run, so real coverage is **unknown**. FastRuby methodology treats
   ≥60% coverage as a **hard gate** before any version bump. Backfilling
   characterization tests is almost certainly the largest single line item.
3. **A cluster of hard-EOL, upgrade-blocking gems** — devise 3.5, cancancan 1.17,
   ransack 1.8, doorkeeper 1.1, carrierwave 1.0, sprockets 2.12, turbolinks 2.2,
   plus a **git-sourced gem** (`omniauth-fluxapp`) that is a supply-chain/availability
   risk.

**Recommended sequence:** (0) get it booting in Docker → (1) coverage gate to ≥60% →
(2) dual-boot scaffold → (3) climb Rails 4.1→8.0 one minor at a time, interleaving
Ruby bumps → (4) Zeitwerk + asset-pipeline modernization → (5) dual-CI verify + handoff.

**Rough order-of-magnitude:** **~28–48 engineer-days** end to end (see §7), dominated
by the coverage backfill and the Rails 5.0, 6.0 (Zeitwerk), and 7.0 (asset pipeline)
hops. Small codebase, but a long version ladder.

---

## 2. Codebase sizing

| Metric | Count | Source |
|---|---:|---|
| App + lib Ruby LOC | ~2,634 | `wc -l` over `app/`, `lib/` |
| Controllers | 17 | `app/controllers` |
| Models | 18 | `app/models` |
| Helpers | 13 | `app/helpers` |
| View templates | 230 | `app/views` |
| Migrations | 35 | `db/migrate` |
| Direct gems (Gemfile) | 33 | `Gemfile` |
| Resolved gems (lock) | 80 | `Gemfile.lock` |
| Test files | 42 | `test/` (Minitest + fixtures) |
| `rails_stats` (LOC/test ratio, method size) | `PENDING(env)` | needs boot |

**Test framework:** Minitest via `rails/test_help` with `fixtures :all`
(`test/{controllers,models,integration,helpers,mailers,fixtures}`). No RSpec.
42 test files exist but **runnability and coverage are unverified** — the suite
can't execute until the app boots.

---

## 3. Version gap & hop plan

Current: **Rails 4.1.16 / Ruby 2.3.0**. Target: **Rails 8.0 / Ruby 3.3+**.
FastRuby rule: upgrade to the **latest patch of the current minor first**, then move
**one minor at a time**, running the old and new versions side-by-side (dual-boot via
`Gemfile.next` + `next_rails`). Ruby is bumped **just ahead of** the Rails minor that
requires it.

| # | Rails hop | Min Ruby | Ruby action | Headline breaking changes |
|---|---|---|---|---|
| — | 4.1.16 → **4.2.11** | 2.0 | 2.3 ok | `respond_to`→responders gem, foreign keys, adequate-record; smallest hop |
| 1 | 4.2 → **5.0** | 2.2.2 | 2.3 ok | `ApplicationRecord`, `belongs_to` required by default, controller-test API (`assigns`/`assert_template` extracted to `rails-controller-testing`), `rails` CLI replaces many `rake` tasks, `ActionController::Parameters` no longer a Hash |
| 2 | 5.0 → **5.1** | 2.2.2 | → **2.4** | jQuery no longer a default, `form_with`, encrypted secrets, `belongs_to_required_by_default` |
| 3 | 5.1 → **5.2** | 2.2.2 | 2.4 ok | **credentials** replace secrets, Bootsnap, ActiveStorage arrives, CSP DSL |
| 4 | 5.2 → **6.0** | 2.5 | → **2.6/2.7** | **Zeitwerk autoloader** (largest single change), Webpacker default, `Rails.application.config_for`, multi-DB, parallel tests |
| 5 | 6.0 → **6.1** | 2.5 | 2.7 ok | `Rails.application.eager_load!` changes, per-DB connection switching, strict `where` |
| 6 | 6.1 → **7.0** | 2.7 | → **3.1** | **sprockets no longer default** (importmap/jsbundling), Zeitwerk mandatory, `button_to` change, new encryption, `-e` env |
| 7 | 7.0 → **7.1** | 2.7 | 3.1 ok | `config.load_defaults 7.1`, composite keys, normalizes, Docker-first defaults |
| 8 | 7.1 → **7.2** | 3.1 | → **3.3** | `config.load_defaults 7.2`, Progressive-Web-App defaults, Rubocop/Brakeman in new apps |
| 9 | 7.2 → **8.0** | 3.2 | 3.3 ok | Solid Queue/Cache/Cable, Propshaft default, authentication generator, Kamal 2 |

**Ruby ramp (interleaved):** 2.3 → 2.4 → 2.6/2.7 → 3.1 → 3.3. Each bump is a small,
independently shippable step and should land **before** the Rails minor that needs it.

**`config.load_defaults` ramp:** after reaching each of 5.0 / 5.1 / 5.2 / 6.0 / 6.1 /
7.0 / 7.1 / 7.2 / 8.0, walk the `new_framework_defaults_*.rb` toggles on one at a time,
risk-tiered — do **not** flip `load_defaults` wholesale.

---

## 4. Gem compatibility & health

Upgrade-blocking or high-risk dependencies (resolved versions from `Gemfile.lock`).
`next_rails --update` will produce the exact compatible target per hop; the table is
the static assessment.

| Gem | Locked | Issue | Action |
|---|---|---|---|
| **rails** | 4.1.16 | 6 majors behind | the ladder in §3 |
| **therubyracer** | (libv8) | ❌ won't compile on Apple Silicon / modern libv8; **boot blocker** | remove — use Node via `execjs`, or `mini_racer` only if a JS runtime is truly needed |
| **mysql2** | 0.3.21 | Rails ≥5.1 needs `~> 0.4`/`0.5` | bump to 0.5.x early (Ruby-3/Rails-7 needs it) |
| **devise** | 3.5.10 | needs **≥4.x** for Rails 5+ | bump at the 5.0 hop |
| **cancancan** | 1.17.0 | needs **2.x/3.x** for Rails 5+ | bump at 5.0; API mostly compatible |
| **ransack** | 1.8.10 | needs **2.x** (Rails 5), **4.x** (Rails 7) | bump per hop; watch `ransackable_attributes` allowlist (2.4+/4.x security change) |
| **doorkeeper** | 1.1.0 | OAuth server, **very old**; needs ≥5.x | bump carefully — migration + token model changes; **auth-critical** |
| **carrierwave** | 1.0.0 | needs **2.x/3.x**; consider ActiveStorage (arrives 5.2) | bump to 2.x; ActiveStorage migration optional/later |
| **sprockets** | 2.12.5 | 3.x/4.x breaking; not default after Rails 7 | 3.x at 5.x, decide Propshaft/importmap at 7.0 |
| **turbolinks** | 2.2.1 | ancient; superseded by Turbo | replace with `turbo-rails` or drop (Rails 7 era) |
| **foundation-rails** | 5.2.1.0 | pinned old CSS framework | keep pinned or replace during asset work |
| **wicked_pdf** | 0.9.10 | old; pairs with `wkhtmltopdf-binary` | bump; **wkhtmltopdf is deprecated upstream** — evaluate replacement |
| **wkhtmltopdf-binary** | — | deprecated project; arch-specific binaries | evaluate Grover/Puppeteer or Prawn later |
| **omniauth-oauth2 / omniauth-google-oauth2** | — | OmniAuth <2.0 has **CSRF CVE (GHSA)**; 2.0 changed request-phase to POST | bump OmniAuth to ≥2.x + `omniauth-rails_csrf_protection` |
| **omniauth-fluxapp** | git (`stpnlr/omniauth-fluxapp`) | ⚠ **git-sourced, single-maintainer** — availability + supply-chain risk | vendor/fork into the repo; pin a SHA |
| **friendly_id** | 5.0.5 | needs 5.4/5.5 for Rails 6+ | bump per hop, low risk |
| **jbuilder / coffee-rails / jquery-rails / select2-rails / cocoon** | old | asset-era gems | address during the asset-pipeline hop |

**Runtime security scan** (`bundler-audit`, `ruby_audit`, `bundler-leak`) →
`PENDING(env)`, but two are already visible statically: **Ruby 2.3 itself is EOL**
(unpatched interpreter CVEs) and **OmniAuth <2.0 CSRF**. A full `security-audit`
(brakeman + bundler-audit + ruby_audit + bundler-leak) is a recommended parallel wedge.

---

## 5. Test-coverage gate (HARD gate)

| Check | Status |
|---|---|
| Test suite present | ✅ 42 Minitest files |
| Suite runnable | ❌ blocked (app won't boot) |
| SimpleCov instrumented | ❌ absent |
| Measured coverage | **UNKNOWN — `PENDING(env)`** |
| Gate (≥60% before upgrading) | 🔴 **cannot pass until measured** |

**Discipline:** coverage-first. Once the app boots, add SimpleCov, run the suite, and
measure. Every controller/model below the line gets **characterization tests**
(pin current behavior, don't judge it) *before* its code is touched by an upgrade.
With 17 controllers + 18 models and only 42 test files, expect meaningful backfill —
this is budgeted as the largest line item in §7.

---

## 6. Risk hotspots

Static reasoning (SkunkScore churn×complexity ranking is `PENDING(env)`):

- **Authorization / OAuth server** — `doorkeeper` 1.1 + `devise` 3.5 +
  `omniauth-*` (incl. the git-sourced fluxapp strategy). Auth is the highest-blast-radius
  area: OAuth-server migrations, OmniAuth 2.0 CSRF/POST change, and devise 4 changes all
  land here. **Prioritize characterization tests around every auth path first.**
- **PDF generation** — `wicked_pdf` + deprecated `wkhtmltopdf-binary`; likely to break
  on arch/runtime and needs a replacement decision.
- **Asset pipeline** — sprockets 2.12 + coffee/foundation/turbolinks/select2: a
  self-contained modernization cluster, best done as one hop around Rails 6→7.
- **35 migrations** — old migration syntax (no `[4.1]` version tag) will warn under
  Rails 5+; `strong_migrations` should gate any *new* migrations during the upgrade.

---

## 7. Prioritized task list & estimates

FastRuby dual-estimate style (**best / worst** engineer-days). Ranges are wide because
runtime metrics are pending; they tighten to ±20% once the app boots and coverage is
measured. Small codebase keeps most hops short; the ladder length is what accumulates.

| # | Task | Best | Worst | Notes |
|---|---|---:|---:|---|
| 0 | **Boot the app in Docker** (Ruby 2.3/2.6 image, drop `therubyracer`, MySQL, seed) — unblocks everything | 1 | 3 | critical path |
| 1 | **Coverage gate**: add SimpleCov, run suite, backfill characterization tests to ≥60% (auth first) | 4 | 9 | largest item; drives all downstream confidence |
| 2 | **Dual-boot scaffold**: `next_rails`, `Gemfile.next`, `NextRails.next?/current?`, dual CI | 1 | 2 | one-time setup |
| 3 | Hop **4.1 → 4.2** (+ responders) | 0.5 | 1 | smallest |
| 4 | Hop **4.2 → 5.0** (ApplicationRecord, controller-testing gem, params, `belongs_to`) | 2 | 4 | first big API break |
| 5 | Hop **5.0 → 5.1 → 5.2** (+ Ruby 2.4, credentials, mysql2 0.5, devise 4, cancancan/ransack bumps) | 2 | 4 | gem cluster |
| 6 | Hop **5.2 → 6.0** (**Zeitwerk**, + Ruby 2.6/2.7) | 3 | 6 | autoloader rewrite risk |
| 7 | Hop **6.0 → 6.1** | 1 | 2 | usually smooth |
| 8 | Hop **6.1 → 7.0** (**asset pipeline** decision, sprockets→propshaft/importmap, turbolinks→turbo, + Ruby 3.1) | 3 | 6 | second big cluster |
| 9 | Hop **7.0 → 7.1 → 7.2 → 8.0** (+ Ruby 3.3, load_defaults ramps, Solid* / Propshaft) | 3 | 6 | mostly mechanical if 7.0 is clean |
| 10 | **doorkeeper 1.1 → 5.x** OAuth-server migration (may span hops) | 2 | 4 | auth-critical, schema changes |
| 11 | Dependency modernization tail (wicked_pdf/wkhtmltopdf replacement, friendly_id, jbuilder, omniauth-fluxapp vendor) | 2 | 4 | |
| 12 | **Dual-CI verify + regression pass + handoff docs** | 1 | 2 | |
| | **Totals** | **~25.5** | **~53** | call it **~28–48 eng-days** with coordination overhead |

**Parallel wedge (optional, not on critical path):** full **security audit** (brakeman
+ bundler-audit + ruby_audit + bundler-leak) → **2–3 eng-days**, sellable standalone.

---

## 8. Immediate next actions

1. **Unblock the environment (Task 0).** Dockerize Ruby 2.3 (or 2.6 as first Ruby bump)
   + MySQL, remove `therubyracer`, get `bundle install` + `rails server` + the test
   suite green. **Nothing in this Roadmap is verifiable until this is done** — and it
   replaces every `PENDING(env)` marker with a real number.
2. **Finalize the Roadmap to v1** — with the app booting, run `next_rails`, SimpleCov,
   `rails_stats`, and `skunk`; replace the `PENDING(env)` cells; tighten §7 estimates.
3. **File the task list as beads** (this repo has `.beads/`), one issue per §7 row with
   parent/blocks DAG (Task 0 blocks all; Task 1 blocks the hops) and an intelligence-tier
   tag per issue. The beads DAG becomes the upgrade orchestrator.
4. **Open the first OpenSpec change** for Task 0 (Dockerized boot) via `/openspec-propose`.

---

## Appendix — provenance

- **Verified statically (final):** codebase sizing (§2), gem versions (§4, from
  `Gemfile`/`Gemfile.lock`), version-gap ladder (§3), Ruby 2.3 EOL, OmniAuth <2.0 CSRF,
  git-sourced `omniauth-fluxapp`, absence of SimpleCov, environment non-boot (Ruby 2.3
  missing + `bundle check` unresolvable on this machine).
- **`PENDING(env)` — needs a bootable app:** exact SimpleCov %, `next_rails` deprecation
  counts, `rails_stats`, SkunkScore hotspots, `bundler-audit`/`ruby_audit`/`bundler-leak`
  results, per-hop test-failure counts.
- **Tooling not yet run** (blocked on env): `next_rails`, `skunk`, `rails_stats`,
  `simplecov`, `brakeman`, `bundler-audit`, `ruby_audit`, `bundler-leak`.
