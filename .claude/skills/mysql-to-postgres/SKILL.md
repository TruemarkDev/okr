---
name: mysql-to-postgres
description: Migrate fluxday's database from MySQL to PostgreSQL — adapter/gem swap, schema.rb charset cleanup, Docker/CI service swap, data migration via pgloader, and the fluxday-specific verification gates (Ransack LIKE case-sensitivity, DISTINCT+ORDER BY landmine re-check, full Minitest suite, boot-and-curl smoke). Use when executing or reviewing any part of the migrate-to-postgres OpenSpec change.
---

# MySQL → PostgreSQL migration (fluxday)

The full MySQL surface of this repo was inventoried on 2026-07-13 (see
`openspec/changes/migrate-to-postgres/design.md`). There is **no raw SQL, no
`find_by_sql`/`connection.execute`, no MySQL-only column types (no unsigned,
no ENUM, no fulltext)** in the app — the migration is config/tooling-shaped,
plus behavioral verification. Do not invent work beyond this surface without
re-grepping first.

## The complete change surface

| Area | File(s) | Change |
|---|---|---|
| Gem | `Gemfile` (`mysql2 ~> 0.5.7`) | Replace with `pg` — install latest stable via `bundle add pg` (never hand-pin an old version) |
| DB config | `config/database.yml`, `config/database.yml.example` | `adapter: postgresql`, `encoding: unicode`, port 5432; rewrite the stale MySQL header comments |
| Schema | `db/schema.rb` | Strip `charset: "utf8mb3"` from all 20 `create_table` calls; regenerate via `rake db:migrate` against Postgres and diff — never hand-edit beyond what a clean regeneration produces. `limit: 50` on `friendly_id_slugs.sluggable_type` is valid in PG; leave it |
| Docker | `docker-compose.yml` (`mysql:5.6`), `db.env(.example)` | `postgres:17-alpine` (or latest stable), `POSTGRES_*` env vars, port 5432, named volume path `/var/lib/postgresql/data` — **on `postgres:18-alpine`+ the image switched its internal data-dir layout (`PGDATA` needs an explicit subdirectory, e.g. `/var/lib/postgresql/data/pgdata`, mounting the volume straight at `/var/lib/postgresql/data` fails to init); check the image's own docs for the version actually pulled, don't assume the 17-era layout** |
| Dockerfile | `Dockerfile.development` (`libmysqlclient-dev`) | Replace with `libpq-dev` |
| CI | `.github/workflows/ci.yml` (mysql:5.6 service) | `postgres` service image with `POSTGRES_PASSWORD`, health-check via `pg_isready`, port 5432; update the header comments |
| Local dev docs | `CLAUDE.md`, `AGENTS.md` (mirror both!), README if it mentions MySQL | brew `postgresql@17`, `DB_USER=$(whoami)` / no password default; also update the `local-non-docker-dev...` bd memory |

## Behavioral gotchas to verify (not just compile-level)

1. **Ransack/`LIKE` case-sensitivity.** MySQL `LIKE` is case-insensitive
   (utf8 collations); Postgres `LIKE` is case-sensitive. Ransack's `*_cont`
   predicates (e.g. `tracker_id_or_name_or_description_cont` used from
   `home_controller` search) will silently become case-sensitive. Decision:
   keep behavior parity — configure Ransack to use `ILIKE` on PG (ransack
   does this automatically for the `cont` predicate on the postgres adapter —
   **verify with a real mixed-case search test**, don't assume).
2. **The DISTINCT + ordered-default_scope landmine** (documented in
   `.claude/agents/rails-engineer.md`): Postgres rejects
   `SELECT DISTINCT ... ORDER BY <col not in select>` just like MySQL strict
   mode — the existing `reorder(nil)` fixes must keep passing. Re-run the
   `/teams` and `/projects` controller tests specifically.
3. **Implicit ordering.** MySQL InnoDB often returns PK order without ORDER
   BY; Postgres returns arbitrary order. Any test or view relying on
   un-ordered query order may flake. `Task` has `default_scope order id desc`
   so it's safe; watch fixtures-based assertions on other models.
4. **`0`/`1` boolean columns and `is_deleted`** — Rails abstracts this; no
   action needed, but if any fixture YAML uses `0`/`1` for booleans confirm
   fixtures still load (`rake db:fixtures:load` in test env is exercised by
   the suite anyway).
5. **GROUP BY strictness.** Postgres requires every non-aggregated select
   column in GROUP BY. Survey found no raw SQL, but `.group(...)` AR calls
   should be smoke-checked — grep `\.group\(` and run the covering tests.
6. **`&&` as logical AND in raw `where()` string fragments.** The initial
   design.md survey said "no raw SQL" and that held for `find_by_sql`/
   `connection.execute`/backtick identifiers — but it missed `where('... &&
   ...')` string fragments in several controllers (`home`, `calendar`,
   `work_logs`, `tasks`, `teams`, `reports`), which use MySQL's `&&` as a
   logical-AND alias for `AND`. MySQL accepts it; Postgres parses `&&` as the
   *array-overlap* operator and throws, which 500'd `HomeController#index` —
   the post-login dashboard — immediately on Postgres. Grep
   `where\(['"].*&&` across `app/controllers` and replace with `AND`
   (semantically identical on both adapters, so safe to land pre-emptively
   rather than wait for it to surface as a failing request).

## Data migration (existing environments)

For dev/staging/prod databases with real data, use **pgloader** (brew
install pgloader) with a load script: mysql → postgresql, `with quote
identifiers, data only` is NOT enough — let pgloader create nothing; instead
create the schema with `rake db:schema:load` on the PG side first, then
pgloader `data only, truncate` so the Rails-generated schema (correct types,
sequences) is authoritative. Afterwards **reset sequences**:
pgloader handles this with `reset sequences`; verify with an INSERT on each
table with data (or `SELECT setval(...)` audit query). The seeded-dev-only
path can skip pgloader entirely: `rake db:create db:migrate db:seed`.

## Verification ladder (in order, all must pass)

1. `bundle install` resolves; `pg` native ext builds (needs `brew install libpq postgresql@17` locally, `libpq-dev` in Docker).
2. `rake db:create db:migrate` against Postgres → regenerated `db/schema.rb` has no `charset:` options and no unexpected diffs.
3. `rake db:seed` → admin@fluxday.io login works.
4. Full `rake test` suite green — compare failure count to the pre-migration baseline on MySQL (record the baseline FIRST).
5. Boot `rails server` and curl `/` (login page), plus a Turbolinks-header redirect check per CLAUDE.md.
6. Mixed-case Ransack search returns the same results as on MySQL.
7. `docker-compose up` end-to-end boots with the Postgres service.
8. CI workflow green on a branch push.

## Anti-goals

- Do NOT bump Rails/Ruby/other gems as a side effect (repo rule).
- Do NOT introduce `strong_migrations`, structure.sql, or UUID PKs "while
  we're here" — this change is adapter parity only.
- Do NOT keep dual-adapter support; MySQL is removed, not optioned.
