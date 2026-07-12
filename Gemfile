source 'https://rubygems.org'

# Dual-boot scaffold (FastRuby methodology): lets this app boot against either
# this Gemfile (current: Rails 5.2, promoted from Gemfile.next by Task 5) or
# Gemfile.next (next hop target, Rails 6.0 per Task 6) via BUNDLE_GEMFILE, and
# exposes NextRails.next?/current? for any code/config that needs to branch
# during a version hop. Keep this outside any group so the helpers are
# available everywhere. See https://github.com/fastruby/next_rails
gem 'next_rails'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
# Rails 5.0 -> 5.1 -> 5.2 hop (Task 5, roadmap §7 row 5; grouped as one hop by
# the roadmap — jumped straight to 5.2 in one lock resolution). Landed:
#
#   - Ruby bumped 2.3 -> 2.4 (2.4.10, latest patch) alongside this hop, per
#     the roadmap's interleaved Ruby ramp — see .ruby-version/.tool-versions/
#     Dockerfile.development. Ruby only goes as far as 2.4 here; the next
#     bump (2.6/2.7) belongs to Task 6 (Zeitwerk hop).
#   - `secrets.yml` -> `credentials.yml.enc`: NOT migrated. Rails 5.2 keeps
#     `secrets.yml` working and nothing in this hop needed the new mechanism.
#   - `before_action`/`after_action` — every `before_filter`/`after_filter`
#     in app/controllers renamed (removed in 5.1).
#   - `uniq` on relations (removed in 5.1) renamed to `distinct` at every
#     call site that was actually operating on an ActiveRecord::Relation
#     (has_many :through scopes and `.where(...).uniq` chains in
#     app/models/{user,task,team,project}.rb and
#     app/controllers/reports_controller.rb). Plain `Array#uniq` calls
#     (id-array dedup, `.collect(&:x).uniq`, etc.) were deliberately left
#     alone — `Array#uniq` still exists and is a different method.
#   - Controller tests using positional args (`get :show, {id: 1}`, removed
#     in 5.1) rewritten to keyword args (`get :show, params: {id: 1}`)
#     across every file in test/controllers, including the
#     `xhr :get, :action, ...` style (rewritten to
#     `get :action, params: {...}, xhr: true`).
#   - mysql2 bumped 0.3.21 -> 0.4.10 (no Ruby cap, and Rails 5.1+'s mysql2
#     adapter expects >= 0.4).
#   - devise bumped 4.2.0 -> 4.6.x: 4.2.1's `railties` dependency was
#     `< 5.1, >= 4.1.0`, which excludes Rails 5.1/5.2 outright (this, not a
#     `responders` version conflict per se, was the real cause of the
#     `bundle lock` failure the previous hop's agent hit) — 4.6.x drops the
#     upper railties cap to `< 6.0` and its `responders` dependency is
#     unconstrained (`>= 0`), so the existing `responders ~> 2.0` pin below
#     needs no change.
#   - omniauth-google-oauth2 pinned explicitly to 0.8.2 (the last release
#     whose own `omniauth` dependency is `~> 1.1`, i.e. compatible with the
#     `omniauth ~> 1.9` pin devise 3.5-era boot still needs below). Versions
#     >= 1.0.1 require `omniauth ~> 2.0`, and unpinned it was resolving to a
#     1.2.x release needing Ruby >= 2.5 anyway — Ruby 2.4 alone would not
#     have fixed that; the pin was the actual fix.
#   - ransack bumped 2.3.0 -> 2.4.1: 2.3.1+ needs `activerecord >= 5.2.1`
#     (satisfied once Rails resolves to a 5.2.x patch) and folded the
#     separate `polyamorous` gem into ransack itself as of 2.4.0. Pinned to
#     the exact patch 2.4.1 rather than `~> 2.4.0` because 2.4.2 raises the
#     Ruby floor to >= 2.6 (above this hop's Ruby 2.4 ceiling).
#   - simplecov bumped 0.17.1 -> 0.18.5 now that Ruby is 2.4 (see :test group
#     below) — 0.18.x is the last line still supporting Ruby 2.4;  0.19+
#     needs Ruby >= 2.5.
#   - nokogiri/loofah/rails-html-sanitizer: left unbumped. Nothing about
#     Rails 5.2 forces a bump, and nokogiri >= 1.11 still needs Ruby >= 2.5 —
#     Ruby only reaches 2.4 in this hop, so the ceiling comment below still
#     applies verbatim. Revisit at the Ruby 2.5+ step of Task 6.
#   - cancancan 1.x: verified still boots/functions under Rails 5.2 via the
#     characterization suite; no gem-level rails/railties constraint forced
#     a bump (same as the 5.0 hop).
#   - doorkeeper 1.1.0: same story — no upper rails/railties cap, verified
#     via the suite. The full 1.1 -> 5.x OAuth-server migration stays scoped
#     to roadmap Task 10.
#   - turbolinks/jquery-turbolinks: see the pins further down for the
#     versions that resolve together under Rails 5.2.
gem 'rails', '~> 5.2.0'

# Rails 4.2 extracted the class-level `respond_to`/`respond_with` API (used by
# Api::V1::CredentialsController) out of Action Controller into this gem.
gem 'responders', '~> 2.0'

# Ruby 2.4 ceiling (unchanged from the 5.0 hop): nokogiri >= 1.11 requires
# Ruby >= 2.5, so pin to the last release supporting Ruby 2.4.
# loofah/rails-html-sanitizer must be pinned in lockstep — loofah >= 2.20
# assumes the Nokogiri::HTML4/HTML5 split that only exists on nokogiri >=
# 1.11, so left unpinned they resolve to versions that raise `NameError:
# uninitialized constant Nokogiri::HTML4` on boot. Revisit once the Ruby
# ramp (§3) lands past 2.5 (Task 6).
gem 'nokogiri', '~> 1.10.10'
gem 'loofah', '~> 2.19.1'
gem 'rails-html-sanitizer', '~> 1.4.4'

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
# 4.6.x raises the cap to `< 6.0` and leaves `responders` unconstrained.
gem 'devise', '~> 4.6.0'

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
# doorkeeper 1.1.0's own controllers (app/controllers/doorkeeper/*) use
# `before_filter`, which Rails 5.1 removed — unlike this app's own
# controllers, that's gem-internal code we can't rename, so the previous
# hop's assumption that 1.1.0 "still boots under Rails 5.2" does not hold.
# doorkeeper didn't switch to `before_action` until 4.0.0. Bumped to 4.4.3
# (the last 4.x release; 5.x raises the Ruby floor to >= 2.5/2.7, above this
# hop's ceiling) purely to unblock boot — verified it boots and the existing
# oauth_applications/oauth_access_grants/oauth_access_tokens schema (from
# `db/migrate/20140418051345_create_doorkeeper_tables.rb`, unchanged) is
# still sufficient for this app's usage (OauthApplicationsController,
# Api::V1::CredentialsController) via the characterization suite. The full
# doorkeeper 1.1 -> 5.x OAuth-server migration (token model/table changes,
# `previous_refresh_token`, PKCE, etc.) stays scoped to roadmap Task 10 —
# this bump does not attempt that, only the minimum to keep booting.
gem 'doorkeeper', '~> 4.4.3'

gem "omniauth-oauth2"#, '1.0.2'
#gem 'omniauth-fluxapp' , :path => '/home/tp/Desktop/flux'
gem 'omniauth-fluxapp' , :git  => 'https://github.com/stpnlr/omniauth-fluxapp.git'
gem 'tzinfo-data'

group :test do
  # Ruby 2.4 floor: simplecov 0.18.x is the last line still supporting Ruby
  # 2.4 (0.19+ needs Ruby >= 2.5), so bump this far and no further until the
  # Ruby 2.5+ step of Task 6.
  gem 'simplecov', '~> 0.18.5', require: false

  # Rails 5.0 extracted `assigns`/`assert_template` out of Action Controller;
  # several controller tests use `assigns`, so pull them back in explicitly.
  gem 'rails-controller-testing'
end
