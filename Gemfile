source 'https://rubygems.org'

# Dual-boot scaffold (FastRuby methodology): lets this app boot against either
# this Gemfile (current: Rails 6.0, promoted from Gemfile.next by Task 6) or
# Gemfile.next (next hop target, Rails 6.1 per Task 7) via BUNDLE_GEMFILE, and
# exposes NextRails.next?/current? for any code/config that needs to branch
# during a version hop. Keep this outside any group so the helpers are
# available everywhere. See https://github.com/fastruby/next_rails
gem 'next_rails'

# Rails 5.2 -> 6.0 hop (Task 6, roadmap §7 row 6; the highest-risk hop flagged
# by the roadmap, "autoloader rewrite risk"). Landed:
#
#   - **Zeitwerk autoloader**: `config.load_defaults 6.0` (config/application.rb)
#     turns it on. Audited `app/`, `lib/`, and `config/initializers/inflections.rb`
#     for file/constant-name mismatches, reopened classes, and non-standard
#     autoload-path usage — found none (this app's naming was already
#     1:1 conventional, and `lib/time_to_diff.rb`/`lib/omniauth/strategies/`
#     are required explicitly rather than relying on autoloading, so Zeitwerk
#     doesn't touch them). The one real find: `Api::V1::CredentialsController`
#     called the pre-3.0 Doorkeeper class method `doorkeeper_for :all`, which
#     doesn't exist on the 4.4.3 release this app runs — classic autoloading
#     never actually loaded that file (no test/request exercises `/api/v1/me`)
#     so the resulting `NoMethodError` was silently dead code until Zeitwerk's
#     eager-load-everything semantics (`zeitwerk:check`, and
#     `config.eager_load = true` in production) surfaced it. Fixed by
#     replacing it with the modern `before_action :doorkeeper_authorize!`.
#     `bin/rails zeitwerk:check` is green.
#   - `config.load_defaults 6.0` applies unconditionally now (see
#     config/application.rb); every individual new-default toggle it can
#     enable is walked, and deliberately left commented/pinned to old
#     behavior, in config/initializers/new_framework_defaults_6_0.rb.
#   - `Rails.application.config_for`: not used anywhere in this app (it uses
#     its own `AppConfig = YAML.load_file(...)` constant in
#     config/environments/*.rb instead), so the 6.0 return-type change
#     (`HashWithIndifferentAccess` -> `ActiveSupport::OrderedOptions`)
#     doesn't apply.
#   - Webpacker (6.0's new-app JS default) was not adopted — this app keeps
#     Sprockets/coffee-rails/jquery-rails; the asset-pipeline modernization
#     stays deferred to the 6.1->7.0 hop (roadmap Task 8).
#   - Ruby bumped 2.4.10 -> 2.7.5 (brightbox PPA `ruby2.7` package on Ubuntu
#     18.04/bionic) alongside this hop, per the roadmap's interleaved Ruby
#     ramp — see .ruby-version/.tool-versions/Dockerfile.development.
#   - Gem cluster bumped to unblock `railties` resolving to a 6.0.x release:
#     devise 4.6.0 -> 4.7.1 (its `< 6.0` railties cap was the actual blocker),
#     responders 2.0 -> 3.0 (2.x caps `railties < 5`), nokogiri/loofah/
#     rails-html-sanitizer bumped off their Ruby-2.4 ceiling now that Ruby is
#     2.7, simplecov 0.18.5 -> 0.22.0 (same reason). doorkeeper 4.4.3 needed
#     no further bump (`railties >= 4.2`, no upper cap).
#   - Two gems needed pinning purely to keep `bundle lock`/boot working on
#     this Ruby/Rails combination, unrelated to Rails 6.0 itself: `ffi` (a
#     transitive dep via sass-listen's file-watcher chain) pinned to
#     `~> 1.15.5` to keep bundler's resolver off a `x86_64-linux-musl`
#     platform build of 1.17.x whose `required_ruby_version` is `>= 3.0`; and
#     `concurrent-ruby` pinned `< 1.3.5` because 1.3.5+ stopped requiring
#     Ruby's stdlib `logger` before referencing the bare `Logger` constant,
#     which Rails 6.0's `active_support/logger_thread_safe_level.rb` needs
#     implicitly required — a well-known cross-gem break, not a Rails 6.0
#     fix; unpin once the app is on a Rails version that requires 'logger'
#     itself (Rails 7.1+).
#   - Bundler bumped 1.17.3 -> 2.4.22, the latest release that still supports
#     Ruby 2.7 (2.5.0+ raises Bundler's own floor to Ruby >= 3.0).
#
# Full characterization suite green under Rails 6.0.6.1 / Ruby 2.7.5: 340
# runs, 766 assertions, 0 failures, 0 errors, 16 skips, 70.75% coverage
# (unchanged from the 5.2 baseline).
gem 'rails', '~> 6.0.6'

# Rails 4.2 extracted the class-level `respond_to`/`respond_with` API (used by
# Api::V1::CredentialsController) out of Action Controller into this gem.
# responders 2.x caps `railties < 5`; bump to 3.x (still the same
# respond_to/respond_with API for Api::V1::CredentialsController) to support
# Rails 6.0's railties.
gem 'responders', '~> 3.0'

# Ruby 2.4 ceiling from the 5.2 hop is gone now that this hop bumps Ruby to
# 2.7.5 (nokogiri >= 1.11 needs Ruby >= 2.5). nokogiri 1.16+ raises the floor
# again to Ruby >= 3.0, so pin to 1.15.7 — the last release still supporting
# Ruby 2.7. loofah/rails-html-sanitizer can move to their current releases;
# loofah's own dependency (`nokogiri >= 1.12.0`) is satisfied by 1.15.7.
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
gem 'mysql2', '~> 0.4.10'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'execjs', '~> 2.7.0'
gem 'uglifier', '< 4'
gem 'multipart-post', '< 2.0'

gem 'faraday', '< 0.10'

# Transitive dep of sass-listen (via sass-rails' watcher chain). Not declared
# directly upstream of Rails 6.0, but `bundle update` on this hop's gem
# cluster otherwise resolves the resolver toward ffi 1.17.x's
# platform-specific (x86_64-linux-musl) build, whose `required_ruby_version`
# is `>= 3.0` — above this hop's Ruby 2.7.5. Pin to the last 1.15.x release,
# which has no such floor, to keep the resolver off that branch.
gem 'ffi', '~> 1.15.5'

# concurrent-ruby 1.3.5+ stopped requiring Ruby's stdlib `logger` before
# referencing the bare `Logger` constant. Rails 6.0's
# `active_support/logger_thread_safe_level.rb` relies on that implicit
# require and blows up on boot with `NameError: uninitialized constant
# ActiveSupport::LoggerThreadSafeLevel::Logger` once concurrent-ruby moves
# past 1.3.4. This is a well-known cross-gem break, not something Rails 6.0
# itself fixes — the actual fix landed in Rails via requiring 'logger'
# explicitly in later Rails versions. Pin below the break until the app is
# on a Rails version that requires 'logger' itself (Rails 7.1+).
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


# devise's `railties` dependency caps below Rails 5.1/5.2 through 4.2.x
# (`< 5.1, >= 4.1.0` on 4.2.1) — that cap, not a `responders` conflict, is
# what actually broke `bundle lock` on the previous hop's Gemfile.next.
# 4.6.x raises the cap to `< 6.0`, which is exactly what blocks *this* hop:
# Rails 6.0 needs `railties` to resolve to a 6.0.x release, above devise
# 4.6.x's own cap. Bump to 4.7.x, whose cap is `< 6.1` (still comfortably
# covers Rails 6.0; the next `< 6.2` cap arrives in 4.8.x, not needed yet).
gem 'devise', '~> 4.7.1'

#gem "less-rails" #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS
gem "foundation-rails",'5.2.1.0'
gem 'hirb'
gem 'thin'
gem 'carrierwave', '1.0'
gem "mini_magick"
gem "select2-rails", '3.5.4'
#gem "cancan"
gem 'cancancan', '~> 1.7'
# Unpinned, omniauth-google-oauth2 resolves to a 1.2.x release that both
# needs Ruby >= 2.5 (above this hop's Ruby 2.4 ceiling) and depends on
# `omniauth ~> 2.0` (incompatible with the `omniauth ~> 1.9` pin above,
# itself needed for this app's still-1.x-shaped omniauth strategies). Pin to
# 0.8.2, the last release whose own `omniauth` dependency is `~> 1.1`.
gem 'omniauth-google-oauth2', '0.8.2'
# ransack 2.3.1+ needs `activerecord >= 5.2.1` (satisfied now that Rails
# resolves to a 5.2.x patch) and folded the separate `polyamorous` gem into
# ransack itself as of 2.4.0. Pinned to the exact patch 2.4.1 — `~> 2.4.0`
# would also match 2.4.2, which raises the Ruby floor to >= 2.6 (above this
# hop's Ruby 2.4 ceiling).
gem 'ransack', '2.4.1'
gem "will_paginate"
gem "cocoon"
# wicked_pdf 0.9.10's PdfHelper module uses `alias_method_chain`, which Rails
# 5.1 removed outright (`NoMethodError: undefined method 'alias_method_chain'
# for ActionController::Base:Class` on boot). Bump to the first release that
# drops it; the roadmap's full wicked_pdf/wkhtmltopdf-binary replacement
# discussion (Task 11) is still deferred — this is only the minimum bump to
# keep booting under Rails 5.2.
gem 'wicked_pdf', '~> 2.1.0'
gem 'wkhtmltopdf-binary' # bundle the binary so there's no system-level wkhtmltopdf dependency
gem 'friendly_id', '~> 5.0.0'
# doorkeeper was bumped 1.1.0 -> 4.4.3 in the 5.2 hop purely to unblock boot
# (1.1.0's own controllers used `before_filter`, which Rails 5.1 removed
# outright, and doorkeeper didn't switch to `before_action` until 4.0.0).
# Confirmed 4.4.3 still boots under Rails 6.0 (its `railties >= 4.2`
# dependency has no upper cap) — the full doorkeeper -> 5.x OAuth-server
# migration (token model/table changes, `previous_refresh_token`, PKCE, etc.)
# stays scoped to roadmap Task 10.
gem 'doorkeeper', '~> 4.4.3'

gem "omniauth-oauth2"#, '1.0.2'
#gem 'omniauth-fluxapp' , :path => '/home/tp/Desktop/flux'
gem 'omniauth-fluxapp' , :git  => 'https://github.com/stpnlr/omniauth-fluxapp.git'
gem 'tzinfo-data'

group :test do
  # Ruby 2.4 floor from the 5.2 hop is gone now that this hop bumps Ruby to
  # 2.7.5; bump to the 0.2x line. simplecov 1.0.0 raises the floor to
  # Ruby >= 3.2 (a later hop's problem), so pin the last release that still
  # supports Ruby 2.7.
  gem 'simplecov', '~> 0.22.0', require: false

  # Rails 5.0 extracted `assigns`/`assert_template` out of Action Controller;
  # several controller tests use `assigns`, so pull them back in explicitly.
  gem 'rails-controller-testing'
end
