# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

fluxday is an OKR + task/productivity tracker (Foradian, open-sourced 2016). It started life
as a **legacy Rails 4.1 app on Ruby 2.3.0** and has since been carried, hop by hop, up to
**Rails 8.0 / Ruby 3.3 / MySQL** (see the `roadmap Task 0`–`Task 12` commits in git log and the
history comment at the top of `config/application.rb`). This is still a maintenance codebase,
not greenfield — match the surrounding style of the file you're editing — but the framework
itself is current, so use modern Rails 8 idioms (`before_action`, strong params, Zeitwerk) going
forward rather than legacy Rails 4 ones.

- Ruby is pinned to **3.3.11** via `.ruby-version` / `.tool-versions` (asdf/mise).
- Rails **8.0** (`before_action`, not `before_filter`; strong params, not `attr_accessible`;
  `mysql2 ~> 0.5.7`).
- Server-rendered ERB views + Foundation 5 + jQuery + Turbolinks + CoffeeScript. No SPA.

## Commands

Local dev assumes Ruby 3.3.11 is active (asdf/mise) and MySQL is reachable.

```bash
bundle install                 # install gems
cp config/app_config.yml.example config/app_config.yml   # first-time config (Google OAuth optional)
cp config/database.yml.example config/database.yml        # first-time DB config
rake db:create db:migrate db:seed   # seeds an admin@fluxday.io / password user
rails server                   # http://localhost:3000
```

### Tests (Minitest, not RSpec)

Tests live in `test/` (`models/`, `controllers/`, `integration/`, `mailers/`, `helpers/`)
with `test/fixtures/*.yml` loaded for all tests via `test/test_helper.rb`.

```bash
rake test                              # full suite
rake test TEST=test/models/task_test.rb        # single file
rake test TEST=test/models/task_test.rb TESTOPTS="--name=/pattern/"   # single test by name
```

### Docker

Docker Compose is the supported alternative for local dev (MySQL 5.6). Requires
`app.env` and `db.env` (copy from the `.example` files first).

```bash
docker-compose up -d --build --remove-orphans
docker exec -it fluxday-app /bin/bash    # shell into the app container
```

## Architecture

### Domain model (the OKR core)

The whole app hangs off a strict OKR hierarchy owned by a `User`:

```
User → Okr → Objective → KeyResult → (task_key_results) → Task → WorkLog
```

- **`Okr`** owns `Objective`s (nested attributes) which own `KeyResult`s. `Okr#update_children`
  cascades `user_id`/`start_date`/`end_date` down to objectives and key results on every save —
  the OKR is the source of truth for those fields.
- **`Task`** joins to `KeyResult` through `task_key_results` (many-to-many). A task's
  "assignees" are derived: `Task#users` = users of its key results; `User#assignments` =
  tasks reached through the user's key results. There is no direct task-assignee table in use
  (the `task_assignees` associations are commented out).
- **Tasks are self-referential**: `root_task`/`sub_tasks` via `task_id`. Subtasks use
  `scope :sub`; top-level use `scope :root`.
- **Soft deletes everywhere**: models carry `is_deleted` and use `scope :active`. `Task` even
  has a `default_scope` excluding deleted rows and ordering `id desc` — be aware this scope is
  always applied; use `Task.unscoped` to bypass it.
- **Org structure**: `Project → Team → TeamMember (role: lead)`, plus `ReportingManager`
  (self-referential manager↔employee) and `ProjectManager`. `User#admin_team_ids`,
  `project_ids`, `team_ids`, `user_ids` (reporting-employee ids) drive most visibility scoping.

### Authorization

- **Devise** for auth (`authenticate_user!` is a global `before_action` in
  `ApplicationController`) plus **omniauth-google-oauth2** for Google login.
- **CanCanCan** for authorization — all rules live in `app/models/ability.rb`, keyed off the
  three roles: `admin` / `manager` (both effectively `can :manage, :all`) and `employee`
  (scoped to their own OKRs/tasks and their reporting employees + project/team membership).
  `User#admin?`/`manager?`/`employee?` downcase the `role` string. Access-denied redirects to
  root with an alert.
- **Data scoping** for employees flows through the `User` association helpers above and
  `Task.searchable_for_user` — when adding queries that must respect visibility, reuse those,
  don't re-derive the SQL.

### API + OAuth server

- fluxday is itself an **OAuth2 provider** via **Doorkeeper** (`use_doorkeeper` in routes,
  `oauth_applications` managed in the UI). It also acts as an OAuth client to an external
  fluxapp (`omniauth-fluxapp`, `omniauth-oauth2`).
- The token-authenticated API lives under `app/controllers/api/v1/`
  (`api_controller.rb`, `credentials_controller.rb`) — this is the filtered-access surface
  referenced in the README, separate from the session-based web controllers.

### Notable pieces

- **Reports** (`ReportsController`) is a large read-only surface — many bespoke GET actions
  (activities, employee/day ranges, tasks, OKRs, worklogs, assignments) wired individually in
  `config/routes.rb` rather than RESTful resources.
- **PDF generation** via `wicked_pdf` + `wkhtmltopdf-binary` (the binary is now bundled as a
  gem so no system-level wkhtmltopdf is needed).
- **File uploads** via CarrierWave + MiniMagick (`app/uploaders/`).
- Search/filtering uses **ransack**; pagination uses **will_paginate**; nested form rows use
  **cocoon**.

## Conventions

### The Rails Way (DHH majestic monolith)

Lean into vanilla Rails; this repo is deliberately *not* layered like a modern service-
oriented backend. In particular, do **not** introduce service objects, `dry-monads`
`Success`/`Failure`, Pundit, serializer/`presenter`/`contract`/`finder` layers, or RSpec.
If a change seems to need one of those, raise it before building.

- **Fat models, skinny controllers.** Logic lives in ActiveRecord models (validations,
  associations, callbacks, scopes) and in `app/*/concerns`; controllers orchestrate.
- **Lean on the framework** — scopes, `has_many :through`, nested attributes, callbacks —
  the way `Okr`/`Task`/`User` already do. POROs only when logic is genuinely model-less.
- Convention over configuration, DRY, least surprise; keep new report actions consistent
  with the existing non-RESTful `ReportsController` rather than forcing resources.
- For non-trivial Rails work, delegate to the project-local **`rails-engineer`** agent
  (`.claude/agents/rails-engineer.md`) — it overrides the global one with these conventions.

### General

- The app runs Rails 8.0 / Ruby 3.3 — use current idioms (`before_action`, strong params,
  Zeitwerk autoloading) rather than the Rails 4.1-era patterns from its early history. Don't
  bump gem/Rails/Ruby versions further as a side effect of a feature change, though — that's
  its own deliberate, isolated piece of work.
- Respect soft-delete (`is_deleted`) and the role/visibility scoping instead of raw
  `where`/`destroy` — especially for anything an `employee` can reach.
- When adding an authorization-gated action, add the rule to `app/models/ability.rb`.
- `config/app_config.yml` and the `.env` files are gitignored; only their `.example`
  counterparts are tracked.

## Planning & specs (OpenSpec)

Non-trivial changes are shaped as **OpenSpec** proposals before implementation, via the
`opsx` slash commands / skills (installed under `.claude/`):

- `/opsx:explore` — investigate the area before committing to a proposal.
- `/opsx:propose` (`openspec-propose`) — create a change under `openspec/changes/<id>/`
  (proposal + tasks + spec deltas).
- `/opsx:apply` (`openspec-apply-change`) — implement an approved proposal.
- `/opsx:archive` (`openspec-archive-change`) — on completion, move the change to
  `openspec/changes/archive/` and fold its deltas into `openspec/specs/`.

`openspec/specs/` is the source-of-truth capability spec; `openspec/changes/` holds
in-flight proposals (`openspec list` shows active ones). Shared project context for
generated artifacts lives in `openspec/config.yaml`. Track the resulting work items with
`bd` (below) — OpenSpec shapes *what*, beads tracks *doing it*.


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:970c3bf2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   bd dolt push
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
