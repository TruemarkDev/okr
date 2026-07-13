source 'https://rubygems.org'

# This Gemfile targets Rails 8.0 / Ruby 3.3+ -- the roadmap's own
# target_stack, reached at Task 9 (the final version-hop task). The
# `next_rails`-powered dual-boot scaffold (Gemfile.next/Gemfile.next.lock,
# `NextRails.next?`/`.current?`, and the second CI leg) was RETIRED at Task
# 12 (dual-CI verify + handoff): with the ladder fully climbed there is no
# further Rails/Ruby hop queued, so a second Gemfile dual-booting against
# itself had no remaining purpose -- and in practice it had already silently
# drifted out of sync with this Gemfile during Task 11 (nobody remembered to
# mirror a same-hop dependency bump into the unused second file), which is
# exactly the failure mode a no-op scaffold invites. If/when a real next hop
# starts (e.g. Rails 8.1+), resurrect the pattern the same way Task 2 did
# originally: `cp Gemfile Gemfile.next`, `bundle lock` it, add `next_rails`
# back, and restore the second CI matrix leg -- don't try to un-rot this one.
#
# Rails 7.0 -> 7.1 -> 7.2 -> 8.0 hop (Task 9, roadmap §7 row 9), ALONGSIDE a
# Ruby 3.1 -> 3.3 bump. This is the LAST Rails/Ruby version hop -- the app
# now runs the roadmap's target stack (Rails 8.0 / Ruby 3.3+).
#
#   - **Ruby 3.1 -> 3.3 bump**: landed as a from-source Ruby 3.3.11 build in
#     `Dockerfile.development` (same from-source approach as Task 8's 3.1.6,
#     since brightbox's PPA still doesn't carry any Ruby 3.x package).
#   - **`config.load_defaults` ramp**: walked 7.1, 7.2, and 8.0 one at a time
#     via their real stock `new_framework_defaults_*.rb` templates. Nothing
#     in this app's code needed to opt into any of the individually-gated
#     behavior changes; all pinned to pre-8.0 defaults except what Task 8
#     already turned on (`raise_on_open_redirects`).
#   - **Asset pipeline**: KEPT Sprockets. Rails 8's new-app default is
#     Propshaft, but Sprockets 4.x remains fully supported and this is a
#     maintenance upgrade, not a rebuild (CLAUDE.md's "match the surrounding
#     style" doctrine, same call as Task 8).
#   - **Solid Queue / Solid Cache / Solid Cable**: NOT adopted. This app has
#     no ActiveJob queue backend or Action Cable usage to migrate -- they're
#     additive-only new-app defaults, not forced on existing apps.
#   - **Turbolinks**: KEPT classic 2.5.4, same arity-flexible monkeypatch
#     from Task 3 still works unmodified.
#   - **Gem cluster**: devise 4.9.4 -> 4.9.4 (unchanged, already the ceiling
#     needed), cancancan 3.6 -> 3.6 (unchanged), doorkeeper 5.1.2 -> 5.1.2
#     (unchanged; the doorkeeper *initializer* itself needed a fix -- its
#     `require 'redirect_uri_validator'` bare-$LOAD_PATH lookup from Task 8
#     stopped resolving under Rails 8.0, re-fixed with an absolute
#     `Doorkeeper::Engine.root`-based require -- see the initializer's own
#     comment), ransack 4.3.0 -> 4.4.1 (its `~> 4.4` `activesupport` floor
#     of `>= 7.1` finally clears once Rails is 7.1+), nokogiri/loofah/
#     rails-html-sanitizer bumped to their latest current releases now that
#     their Ruby-floor-only pins no longer apply (Ruby is 3.3), `ffi` bumped
#     to latest for the same reason, `concurrent-ruby < 1.3.5` pin DROPPED
#     (activesupport 8.0 requires 'logger' itself, the actual upstream fix
#     that pin was working around).
#   - **simplecov**: tried the 1.0.0 line (now unblocked since Ruby clears
#     its >= 3.2 floor), but REVERTED to 0.22.0 -- 1.0.0's stock "rails"
#     profile changed its config/db path-filtering AND file-discovery
#     semantics, which inflates the reported denominator (1573 -> 1908
#     tracked lines) with the exact same 1114 covered lines, making the
#     percentage read as a regression (70.82% -> 58.38%) when nothing about
#     actual coverage changed. Kept 0.22.0 to preserve a hop-to-hop
#     comparable coverage-gate percentage rather than trade a
#     well-understood baseline for a confusing one-line "modernize while
#     we're here" change.
gem 'rails', '~> 8.0.0'

# Rails 4.2 extracted the class-level `respond_to`/`respond_with` API (used by
# Api::V1::CredentialsController) out of Action Controller into this gem.
# responders 2.x caps `railties < 5`; bumped to 3.x in the 6.0 hop.
gem 'responders', '~> 3.0'

# Ruby-floor-only pins (Task 6/7/8): 1.15.7/2.25.1/1.7.0 were capped only
# because Ruby was still 2.7 when set. Now that Ruby is 3.3 (Task 9), bumped
# all three to their latest current releases (nokogiri 1.15.7 -> 1.19.4;
# loofah/rails-html-sanitizer already at latest) via `bundle lock --update`.
# No forcing function beyond "the Ruby-floor reason for the old pin is gone" --
# this app's own code never calls Nokogiri/Loofah/rails-html-sanitizer APIs
# directly (transitive HTML-sanitization deps of actionview/rails-dom-testing),
# so the full characterization suite staying green is the only verification
# surface, and it does.
gem 'nokogiri', '~> 1.19.4'
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

# Use Terser as compressor for JavaScript assets (Uglifier's ES5-only parser
# chokes on the ES6 class syntax that Rails 8's bundled ActiveStorage/
# ActionText JS ships with, once `rails/all` puts them on the precompile
# list -- see production.rb's js_compressor).
gem 'execjs', '~> 2.7.0'
gem 'terser', '~> 1.2'
gem 'multipart-post', '< 2.0'

# Was pinned `< 0.10` since the app's original (2016) Gemfile with no
# comment explaining why, and nothing in this app's own code calls Faraday
# directly — it's purely a transitive dep of oauth2/omniauth-google-oauth2
# (which only requires `>= 0.8, < 3.0`). That ancient 0.9.2 resolution
# doesn't survive Ruby 3.1 (roadmap Task 8's Ruby bump): its
# `Faraday::Options` class builder uses a bare `Struct.new { |...| ... }`/
# `Proc.new` pattern Ruby 3.0+ turned into a hard `ArgumentError: tried to
# create Proc object without a block` (no longer just a warning). Bump to
# the last Faraday 1.x release (avoids the 2.x adapter-registration
# breaking change, which would be more than this hop needs) — still well
# within oauth2's `< 3.0` cap.
gem 'faraday', '~> 1.10'

# Transitive dep of sass-listen (via sass-rails' watcher chain). Bumped to
# the latest release (1.17.4) this hop (Task 9) -- the Ruby-floor-only
# platform-build concern that motivated the earlier 1.15.5 pin no longer
# applies now that Ruby is 3.3; `bundle lock --update ffi` resolves cleanly
# and the full suite stays green.
gem 'ffi', '~> 1.17.4'

# concurrent-ruby 1.3.5+ stopped requiring Ruby's stdlib `logger` before
# referencing the bare `Logger` constant, which broke `active_support/
# logger_thread_safe_level.rb` on any Rails release that didn't require
# 'logger' itself. DROPPED this hop (Task 9): activesupport 8.0.5 requires
# 'logger' itself (the actual upstream fix), so the pin is no longer needed --
# confirmed via `bundle lock` and the full suite passing unpinned.


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
# Turbolinks 2.x. Confirmed (Tasks 8/9) this same monkeypatch's splatted
# `*args` signature still works unmodified through Rails 8.0.
gem 'turbolinks', '~> 2.5.4'
gem 'jquery-turbolinks', '2.0.2'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# jbuilder 1.5.3 (resolved from `~> 1.2` unpinned) references the
# `Mime::JSON` constant directly, which Rails 5 removed in favor of
# `Mime[:json]` (the whole `Mime::TYPE` constant-per-type scheme was
# replaced with `Mime::Type.lookup_by_extension`) — boot fails with
# `NameError: uninitialized constant Mime::JSON` under Rails 5.2. Bumped to
# 2.11.5 for that hop (Task 5), then to 2.15.1 in Task 9 (Rails 8.0 removed
# the ancient `active_support/basic_object`/`proxy_object` compat shim
# 2.11.5's LoadError-rescue path depended on). This app's ~20
# `*.json.jbuilder` views use the plain `json.<attr>`/`json.array!` DSL,
# unchanged across the 2.11 -> 2.15 jump.
gem 'jbuilder', '~> 2.15.1'

# The `:doc` group (`sdoc 0.4.0`, for `rake doc:rails`) was dropped in the
# Ruby 2.7 -> 3.1 bump (roadmap Task 8): `sdoc 0.4.0` pins `json ~> 1.8`
# (resolved 1.8.6, a native-extension gem from 2014), which is incompatible
# with Ruby 3.1's stdlib `json` (2.6.1) API — `JSON.parse`'s C extension
# takes a different arity, so anything that touches JSON at runtime
# (Doorkeeper's initializer, SimpleCov's result writer) blew up with
# `ArgumentError: wrong number of arguments`. Nothing in this app's test
# suite or runtime code calls `rake doc:rails`; removing the group lets
# Bundler resolve to Ruby's own bundled `json` instead of pinning an
# incompatible ancient one. Re-add `sdoc` (a current release) as a
# stand-alone `group :development` gem later if API-doc generation is
# actually needed.

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]


# devise 4.7.3 finally hit its wall at Rails 7.0 (Task 6/7's speculation
# about needing 4.8.x materialized here): `Devise.ref` calls
# `ActiveSupport::Dependencies.reference(arg)` unconditionally, but Rails
# 7.0 (Zeitwerk-only, classic autoloader support fully removed) drops that
# method from `ActiveSupport::Dependencies` entirely -- `NoMethodError`
# the moment `devise.rb` loads (`Devise.mailer = ...`). Fixed at 4.8.0,
# which guards the call with
# `if ActiveSupport::Dependencies.respond_to?(:reference)`. Bumped to the
# last 4.x release (5.0.x changes enough -- new
# `Devise::Test::IntegrationHelpers` defaults, dropped Rails < 6.1 support
# -- that a same-major bump is the lower-risk choice here). Re-verified
# against Rails 7.1/7.2/8.0 (Task 9) -- unchanged, still resolves and passes.
gem 'devise', '~> 4.9.4'

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
# cancancan 1.17.0's `Ability#unauthorized_message` calls
# `I18n.translate(nil, variables.merge(...))` -- a Hash passed
# *positionally*, not double-splatted -- into i18n 1.14's
# `translate(key = nil, **options)`. Same Ruby 3.0+ kwargs-separation break
# as the doorkeeper/faraday fixes above (roadmap Task 8's Ruby 2.7 -> 3.1
# bump): every `CanCan::AccessDenied` path (any employee hitting a
# `load_and_authorize_resource`-gated action they can't reach) blew up with
# `ArgumentError: wrong number of arguments (given 2, expected 0..1)`
# instead of rendering the expected redirect+alert. Fixed upstream at
# 3.1.0; bumped to latest 3.x. This app's
# `can`/`cannot`/`alias_action`/block-condition DSL in
# `app/models/ability.rb` is unchanged across the 1.x -> 3.x jump. Re-verified
# against Rails 7.1/7.2/8.0 (Task 9) -- unchanged, still resolves and passes.
gem 'cancancan', '~> 3.6'
# Unpinned, omniauth-google-oauth2 resolves to a 1.2.x release that both
# needs Ruby >= 2.5 (above this hop's Ruby 2.4 ceiling) and depends on
# `omniauth ~> 2.0` (incompatible with the `omniauth ~> 1.9` pin above,
# itself needed for this app's still-1.x-shaped omniauth strategies). Pin to
# 0.8.2, the last release whose own `omniauth` dependency is `~> 1.1`.
gem 'omniauth-google-oauth2', '0.8.2'
# Was capped `~> 4.3.0` in Task 8 specifically because `~> 4.4` raises its
# own `activesupport` floor to `>= 7.1`/`>= 7.2`. This hop (Task 9, landing
# Rails 8.0) clears that floor, so lifted to the latest 4.x release (4.4.1).
# `home_controller.rb`'s `.ransack(...)` call and `Task#ransackable_attributes`/
# `#ransackable_associations` allowlists (added in Task 8) re-verified against
# 4.4.1 -- no allowlist/API changes between 4.3 and 4.4, full suite green.
gem 'ransack', '~> 4.4.1'
gem "will_paginate"
gem "cocoon"
# wicked_pdf 0.9.10's PdfHelper module uses `alias_method_chain`, which Rails
# 5.1 removed outright. Bumped to the first release that drops it.
#
# Roadmap Task 11 investigated replacing wicked_pdf/wkhtmltopdf-binary
# outright (the underlying wkhtmltopdf binary is unmaintained upstream).
# Under Rails 8.0 the ReportsController's `format.pdf` actions had bit-rotted
# in two small, unrelated ways -- NOT anything wrong with wkhtmltopdf itself:
#   1. `config/initializers/wicked_pdf.rb` hardcoded a long-gone
#      `#{Rails.root}/lib/wkhtmltopdf` exe_path from before this app switched
#      to the `wkhtmltopdf-binary` gem (which puts `wkhtmltopdf` on PATH via
#      its own bin stub) -- fixed by dropping the stale override.
#   2. Every `format.pdf { render ... :layout => 'pdf.html' }` call used an
#      old convention of suffixing the layout name with ".html" to force
#      html-format layout lookup during a :pdf-format request; Rails 8's
#      template lookup no longer honors that, raising ActionView::
#      MissingTemplate. Fixed by using the format-less `:layout => 'pdf'`
#      (Rails' lookup context already searches the request's declared
#      formats plus html for layouts).
# With both fixed, wkhtmltopdf 0.12.6 (bundled by wkhtmltopdf-binary) renders
# real, valid PDFs again (verified via a real render + `%PDF-` magic-number
# check in test/controllers/reports_controller_test.rb) -- there is no
# current forcing function (crash/missing binary/broken output) to justify
# swapping rendering engines (e.g. to grover/ferrum_pdf), so the gem stays
# put. Revisit if wkhtmltopdf itself breaks on some future platform.
gem 'wicked_pdf', '~> 2.1.0'
gem 'wkhtmltopdf-binary' # bundle the binary so there's no system-level wkhtmltopdf dependency
# Was pinned `~> 5.0.0`, which (pessimistic operator) only floats 5.0.x
# patches -- resolved to the years-old 5.0.5 even though the whole 5.x line
# (through 5.7.0, still `activerecord >= 4.0.0`, no Rails-8-incompatible API
# changes) is current and there's no 6.x major to avoid. Bumped the pin to
# the latest 5.x (roadmap Task 11); `Task`/`User`'s plain `friendly_id
# :tracker_id`/`:employee_code` usage needed no code changes.
gem 'friendly_id', '~> 5.7.0'
# doorkeeper 4.4.3 (last 4.x release) did NOT survive the Ruby 2.7 -> 3.1
# bump (roadmap Task 8) -- fixed by bumping to 5.1.2, the earliest 5.x patch
# whose `belongs_to` calls use keyword-literal syntax instead of a
# positionally-passed Hash (a Ruby 3.0+ kwargs-separation break). Needed the
# `confidential` column migration (5.x hard-validates it) --
# db/migrate/20260712000000_add_confidential_to_oauth_applications.rb.
# Everything else 5.x adds (token/secret hashing, `previous_refresh_token`,
# PKCE, scopes-by-grant-type, etc.) stayed off/default through Task 8/9,
# deferring the rest of doorkeeper modernization to roadmap Task 10.
# Re-verified against Rails 7.1/7.2/8.0 (Task 9) -- unchanged as a version,
# but its initializer needed the `require Doorkeeper::Engine.root.join(...)`
# fix (see config/initializers/doorkeeper.rb) once Rails 8.0 changed
# `add_autoload_paths_to_load_path`'s effective behavior.
#
# Task 10 revisited that deferred list: token/secret hashing (`hash_token_
# secrets`/`hash_application_secrets`, with a plaintext fallback for existing
# rows) is now enabled -- see config/initializers/doorkeeper.rb for the full
# rationale plus the explicit non-adoption of PKCE/previous_refresh_token/
# scopes-by-grant-type (no concrete need in fluxday's single confidential-
# client usage) and the `confidential` column default audit (still correct
# as `true` for every application -- see the migration file's comment).
gem 'doorkeeper', '~> 5.1.2'

gem "omniauth-oauth2"#, '1.0.2'
#gem 'omniauth-fluxapp' , :path => '/home/tp/Desktop/flux'
# omniauth-fluxapp is only published at this git URL -- there is no
# rubygems.org release (confirmed: `gem list -r ^omniauth-fluxapp$` /
# rubygems.org's API return nothing) and the upstream repo has no tags
# either, so there's no `:tag` to pin to. It was floating on unpinned
# `master`, which happened to still be the exact commit this app's
# Gemfile.lock had already resolved to (`a00079af6...`, last pushed
# 2021-10-03 -- the repo looks abandoned/stale, an external risk this repo
# can't fix). Roadmap Task 11: pin the Gemfile itself to that same `:ref`
# so a future `bundle update` can't silently drift onto whatever `master`
# becomes if the repo ever gets new commits.
gem 'omniauth-fluxapp' , :git => 'https://github.com/stpnlr/omniauth-fluxapp.git', :ref => 'a00079af6e6ebb9dae5ca4c50ff4dfb01a20f159'
gem 'tzinfo-data'

# csv moves from a default gem to a bundled gem in Ruby 3.4; declare it
# explicitly now to silence the "will no longer be part of the default
# gems" warning railties emits on every boot under Ruby 3.3.11.
gem 'csv'

group :test do
  # simplecov 1.0.0 raises the Ruby floor to >= 3.2 -- this hop's Ruby 3.3
  # bump (roadmap Task 9) clears that floor for the first time, so it's no
  # longer *blocked*. Tried it anyway: 1.0.0's stock "rails" profile changed
  # its config/db filtering from `add_filter %r{^/config/}` to
  # `skip %r{\Aconfig/}` (root-relative vs. absolute-path regexes) AND its
  # `track_files` file-discovery semantics, which together shift the
  # reported denominator from 1573 tracked lines to 1908 -- same 1114 lines
  # actually covered, but the resulting percentage (58.38% vs. 70.82%) reads
  # like a coverage regression when it's really just SimpleCov's own
  # bookkeeping changing. Since 0.22.0 already runs fine on Ruby 3.3/Rails
  # 8.0 (verified) and isn't a forced bump, reverted to keep this roadmap's
  # coverage-gate percentage comparable hop-to-hop rather than trade a
  # working, well-understood baseline for a confusing one-line "modernize
  # while we're here" change.
  gem 'simplecov', '~> 0.22.0', require: false

  # Rails 5.0 extracted `assigns`/`assert_template` out of Action Controller;
  # several controller tests use `assigns`, so pull them back in explicitly.
  gem 'rails-controller-testing'
end
