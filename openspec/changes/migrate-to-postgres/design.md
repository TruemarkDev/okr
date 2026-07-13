# Design: Migrate fluxday from MySQL to PostgreSQL

## Context

fluxday is a Rails 8.0 / Ruby 3.3 monolith (upgraded hop-by-hop from Rails 4.1) still running MySQL: brew MySQL locally, EOL `mysql:5.6` in Docker Compose and GitHub Actions CI. A full codebase survey (2026-07-13) established the actual MySQL coupling:

- `Gemfile:23` — `mysql2 ~> 0.5.7` (plus `Gemfile.lock` resolutions).
- `config/database.yml(.example)` — `adapter: mysql2`, `encoding: utf8`, MySQL-era header comments.
- `db/schema.rb` — `charset: "utf8mb3"` on all 20 `create_table` calls; one benign `limit: 50` string.
- `docker-compose.yml` — `mysql:5.6` service + `MYSQL_*` vars in `db.env(.example)`; `Dockerfile.development:52` installs `libmysqlclient-dev`.
- `.github/workflows/ci.yml` — `mysql:5.6` service container, port 3306, `MYSQL_*` env.
- **No raw SQL anywhere**: no `find_by_sql`, `connection.execute`, `GROUP_CONCAT`/`DATE_FORMAT`/backtick identifiers in `app/` or `db/`. No unsigned/ENUM/fulltext schema features.
- Ransack `*_cont` search (`Task` search from `home_controller`) relies on MySQL's case-insensitive `LIKE` — the one behavioral (not compile-level) coupling.

Execution tooling: the project-local `pg-migrator` agent (`.claude/agents/pg-migrator.md`) drives the `mysql-to-postgres` skill (`.claude/skills/mysql-to-postgres/SKILL.md`), which carries this inventory, the gotcha list, and the verification ladder.

## Goals / Non-Goals

**Goals:**
- fluxday runs exclusively on PostgreSQL across local dev, Docker Compose, and CI.
- Behavior parity: same test-suite results (set-diff-empty vs. a recorded MySQL baseline), same search case-insensitivity, same page behavior on the known DISTINCT+ORDER BY hot spots (`/teams`, `/projects`).
- A verified data-migration path for environments holding real MySQL data.
- Updated dev docs (CLAUDE.md + AGENTS.md mirrored, README) and bd memory.

**Non-Goals:**
- No dual-adapter/backward-compat support — MySQL is removed outright.
- No Rails/Ruby/gem bumps beyond `mysql2`→`pg`, no `strong_migrations`, no `structure.sql`, no UUID PKs, no index/collation tuning "while we're here."
- No production deployment execution (fluxday is a lab project; the pgloader path is documented and verified against a local copy, not run against a live prod).

## Decisions

1. **`pg` gem at latest stable via `bundle add pg`** (not a hand-pinned version) — per the standing rule to install newest stable for new deps. Alternative (pin to a training-memory version) rejected.
2. **Regenerate `db/schema.rb` from `rake db:migrate` against a fresh Postgres DB** rather than hand-editing the charset options out. The regenerated file is the artifact; review is regenerated-vs-old diff. Hand-editing risks drift between schema.rb and what the adapter actually produces.
3. **Rely on Ransack's adapter-aware `cont` predicate (ILIKE on PG) but prove it with a test** — add a Minitest case doing a mixed-case search that would fail under case-sensitive `LIKE`. Alternative (`citext` columns or `lower()` functional indexes) rejected as over-engineering for parity; revisit only if the test disproves the assumption.
4. **`postgres:17-alpine` (or newest stable at implementation time) in Docker/CI**, health-checked with `pg_isready`, replacing the EOL `mysql:5.6`. Compose keeps the same service name (`fluxday-db`) so app-container wiring changes stay minimal.
5. **Data migration via pgloader, with the Rails schema authoritative**: `rake db:schema:load` on the PG side first, then pgloader in `data only, truncate, reset sequences` mode. Alternative (let pgloader create the schema) rejected — pgloader's type mapping wouldn't match what Rails migrations produce, and schema.rb must remain the single source of truth. Fresh/dev environments skip pgloader entirely (`db:create db:migrate db:seed`).
6. **Baseline-first verification discipline**: record the exact MySQL failure set (not just count) before touching the adapter; after migration the PG failure set minus baseline must be empty. Same discipline as the repo's Rails-hop history.
7. **Single change, laned commits**: gem/config → schema regen → Docker → CI → docs/data-path, each landing with verification evidence. Small enough surface not to warrant multiple OpenSpec changes or an em fan-out.

## Risks / Trade-offs

- [Ransack `cont` doesn't use ILIKE on some predicate we use] → the parity test catches it; fallback is explicit `i_cont`-based ransackers or a predicate override, decided then, not preemptively.
- [Implicit row-order differences (MySQL InnoDB PK order vs. PG arbitrary order) flake fixtures-based tests] → baseline set-diff isolates exactly which tests; fix by adding explicit `order` to the query or assertion, never by loosening assertions.
- [DISTINCT + ordered `default_scope` (documented `/teams`, `/projects` landmine) also errors on PG] → the existing `reorder(nil)` fixes are adapter-agnostic; covering controller tests are explicitly re-run in the verification ladder.
- [pgloader boolean/tinyint(1) mapping mismatch corrupts `is_deleted`-style flags] → with Rails-created schema + `data only` mode, pgloader casts into existing boolean columns; verify with row-count + spot-check queries per table after load.
- [Sequences not advanced after data load → duplicate-PK errors on first INSERT] → pgloader `reset sequences` + an explicit post-load audit (`SELECT last_value FROM <seq>` vs `MAX(id)`).
- [`pg` native extension fails to build] → needs `libpq` (brew) / `libpq-dev` (Debian) — captured in Dockerfile change and docs.
- [Developer machines still on MySQL] → docs updated in same change; MySQL DB is not dropped by the migration, so rollback is `git revert` + point back at the untouched MySQL DB.

## Migration Plan

1. Record MySQL test baseline (failure set to a scratch file).
2. Swap gem + database.yml; create/migrate/seed against local PG; regenerate schema.rb.
3. Full suite on PG; burn down any set-diff to empty; add the Ransack parity test.
4. Swap Docker Compose + Dockerfile dep; `docker-compose up` end-to-end boot check.
5. Swap CI service; green run on branch.
6. Verify pgloader path against a copy of the local MySQL data; document it.
7. Update CLAUDE.md/AGENTS.md/README + bd memory (`local-non-docker-dev...`).

**Rollback:** revert the branch; MySQL databases are never dropped or written to by this change.

## Open Questions

- None blocking. (Exact `postgres` image tag and `pg` gem version resolve to "latest stable" at implementation time.)
