# Migrating existing MySQL data to PostgreSQL

This documents the procedure for moving a fluxday database that already has
real data (a dev seed, staging, or production copy) from MySQL to
PostgreSQL, now that the app itself runs exclusively on PostgreSQL (see
`openspec/changes/migrate-to-postgres/`).

**Fresh environments do not need any of this.** If there's no existing
MySQL data worth keeping, just run:

```bash
export DB_NAME=fluxday DB_HOST=127.0.0.1 DB_USER=$(whoami) DB_PASS=""
rake db:create db:migrate db:seed
```

The rest of this doc is for environments with real MySQL data to carry
over.

## Why pgloader, and why schema-first

[pgloader](https://pgloader.io/) can both create the target schema *and*
copy data in one pass, but this procedure deliberately does **not** let it
create the schema. Rails' own migrations (`db/schema.rb`) are the single
source of truth for column types, constraints, and indexes — pgloader's
automatic MySQL→PostgreSQL type mapping does not reliably reproduce what
Rails migrations actually produce (e.g. it would need to independently
reverse-engineer `friendly_id_slugs.sluggable_type`'s `limit: 50`, the
`is_deleted`/`approved`/`confidential`/`delete_request` boolean columns,
and every foreign key Rails already declares). So the target schema is
loaded from `db/schema.rb` first, and pgloader is told to load **data
only**.

## Prerequisites

```bash
brew install pgloader
```

(On first install on macOS you may see `Failed applying an ad-hoc
signature` from Homebrew's `brew install` — this is a benign warning about
codesigning, not an install failure; `pgloader --version` still works.)

You need:
- Read access to the source MySQL database (host/port/user/pass/db name).
- A PostgreSQL database matching the app's `config/database.yml`
  credentials, migrated to the current schema (`rake db:schema:load`).

## Procedure

### 1. Load the Rails-authoritative schema into a fresh Postgres database

```bash
export DB_NAME=fluxday DB_HOST=127.0.0.1 DB_USER=$(whoami) DB_PASS=""
rake db:create db:schema:load
```

This creates every table via `db/schema.rb` — the exact structure Rails
expects, with no data yet.

### 2. Write a pgloader load script

```lisp
LOAD DATABASE
     FROM mysql://<mysql_user>:<mysql_pass>@<mysql_host>:3306/<mysql_db>
     INTO postgresql://<pg_user>:<pg_pass>@<pg_host>:5432/<pg_db>

WITH data only,
     truncate,
     reset sequences,
     workers = 4, concurrency = 1

SET PostgreSQL PARAMETERS
    maintenance_work_mem to '128MB',
    work_mem to '12MB'
;
```

- `data only` — do not create/alter any schema objects; the target schema
  from step 1 is authoritative.
- `truncate` — empty each target table immediately before loading it (safe
  because this is a one-shot data load into a freshly-migrated, otherwise
  empty database — never run this against a database with data you want to
  keep).
- `reset sequences` — after loading, advance every `<table>_id_seq` to
  `MAX(id) + 1` so the next Rails-side `INSERT` doesn't collide with a
  migrated row's primary key.

### 3. Run it

```bash
pgloader path/to/fluxday-migrate.load
```

Expect a per-table summary at the end. **0 errors is the bar** — any
non-zero `errors` column needs investigating before proceeding (don't
treat a partial load as good enough).

pgloader will print `WARNING` lines about `timestamp` vs `timestamptz` /
`time` vs `time without time zone` type coercion — these are expected and
harmless: Rails' schema uses timezone-naive columns
(`t.datetime`/`t.time`), pgloader is just noting it's adapting MySQL's
(also timezone-naive) `datetime`/`time` values into them.

### 4. Verify

Row counts, per table (must match exactly):

```bash
for t in $(psql -U $DB_USER -d $DB_NAME -t -A -c "select tablename from pg_tables where schemaname='public'"); do
  m=$(mysql -u <mysql_user> -N -e "select count(*) from $t" <mysql_db>)
  p=$(psql -U $DB_USER -d $DB_NAME -t -A -c "select count(*) from $t" | head -1)
  echo "$t: mysql=$m pg=$p"
done
```

Boolean / soft-delete flags survive the `tinyint(1)` → `boolean` cast
(spot-check `is_deleted`, `approved`, `confidential`, `delete_request` —
the full list of boolean columns in this schema):

```sql
-- MySQL: 0/1
select id, is_deleted from tasks order by id limit 5;
-- Postgres: f/t (same rows, same order)
select id, is_deleted from tasks order by id limit 5;
```

Sequence audit — every serial PK's sequence must be at or above the
migrated `MAX(id)`, or the first real Rails `INSERT` after cutover will
collide with a migrated row:

```sql
select 'tasks' t, (select max(id) from tasks) maxid, (select last_value from tasks_id_seq) seqval
union all select 'users', (select max(id) from users), (select last_value from users_id_seq)
union all select 'work_logs', (select max(id) from work_logs), (select last_value from work_logs_id_seq)
union all select 'okrs', (select max(id) from okrs), (select last_value from okrs_id_seq);
-- repeat for any other table you're specifically worried about;
-- `reset sequences` in the load script handles this for every table,
-- this query is just the audit/confirmation step.
```

Post-load insert sanity check (confirms no PK collision in practice, not
just in the audit query):

```sql
INSERT INTO okrs (user_id, name, start_date, end_date, is_deleted, created_at, updated_at)
VALUES (1, 'post-load insert test', now(), now(), false, now(), now())
RETURNING id;
-- id returned must be MAX(id)+1, not a collision/duplicate-key error
```

## Verified against a local copy (2026-07-13)

This procedure was run end-to-end against a full `mysqldump`/restore copy
of the local `fluxday` MySQL database (`fluxday_migration_test`), loaded
into a freshly `db:schema:load`-ed Postgres database of the same name:

- pgloader: **0 errors**, all 21 tables loaded (71 rows total in this
  particular copy).
- Row counts matched exactly between MySQL and Postgres for every table
  (`ar_internal_metadata`, `comments`, `friendly_id_slugs`, `key_results`,
  `oauth_access_grants`, `oauth_access_tokens`, `oauth_applications`,
  `objectives`, `okrs`, `project_managers`, `projects`,
  `reporting_managers`, `task_assignees`, `task_key_results`, `tasks`,
  `team_members`, `teams`, `user_oauth_applications`, `users`,
  `work_logs`).
- `is_deleted` flags spot-checked on `tasks`: MySQL `0` → Postgres `f`,
  correctly cast, same rows.
- Sequence audit: `tasks`, `users`, `work_logs`, `okrs` sequences all
  landed exactly at their table's `MAX(id)` after `reset sequences`.
- Post-load `INSERT` into `okrs` returned the next sequential id with no
  collision.

## Rollback

MySQL databases are never modified or dropped by this procedure — it only
reads from MySQL and writes to a (freshly schema-loaded, then truncated)
Postgres database. If the Postgres load needs to be redone, just re-run
`rake db:schema:load` against a clean Postgres database and re-run
pgloader; if the whole migration needs to be abandoned, point
`config/database.yml`/env vars back at the untouched MySQL database and
`git revert` the adapter-swap commits.
