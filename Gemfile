source 'https://rubygems.org'

# Dual-boot scaffold (FastRuby methodology): lets this app boot against either
# this Gemfile (current: Rails 6.1, promoted from Gemfile.next by Task 7) or
# Gemfile.next (next hop target, Rails 7.0 per Task 8) via BUNDLE_GEMFILE, and
# exposes NextRails.next?/current? for any code/config that needs to branch
# during a version hop. Keep this outside any group so the helpers are
# available everywhere. See https://github.com/fastruby/next_rails
gem 'next_rails'

# Rails 6.0 -> 6.1 hop (Task 7, roadmap §7 row 7), kept on Ruby 2.7.5 (no Ruby
# bump this hop — the roadmap's next Ruby bump, 2.7 -> 3.1, arrives alongside
# Task 8's 6.1 -> 7.0 asset-pipeline hop). Landed, and it was indeed
# "usually smooth" as the roadmap flagged — no Zeitwerk-scale surprises:
#
#   - **`update_attributes`/`update_attributes!` removed in 6.1**: fixed every
#     call site app-wide (more than the two the prior hop's agent had
#     spotted) — `app/models/team_member.rb`, `app/models/team.rb`,
#     `app/models/project.rb`, `app/models/task.rb`, `app/models/comment.rb`,
#     `app/models/project_manager.rb`, `app/controllers/oauth_applications_controller.rb`
#     (x2), `app/controllers/okrs_controller.rb`, `app/controllers/tasks_controller.rb`,
#     plus the equivalent test call sites (`test/models/oauth_application_test.rb`,
#     `test/models/task_test.rb`, `test/models/team_test.rb`) — all renamed to
#     `update`, no behavior change (both are single-`update` calls, no `!`).
#   - **`Uniqueness` validator case-sensitivity change turned out to be a
#     no-op for this app**: `User#email`/`#employee_code` and `Project#code`
#     all live on `utf8_general_ci` (case-insensitive) MySQL columns — so
#     even under 6.0's case-sensitive-by-default Ruby-level check, the actual
#     DB comparison was already case-insensitive (MySQL's collation wins).
#     Rails 6.1's new default (defer to the column's collation instead of
#     assuming case-sensitive) makes the validator's behavior match what the
#     DB was already enforcing — no query/validation results change, and the
#     6.0-era `DEPRECATION WARNING: Uniqueness validator will no longer
#     enforce case sensitive comparison in Rails 6.1...` disappears entirely
#     once actually running on 6.1 (confirmed via `rake test` output on both
#     sides). No `case_sensitive:` option was added to any model — it would
#     be redundant with the column collation and isn't this app's own style.
#   - `bin/rails zeitwerk:check` is green under Gemfile.next; no eager-load
#     path/Railtie regressions from the gem bumps below, EXCEPT:
#   - **New requirement, not previously needed**: eager loading (which
#     `zeitwerk:check` and `config.eager_load = true` in production both
#     trigger) now pulls in the bundled `active_storage` engine's own
#     `app/models`, which requires `config/storage.yml` to exist even though
#     this app has never used Active Storage (uploads are CarrierWave/
#     MiniMagick, see `app/uploaders/`). Added a minimal, unused stock
#     `config/storage.yml` (test/local Disk services, generated the same way
#     as other stock templates this hop, not hand-invented) purely to
#     satisfy that requirement.
#   - **Per-database connection switching / multi-DB config format**: not
#     applicable, confirmed — single flat `config/database.yml` per
#     environment, no replica/multi-DB setup, parses unchanged.
#   - **Strict `where` on associations** (`ActiveRecord::StrictLoadingViolationError`):
#     opt-in only, not touched — this app's code never turns on `strict_loading`.
#   - `ActiveSupport::Deprecation` per-gem configuration and the
#     `disable_to_s_conversion`/`isolation_level` knobs: new but off-by-default,
#     not touched.
#   - `config.load_defaults 6.1` (config/application.rb, guarded by
#     `NextRails.next?` until promotion) + the stock
#     `config/initializers/new_framework_defaults_6_1.rb` template (fetched
#     from the `railties-6.1.7.10` gem installed for this hop) — every
#     individually-togglable 6.1 behavior change is walked and left pinned to
#     its pre-6.1 default (none are exercised by this app's code: no
#     ActiveStorage, no ActiveJob callbacks/retries, no `form_with` remote
#     forms reliance, no multi-DB, no ActionMailbox).
#   - Gem cluster: devise 4.7.3 (still satisfies the existing `~> 4.7.1` pin —
#     its `railties` cap covers 6.1 after all, the prior hop's "may need
#     4.8.x" note didn't materialize), cancancan/doorkeeper/ransack/nokogiri-
#     family all resolved unchanged. Two gems *did* need bumping to make
#     `bundle lock` succeed under Rails 6.1 (see their own comments below):
#     `mysql2` (0.4.10 -> 0.5.7, activerecord's mysql2 adapter now requires
#     `~> 0.5`) and `select2-rails` (3.5.4 -> 3.5.11, to drop a `thor ~> 0.14`
#     *runtime* dependency that conflicted with railties' `thor ~> 1.0`).
#   - `concurrent-ruby` pin (`< 1.3.5`) still needed — Rails 6.1's
#     `activesupport` still doesn't require 'logger' itself (lands in 7.1).
#
# Full characterization suite green under Rails 6.1.7.10 / Ruby 2.7.5: 340
# runs, 766 assertions, 0 failures, 0 errors, 16 skips, 70.75% coverage
# (unchanged from the 6.0 baseline — this hop changed no test behavior,
# only renamed removed-API call sites).
gem 'rails', '~> 6.1.7'

# Rails 4.2 extracted the class-level `respond_to`/`respond_with` API (used by
# Api::V1::CredentialsController) out of Action Controller into this gem.
# responders 2.x caps `railties < 5`; bumped to 3.x in the 6.0 hop.
gem 'responders', '~> 3.0'

# nokogiri 1.16+ raises the Ruby floor to >= 3.0 (above this hop's Ruby 2.7),
# so stay pinned to 1.15.7 (the last release supporting Ruby 2.7) until the
# Ruby 2.7 -> 3.1 bump (Task 8) lands. loofah/rails-html-sanitizer likewise
# stay at the versions landed in Task 6 unless this hop's `bundle lock` finds
# a reason to move them.
gem 'nokogiri', '~> 1.15.7'
gem 'loofah', '~> 2.25.1'
gem 'rails-html-sanitizer', '~> 1.7.0'

# devise 4.6.x's omniauth integration is more lenient than 3.5's hard
# `OmniAuth::VERSION =~ /^1\./` assertion, but this app's omniauth-fluxapp /
# omniauth-oauth2 / omniauth-google-oauth2 strategies are still written
# against OmniAuth 1.x request-phase semantics (OmniAuth 2.0 changed the
# request phase from GET to POST and needs omniauth-rails_csrf_protection).
# Keep pinning to the 1.x line until that migration is deliberately scoped.
gem 'omniauth', '~> 1.9'

# Use mysql as the database for Active Record
# Rails 6.1's activerecord-mysql2-adapter requires `mysql2 ~> 0.5`; the 0.4.10
# pin from earlier hops no longer resolves. Bump to the 0.5.x line (still the
# same C-extension mysql2 gem, no app-facing API change for this app's
# usage) — verify the native extension still builds against this container's
# libmysqlclient during this hop.
gem 'mysql2', '~> 0.5.7'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'execjs', '~> 2.7.0'
gem 'uglifier', '< 4'
gem 'multipart-post', '< 2.0'

gem 'faraday', '< 0.10'

# Transitive dep of sass-listen (via sass-rails' watcher chain). Pinned in
# the Rails 6.0 hop (Task 6) to keep bundler's resolver off a
# `x86_64-linux-musl` platform build of 1.17.x whose `required_ruby_version`
# is `>= 3.0` — still needed as long as this hop stays on Ruby 2.7.
gem 'ffi', '~> 1.15.5'

# concurrent-ruby 1.3.5+ stopped requiring Ruby's stdlib `logger` before
# referencing the bare `Logger` constant, which breaks
# `active_support/logger_thread_safe_level.rb` on any Rails release that
# doesn't require 'logger' itself (that fix lands in Rails 7.1). Still
# needed on Rails 6.1 — re-verify during this hop rather than dropping it.
gem 'concurrent-ruby', '< 1.3.5'


# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.2.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
# jquery-rails 3.1.4 caps `railties < 5.0`; bump to a 4.x release (still just
# jQuery + UJS asset packaging, no app-code impact) to support Rails 5.0.
gem 'jquery-rails', '~> 4.3.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# turbolinks 2.2.1's XHRHeaders concern monkeypatches
# `_compute_redirect_to_location(options)`, but Rails 4.2 changed that
# private API to `_compute_redirect_to_location(request, options)`, which
# blows up every `redirect_to` call with `ArgumentError: wrong number of
# arguments`. Bump to the last classic (non-Turbolinks-5-rewrite) release,
# which targets Rails 4.2's signature; the JS/behavior stays classic
# Turbolinks 2.x.
gem 'turbolinks', '~> 2.5.4'
gem 'jquery-turbolinks', '2.0.2'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# jbuilder 1.5.3 (resolved from `~> 1.2` unpinned) references the
# `Mime::JSON` constant directly, which Rails 5 removed in favor of
# `Mime[:json]` (the whole `Mime::TYPE` constant-per-type scheme was
# replaced with `Mime::Type.lookup_by_extension`) — boot fails with
# `NameError: uninitialized constant Mime::JSON` under Rails 5.2. Bump to the
# last release still supporting Ruby 2.4 (2.14+ raises the Ruby floor to
# >= 3.0).
gem 'jbuilder', '~> 2.11.5'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
	gem 'sdoc', '0.4.0',require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]


# devise 4.7.3 (the latest 4.7.x patch, resolved from this unchanged `~> 4.7.1`
# pin) still boots fine under Rails 6.1 — its `railties` cap already covers
# 6.1, so the Task 6 comment's speculation about needing 4.8.x didn't
# materialize; confirmed via `bundle lock` during this hop (Task 7).
gem 'devise', '~> 4.7.1'

#gem "less-rails" #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS
gem "foundation-rails",'5.2.1.0'
gem 'hirb'
gem 'thin'
gem 'carrierwave', '1.0'
gem "mini_magick"
# select2-rails 3.5.4 declares `thor ~> 0.14` as a *runtime* dependency, which
# conflicts with Rails 6.1's railties requiring `thor ~> 1.0`. 3.5.11 (still
# the same 3.5.x select2 v3 JS/CSS assets, no app-facing behavior change)
# demoted thor to a development-only dependency, which unblocks `bundle
# lock` under Rails 6.1 without needing select2 v4's asset/JS API changes.
gem "select2-rails", '3.5.11'
#gem "cancan"
gem 'cancancan', '~> 1.7'
# Unpinned, omniauth-google-oauth2 resolves to a 1.2.x release that both
# needs Ruby >= 2.5 (above this hop's Ruby 2.4 ceiling) and depends on
# `omniauth ~> 2.0` (incompatible with the `omniauth ~> 1.9` pin above,
# itself needed for this app's still-1.x-shaped omniauth strategies). Pin to
# 0.8.2, the last release whose own `omniauth` dependency is `~> 1.1`.
gem 'omniauth-google-oauth2', '0.8.2'
# ransack 2.3.1+ needs `activerecord >= 5.2.1` and folded the separate
# `polyamorous` gem into ransack itself as of 2.4.0. Pinned to the exact
# patch 2.4.1 — `~> 2.4.0` would also match 2.4.2, which raises the Ruby
# floor to >= 2.6 (satisfied since Task 6). Confirmed this hop (Task 7) that
# 2.4.1 still resolves unchanged under Rails 6.1's `activerecord`; no reason
# found to revisit the pin.
gem 'ransack', '2.4.1'
gem "will_paginate"
gem "cocoon"
# wicked_pdf 0.9.10's PdfHelper module uses `alias_method_chain`, which Rails
# 5.1 removed outright. Bumped to the first release that drops it; the
# roadmap's full wicked_pdf/wkhtmltopdf-binary replacement discussion (Task
# 11) is still deferred.
gem 'wicked_pdf', '~> 2.1.0'
gem 'wkhtmltopdf-binary' # bundle the binary so there's no system-level wkhtmltopdf dependency
gem 'friendly_id', '~> 5.0.0'
# doorkeeper 4.4.3's `railties >= 4.2` dependency has no upper cap — confirmed
# via `bundle lock` this hop (Task 7), still resolves unchanged under Rails
# 6.1. The full doorkeeper -> 5.x OAuth-server migration (token model/table
# changes, `previous_refresh_token`, PKCE, etc.) stays scoped to roadmap Task 10.
gem 'doorkeeper', '~> 4.4.3'

gem "omniauth-oauth2"#, '1.0.2'
#gem 'omniauth-fluxapp' , :path => '/home/tp/Desktop/flux'
gem 'omniauth-fluxapp' , :git  => 'https://github.com/stpnlr/omniauth-fluxapp.git'
gem 'tzinfo-data'

group :test do
  # simplecov 1.0.0 raises the Ruby floor to >= 3.2 (a later hop's problem
  # once Ruby moves past 2.7). Stay pinned to the 0.22.x line landed in
  # Task 6 until this hop's own Ruby bump (if any) makes 1.0.0 reachable.
  gem 'simplecov', '~> 0.22.0', require: false

  # Rails 5.0 extracted `assigns`/`assert_template` out of Action Controller;
  # several controller tests use `assigns`, so pull them back in explicitly.
  gem 'rails-controller-testing'
end
