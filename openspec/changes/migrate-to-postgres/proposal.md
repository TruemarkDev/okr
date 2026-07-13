# Migrate fluxday from MySQL to PostgreSQL

## Why

fluxday has been carried from Rails 4.1 to Rails 8.0, but still runs on MySQL — locally against brew MySQL, in Docker/CI against the EOL `mysql:5.6` image (unsupported since 2021, a growing security and availability liability). PostgreSQL is the ecosystem-default for modern Rails, removes the EOL image dependency, and a July 2026 codebase survey confirmed the migration surface is small: no raw SQL, no `find_by_sql`/`connection.execute`, and no MySQL-only column types anywhere in the app.

## What Changes

- **BREAKING**: The `mysql2` gem is replaced with `pg` (latest stable); MySQL is no longer a supported backend — no dual-adapter support.
- `config/database.yml(.example)` switches to `adapter: postgresql` / `encoding: unicode` / port 5432, with the stale MySQL-era header comments rewritten.
- `db/schema.rb` is regenerated against Postgres, dropping the MySQL-only `charset: "utf8mb3"` option from all 20 `create_table` calls.
- `docker-compose.yml` swaps `mysql:5.6` for a current `postgres` image; `db.env(.example)` moves to `POSTGRES_*` variables; `Dockerfile.development` swaps `libmysqlclient-dev` for `libpq-dev`.
- `.github/workflows/ci.yml` swaps the MySQL service container for a Postgres one (health-checked via `pg_isready`).
- Search behavior parity is preserved: Ransack `*_cont` predicates must remain case-insensitive under Postgres (`ILIKE`), matching current MySQL behavior.
- A documented data-migration path (pgloader, Rails schema authoritative, sequences reset) for environments holding real data.
- Dev docs (`CLAUDE.md`/`AGENTS.md`, README) updated for local Postgres setup.

## Capabilities

### New Capabilities
- `postgres-database`: fluxday runs exclusively on PostgreSQL — connection configuration, schema compatibility, behavior parity (search case-insensitivity, distinct+order queries, test-suite baseline), Docker/CI services, and the data-migration path from an existing MySQL database.

### Modified Capabilities

None — `openspec/specs/` is currently empty; there are no existing capability specs to modify.

## Impact

- **Dependencies**: `mysql2` removed; `pg` added (native extension needs `libpq`/`libpq-dev`).
- **Config**: `config/database.yml(.example)`, `db.env(.example)`, `docker-compose.yml`, `Dockerfile.development`, `.github/workflows/ci.yml`.
- **Schema**: `db/schema.rb` regenerated (charset options dropped); no migration files change.
- **Runtime behavior to verify, not change**: Ransack search case-sensitivity, the known DISTINCT + ordered-`default_scope` query shapes (`/teams`, `/projects`), implicit result ordering in fixtures-based tests.
- **Environments**: every developer, Docker, and CI environment must provision Postgres; existing MySQL data requires the pgloader migration path.
- **Tooling**: executed by the project-local `pg-migrator` agent driving the `mysql-to-postgres` skill (both added alongside this proposal).
