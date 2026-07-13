# Tasks: migrate-to-postgres

> Execute via the project-local `pg-migrator` agent, which loads the
> `mysql-to-postgres` skill (inventory, gotchas, verification ladder).
> Each numbered group lands as its own commit with verification evidence.

## 1. Baseline (on MySQL, before touching anything)

- [x] 1.1 Run the full `rake test` suite on MySQL and record the exact failure set (test names, not just count) to `openspec/changes/migrate-to-postgres/baseline-mysql.txt`
- [x] 1.2 Install and start local PostgreSQL (`brew install postgresql@17 && brew services start postgresql@17`); confirm `psql` connects

## 2. Adapter and configuration swap

- [x] 2.1 Replace `mysql2` with `pg` in the Gemfile via `bundle add pg` (latest stable); confirm the native extension builds
- [x] 2.2 Update `config/database.yml` and `config/database.yml.example`: `adapter: postgresql`, `encoding: unicode`, port 5432, rewritten header comments
- [x] 2.3 `rake db:create db:migrate` against local Postgres; commit the regenerated `db/schema.rb` (verify: no `charset:` options, diff shows only adapter-mechanical changes)
- [x] 2.4 `rake db:seed`; verify admin@fluxday.io sign-in works via `rails server` + curl of the login flow (include the `X-XHR-Referer` Turbolinks redirect check from CLAUDE.md)

## 3. Behavior parity verification

- [x] 3.1 Run the full `rake test` suite on Postgres; diff the failure set against `baseline-mysql.txt`; burn down any new failures to set-diff-empty
- [x] 3.2 Add a Minitest case locking case-insensitive Ransack `*_cont` task search (mixed-case query must match), and confirm it passes on Postgres
- [x] 3.3 Re-run the `/teams` and `/projects` controller tests explicitly (DISTINCT + ordered-`default_scope` landmine) and exercise both pages in a booted server
- [x] 3.4 Grep `\.group\(` call sites and run their covering tests (Postgres GROUP BY strictness)

## 4. Docker

- [x] 4.1 Swap `docker-compose.yml` `fluxday-db` service from `mysql:5.6` to current stable `postgres` (alpine), port 5432, PG data volume path, `pg_isready`-based healthcheck
- [x] 4.2 Convert `db.env.example` (and local `db.env`) from `MYSQL_*` to `POSTGRES_*` variables; update `app.env.example` DB vars if needed
- [x] 4.3 Replace `libmysqlclient-dev` with `libpq-dev` in `Dockerfile.development`
- [x] 4.4 `docker-compose up -d --build --remove-orphans`; verify the app container migrates, seeds, and serves the login page end-to-end

## 5. CI

- [ ] 5.1 Swap the `.github/workflows/ci.yml` MySQL service for a `postgres` service container (health-checked, port 5432, `POSTGRES_*` env); update `DB_*` env passed to the rake/test steps and rewrite the workflow's MySQL-era header comments
- [ ] 5.2 Push the branch and confirm a green CI run on Postgres

## 6. Data migration path

- [x] 6.1 Write `doc/mysql-to-postgres-data-migration.md`: pgloader procedure with Rails-authoritative schema (`db:schema:load` first, then pgloader `data only, truncate, reset sequences`), including the sequence-audit and row-count/boolean spot-check queries
- [x] 6.2 Verify the procedure against a copy of the local MySQL fluxday database: row counts match, `is_deleted` flags intact, post-load INSERT succeeds without sequence collision

## 7. Documentation and cleanup

- [ ] 7.1 Update CLAUDE.md and AGENTS.md (mirror both): stack line (MySQL → PostgreSQL), local dev env vars/commands, Docker notes; update README if it mentions MySQL
- [ ] 7.2 Update `.claude/agents/rails-engineer.md` (stack description + the MySQL-strict-mode landmine note now applies as Postgres DISTINCT behavior) and the `local-non-docker-dev...` bd memory (`bd remember --key ...`)
- [ ] 7.3 Remove `baseline-mysql.txt` scratch artifact from the change dir if committed; final `git status` review and handoff (no push without explicit authority)
