---
title: fluxday — Upgrade Engagement Handoff
type: handoff
status: final
client: fluxday (Foradian, open-source OKR/task tracker)
prepared: 2026-07-13
starting_stack: Rails 4.1.16 / Ruby 2.3.0 / MySQL (mysql2 0.3.21)
ending_stack: Rails 8.0.5 / Ruby 3.3.11 / MySQL 5.6 (mysql2 0.5.7)
methodology: FastRuby-style — coverage gate → dual-boot → one-minor-at-a-time → dual-CI verify
---

# fluxday — Upgrade Engagement Handoff

This is the closing deliverable for the engagement scoped in `engagement/roadmap.md`
(the audit/estimate) and `engagement/proposal.md`. The roadmap's 13-task plan (Tasks
0–12) is **complete**. This document is the maintainer-facing summary: what changed,
current health, what was deliberately *not* done, and what to watch.

---

## 1. Starting state → ending state

| | Start | End |
|---|---|---|
| Rails | 4.1.16 | 8.0.5 |
| Ruby | 2.3.0 (EOL Mar 2019) | 3.3.11 |
| Autoloader | classic | Zeitwerk |
| Asset pipeline | Sprockets 2.12 | Sprockets 4.x (kept, see §3) |
| Test suite | unrunnable (no boot) | 342 runs / 828 assertions, green |
| Coverage | unmeasured | ~70.8% (SimpleCov, `rails` profile) |
| CI | none | single-leg GitHub Actions, dockerized |

### The hop ladder (commits `fe25d0c` → `f738b73` on `master`)

| Task | Commit | What changed |
|---|---|---|
| 0 | `fe25d0c` | Unblocked Docker boot (removed `therubyracer`, fixed MySQL/config), wired up SimpleCov |
| — | `46dd990` | Fixed controller test infra: Devise test helpers, real-route assertions, coherent fixtures |
| 1 | `a1a69a9` | Backfilled characterization tests to close the ≥60% coverage gate (pinned *current* behavior, not judged) |
| 2 | `7f13d01` | Added the `next_rails` dual-boot scaffold (`Gemfile`/`Gemfile.next`, dual CI) — since **retired** at Task 12, see §2 |
| 3 | `424f920` | Rails 4.1 → 4.2 (responders gem extracted from `respond_to`/`respond_with`) |
| 4 | `1204c57` | Rails 4.2 → 5.0 (`ApplicationRecord`, `rails-controller-testing` for `assigns`/`assert_template`, `ActionController::Parameters` no longer a Hash) |
| 5 | `bfe0a43` | Rails 5.0 → 5.1 → 5.2 + Ruby 2.3 → 2.4 (credentials, mysql2 0.5, devise/cancancan/ransack major bumps) |
| 6 | `808a952` | Rails 5.2 → 6.0 (**Zeitwerk** autoloader, the single largest-risk hop) + Ruby 2.4 → 2.7 |
| 7 | `f1329c2` | Rails 6.0 → 6.1 |
| 8 | `f9a470d` | Rails 6.1 → 7.0 + Ruby 2.7 → 3.1 (Ruby 3.0+ kwargs-separation broke doorkeeper/faraday/cancancan; each fixed by bumping to the first compatible release, not by patching app code) |
| 9 | `a1760c6` | Rails 7.0 → 7.1 → 7.2 → 8.0 + Ruby 3.1 → 3.3 — **the terminal hop**, reaching the roadmap's own `target_stack` |
| 10 | `001d3e5` | Enabled doorkeeper token/secret hashing (`hash_token_secrets`/`hash_application_secrets`, with a plaintext-row fallback) |
| 11 | `f738b73` | Dependency modernization tail: wicked_pdf/wkhtmltopdf fixes (not a replacement — see §3), friendly_id bump, `omniauth-fluxapp` pinned to an explicit git SHA |
| 12 | *(this session)* | Dual-CI verify, flake root-cause + fix, this document |

Each hop commit's own message/diff is the authoritative detailed record — this table is
a summary, not a replacement.

**Ruby-3.0+ kwargs-separation break, repeated pattern:** doorkeeper, faraday, and
cancancan each hit the same class of failure at the Ruby 2.7 → 3.1 bump (Task 8) —
Hash-as-last-positional-arg code that Ruby 3.0 now treats as a real kwargs mismatch.
Each was fixed by bumping to the first upstream release that adjusted its call sites,
not by patching this app's code. Useful pattern to recognize if any transitive dep
still on an old pin ever needs the same Ruby-3 treatment.

---

## 2. Dual-CI: retired, not kept as scaffold

**Decision: single-leg CI.** `.github/workflows/ci.yml` now runs the Minitest suite
once, against `Gemfile` only. `Gemfile.next`/`Gemfile.next.lock` and the `next_rails`
gem have been removed.

**Why retire rather than keep as a forward-looking scaffold:** by the time Task 12
started, `Gemfile` and `Gemfile.next` were supposed to be byte-identical (Task 9 was
the ladder's last hop), but they weren't — Task 11's dependency bumps (friendly_id,
wicked_pdf, omniauth-fluxapp pin) landed in `Gemfile` and were never mirrored into the
otherwise-unused `Gemfile.next`. That's exactly the failure mode a no-op scaffold
invites: nothing exercises the second file, so drift is silent until someone actually
needs it. Rather than re-sync it now and hope the next person remembers to keep it in
sync going forward, it's simpler and more honest to delete it. **If a real next hop
starts** (Rails 8.1+), resurrect the pattern the same way Task 2 originally built it:
`cp Gemfile Gemfile.next`, edit the copy, `bundle lock` it, add `next_rails` back, and
restore a second matrix leg in `ci.yml` — the retired CI workflow's own comment and the
Gemfile's header comment both point back to this.

### A real CI bug found and fixed during verification

Task 12's "verify" step meant actually running each CI step's exact `docker build`/
`docker run` command locally (against the built `Dockerfile.development` image and the
real `fluxday-db` container's network) rather than just reading the YAML. That surfaced
a genuine, **pre-existing** bug, unrelated to the dual-boot retirement:

Each CI step spins up its own throwaway `docker run --rm` container. Gems installed by
the "Bundle install" step land in `/usr/local/lib/ruby/gems/3.3.0` **inside that
container's own writable layer** — not under `/share` (the only path bind-mounted from
the runner's checkout, and the only thing that persists across separate `docker run`
invocations). The moment that container exits, the installed gems are gone. Compounding
it: `.bundle/config` (`force_ruby_platform: true`) only reaches the built image via
`Dockerfile.development`'s `ADD . $APP_HOME`, which runs **after** that same
Dockerfile's own build-time `bundle install` — so even the gems baked into the image at
build time don't yet satisfy `bundle check` once `.bundle/config` becomes active via the
bind mount. In practice this meant `nokogiri`/`ffi`/`mini_portile2` always needed a
`force_ruby_platform` re-resolve, and every subsequent step's fresh container hit
`Bundler::GemNotFound` for exactly those three gems — reproduced locally, confirmed it
was not caused by any Task 12 edit.

**Fix:** each `docker run` step now mounts a shared named Docker volume at
`/usr/local/lib/ruby/gems/3.3.0` (`fluxday-ci-gems-${{ github.run_id }}`, cleaned up at
job end). Docker seeds a new named volume from the image's own directory content on
first mount, so the image's pre-baked gems aren't lost — only the genuinely new
`force_ruby_platform` re-install now persists forward across steps instead of being
discarded each time. Verified end-to-end locally, three separate `docker run`
invocations in sequence, matching the real workflow's step structure exactly:
`bundle install` → `db:create db:test:prepare` → `rake test`, all green.

---

## 3. Test suite health

```
342 runs, 828 assertions, 0 failures, 0 errors, 16 skips
Line Coverage: 70.82% (1114 / 1573)   [SimpleCov, 'rails' profile]
```

Confirmed stable across **14 separate full-suite runs with different `--seed` values**
(1–12, 42, 999) — 0 failures, 0 errors on every run, including the two seeds (`2`, `3`)
that previously reproduced the flake below.

Note: the exact SimpleCov denominator can shift by a handful of lines run-to-run
(1573 vs. 1523 seen during investigation) depending on which code paths a given
random seed happens to execute — same 1114 covered lines either way, just a slightly
different tracked-file snapshot. Not a regression; just how SimpleCov's file-discovery
interacts with random test order. Coverage is comparable hop-to-hop at ~70–73%.

### The 16 skips (all pre-existing, all documented in-file)

- **7x `ObjectivesControllerTest`** — `resources :objectives` is commented out in
  `config/routes.rb`; every action raises `ActionController::UrlGenerationError`.
  Characterization blocked at the routing layer, not a Rails-upgrade regression.
- **7x `KeyResultsControllerTest`** — same cause, `resources :key_results` is
  commented out.
- **2x `CommentsControllerTest`** (`create`, `index`) — `CommentsController` calls a
  Rails-3-era finder, `@task.comments.active.all(:include => :user)`, whose argument
  form was removed in Rails 4 (`ArgumentError: wrong number of arguments`). Predates
  this engagement's Rails floor entirely.

None of these are upgrade fallout — they're routes/code that were already
non-functional in the original 4.1 app and were left alone per the "characterization,
not judgment" discipline from Task 1.

### The flake: found, root-caused, and fixed

**Symptom:** `ProjectsControllerEmployeeAuthorizationTest` intermittently raised
`RuntimeError: Could not find a valid mapping for #<User ...>` — a Devise::Mapping
error — on certain Minitest `--seed` values (reproduced on `--seed=2`, `--seed=3`).
Confirmed pre-existing (reproduces identically on `001d3e5`, before Task 11).

**Root cause:** Rails 7.1+ introduced lazy route drawing
(`Rails::Engine::LazyRouteSet` — routes are only actually drawn the first time
something interacts with `Rails.application.routes`, typically the first `get`/`post`
dispatch). `devise_for :users` in `config/routes.rb` is what populates
`Devise.mappings`, so until routes have been drawn at least once, that hash is empty.
`ActionController::TestCase#process` wraps its dispatch in
`Rails.application.executor.wrap`, which is what triggers the lazy draw — but that
wrap only happens **inside** a test's `get`/`post` call, not during its `setup` block.
Any test that calls `sign_in` in `setup` (many do, via
`Devise::Test::ControllerHelpers`) depends on `Devise.mappings` already being
populated — true on every seed *except* when Minitest's random test order happens to
make that test the very first thing in the whole process to touch anything
Devise-mapping-related. Confirmed by instrumenting `Devise::Mapping.find_scope!`
directly: on a failing seed, `Devise.mappings` was empty for exactly the first 3 calls
(all inside the flaky test class) and became populated from the 4th call onward, for
the rest of the run. This was invisible before Rails 7.1/8.0 (Task 9) because routes
used to be drawn eagerly at boot, before any test ever ran.

**Fix** (`test/test_helper.rb`): one line, `Rails.application.reload_routes!`, added
right after `require 'rails/test_help'`, forcing routes (and therefore
`Devise.mappings`) to be populated once at test-suite boot — restoring the pre-7.1
guarantee that every test's `setup` can rely on Devise routing already being resolved,
regardless of random test order. No test-reordering hack, no rescue/retry, no sleep.

**Verification:** re-ran `--seed=2` and `--seed=3` (previously reproduced the failure)
— both green. Then ran the full suite 14 times total with distinct seeds
(1–12, 42, 999) — 342 runs / 828 assertions / 0 failures / 0 errors / 16 skips on
every single run.

---

## 4. Deliberate non-adoptions (not oversights)

- **Sprockets over Propshaft.** Rails 8's new-app default is Propshaft, but Sprockets
  4.x is fully supported for existing apps. This is a maintenance upgrade, not a
  rebuild — CLAUDE.md's "match the surrounding style" doctrine. Revisit only if a real
  forcing function shows up (Sprockets EOL announcement, a asset bug Propshaft would
  fix).
- **Classic Turbolinks (2.5.4) over Turbo.** The app's `jquery-turbolinks` +
  server-rendered ERB + jQuery stack is untouched; Turbolinks 2's XHRHeaders
  monkeypatch was re-verified working unmodified through Rails 8.0 (Task 9). Turbo is
  a bigger frontend-architecture change than this engagement's scope.
- **No Solid Queue / Solid Cache / Solid Cable.** These are Rails 8's new-app
  defaults, not forced migrations for existing apps. fluxday has no ActiveJob queue
  backend or Action Cable usage to migrate — adopting them here would be new feature
  work, not an upgrade.
- **Doorkeeper: token/secret hashing only, not the rest of the 5.x feature set.**
  Task 10 turned on `hash_token_secrets`/`hash_application_secrets` (with a plaintext
  fallback for pre-existing rows). Deliberately **not** adopted: PKCE,
  `previous_refresh_token`, and scopes-by-grant-type — no concrete need in fluxday's
  single confidential-client OAuth-server usage, and each is additive/opt-in in
  doorkeeper 5.x, not required for the version bump itself. Revisit if a real OAuth
  client integration ever needs PKCE.
- **wkhtmltopdf kept, not replaced.** Investigated at Task 11 (see below) — the two
  actual bugs were app-side (a stale `exe_path` override, and Rails 8's stricter PDF
  layout-lookup), not the PDF engine. No forcing function to justify a Grover/
  ferrum_pdf rewrite exists today.

---

## 5. Known remaining risks / follow-ups

- **`omniauth-fluxapp` is git-sourced from a single, apparently-abandoned repo**
  (`stpnlr/omniauth-fluxapp`, last pushed 2021-10-03, no tags, no rubygems.org
  release). Task 11 pinned the Gemfile to the exact SHA it had already resolved to
  (`a00079af6...`) so a future `bundle update` can't silently drift onto whatever
  `master` becomes if the repo ever gets new commits — but that's a mitigation, not a
  fix. **If this integration ever needs a real upstream bugfix, there's no maintainer
  to ask.** Be ready to fork/vendor it in-repo (`lib/omniauth-fluxapp/` or similar) if
  that day comes; don't wait for an upstream release that likely isn't coming.
- **wkhtmltopdf-binary is long-term unmaintained upstream** (the underlying
  `wkhtmltopdf` project itself, not just the gem, has had no real releases in years).
  It works today — Task 11 verified real, valid PDF output (a `%PDF-` magic-number
  check now lives in `test/controllers/reports_controller_test.rb`) — but if it ever
  breaks on a future OS/arch (the same class of problem that made `therubyracer`
  unrecoverable at Task 0), the replacement path is **Grover** (headless
  Chrome/Playwright-based PDF rendering) or a `ferrum_pdf`-style approach. Not
  currently justified; flagging so a future maintainer doesn't have to re-derive this
  decision from scratch.
- **35 old-style migrations** (pre-Rails-4.2, no explicit version tag) still exist
  from before this engagement. They don't block anything today, but there's no
  `strong_migrations` gate in this repo — any *new* migration should be reasoned about
  for MySQL lock-safety manually (per CLAUDE.md), since nothing will catch an unsafe
  one automatically.
- **CI runs on `ubuntu-latest` GitHub-hosted runners, x86_64.** The from-source Ruby
  3.3.11 build in `Dockerfile.development` takes ~1–2 minutes; this is fine for CI but
  worth knowing if runner minutes ever become a cost concern (a pre-built base image
  with Ruby already compiled would cut this down, at the cost of one more thing to
  maintain).

---

## 6. How to run things

(Pulled from `CLAUDE.md` / the repo's own README — not new conventions.)

### Local dev (Ruby 3.3.11 active via asdf, MySQL reachable)

```bash
bundle install
cp config/app_config.yml.example config/app_config.yml   # first-time config
cp config/database.yml.example config/database.yml        # first-time DB config
rake db:create db:migrate db:seed   # seeds admin@fluxday.io / password
rails server                        # http://localhost:3000
```

### Docker (the supported alternative; MySQL 5.6 via docker-compose)

```bash
docker-compose up -d --build --remove-orphans
docker exec -it fluxday-app /bin/bash
```

### Tests (Minitest, not RSpec)

```bash
rake test                                              # full suite
rake test TEST=test/models/task_test.rb                # single file
rake test TEST=test/models/task_test.rb TESTOPTS="--name=/pattern/"  # single test
rake test TESTOPTS="--seed=<n>"                        # reproduce a specific order
```

### CI

Push/PR to `main`/`master` triggers `.github/workflows/ci.yml` — one job, builds
`Dockerfile.development`, runs `bundle install` / `db:create db:test:prepare` /
`rake test` against a `mysql:5.6` service container, all three steps sharing gems via a
per-run named Docker volume (see §2).

---

## 7. Engagement close-out

All 13 roadmap tasks (0–12) are complete. The app runs Rails 8.0.5 / Ruby 3.3.11 with a
green, stable 342-test Minitest suite (0 failures, 0 errors across 14 differently-seeded
runs) and dockerized single-leg CI verified end-to-end via real `docker build`/`docker
run` invocations, not just YAML review. Two real bugs were found and fixed along the way
that weren't explicitly scoped but were directly in the path of "make CI trustworthy":
the Devise-mapping test-order flake (§3) and the cross-step gem-persistence CI bug (§2).
Everything else in this document is a deliberate, reasoned call — not an oversight —
with the reasoning left in place (in commit messages, Gemfile comments, and this file)
for whoever picks this up next.
