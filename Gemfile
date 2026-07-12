source 'https://rubygems.org'

# Dual-boot scaffold (FastRuby methodology): lets this app boot against either
# this Gemfile (current: Rails 5.0, promoted from Gemfile.next by roadmap
# Task 4) or Gemfile.next (next hop target, Rails 5.1/5.2 per Task 5) via
# BUNDLE_GEMFILE, and exposes NextRails.next?/current? for any code/config
# that needs to branch during a version hop. Keep this outside any group so
# the helpers are available everywhere. See https://github.com/fastruby/next_rails
gem 'next_rails'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
# Rails 4.2 -> 5.0 hop (Task 4, roadmap §7 row 4). Landed:
#
#   - Models now inherit from `ApplicationRecord < ActiveRecord::Base`
#     (app/models/application_record.rb) instead of `ActiveRecord::Base`
#     directly.
#   - `rails-controller-testing` added (see :test group below) — Rails 5.0
#     extracted `assigns`/`assert_template` out of Action Controller and
#     several controller tests use `assigns`.
#   - `config.active_record.belongs_to_required_by_default = false` set in
#     config/application.rb to preserve this app's existing optional-by-default
#     `belongs_to` behavior (Rails 5.0 makes it required-by-default otherwise).
#     Auditing individual associations to opt into the new default is a
#     deliberate future follow-up, not part of this hop.
#   - devise bumped 3.5.10 -> 4.2.x (see below) to support railties 5.0.
#   - jquery-rails bumped 3.1.4 -> 4.3.x (its railties cap was `< 5.0`).
#   - ransack pinned to the one release (2.3.0) whose activerecord dependency
#     (`>= 5.0`, no upper bound) is compatible with Rails 5.0 — see below.
#   - foundation-rails 5.2.1.0 and omniauth-google-oauth2 (unpinned, resolves
#     to 0.8.2 because of the `omniauth ~> 1.9` pin) needed **no change** —
#     neither has a railties/rails upper bound that excludes 5.0, contrary to
#     the roadmap's static-analysis guess.
#   - jquery-turbolinks needed no change either — it has no version cap on
#     `turbolinks`.
#   - cancancan 1.x has no rails/railties dependency at the gem-constraint
#     level, so it was left pinned; verified it still works at runtime against
#     Rails 5.0 via the existing characterization test suite (Ability specs
#     and controller tests).
#   - doorkeeper 1.1.0 only requires `railties >= 3.1` (no upper cap) and still
#     boots/functions against Rails 5.0, so it was **not** bumped — a full
#     doorkeeper 1.1 -> 5.x OAuth-server migration stays scoped to roadmap
#     Task 10, not this hop.
gem 'rails', '~> 5.0.0'

# Rails 4.2 extracted the class-level `respond_to`/`respond_with` API (used by
# Api::V1::CredentialsController) out of Action Controller into this gem.
gem 'responders', '~> 2.0'

# Ruby 2.3 ceiling: nokogiri >= 1.11 requires Ruby >= 2.5, so pin to the last
# release supporting Ruby 2.3. loofah/rails-html-sanitizer must be pinned in
# lockstep — loofah >= 2.20 assumes the Nokogiri::HTML4/HTML5 split that only
# exists on nokogiri >= 1.11, so left unpinned they resolve to versions that
# raise `NameError: uninitialized constant Nokogiri::HTML4` on boot. Revisit
# once the Ruby ramp (§3) lands.
gem 'nokogiri', '~> 1.10.10'
gem 'loofah', '~> 2.19.1'
gem 'rails-html-sanitizer', '~> 1.4.4'

# devise 3.5.10's omniauth integration hard-asserts `OmniAuth::VERSION =~ /^1\./`
# (lib/devise/omniauth.rb) and raises on boot otherwise. Left unpinned,
# omniauth-oauth2/omniauth-google-oauth2 resolve to a 2.x omniauth. Pin to the
# same 1.x line this Gemfile resolves to until devise is upgraded.
gem 'omniauth', '~> 1.9'

# Use mysql as the database for Active Record
gem 'mysql2', '0.3.21'

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
gem 'jbuilder', '~> 1.2'

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


# devise 3.5.10 caps `railties < 5`; bump to the 4.2.x line, which is the
# newest devise release that still caps `railties < 5.1` (i.e. explicitly
# supports Rails 5.0 without pulling in 4.4+'s Rails-5.2-era changes ahead of
# schedule). See Devise's own 3.5 -> 4.x upgrade notes accounted for below.
gem 'devise', '~> 4.2.0'

#gem "less-rails" #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS
gem "foundation-rails",'5.2.1.0'
gem 'hirb'
gem 'thin'
gem 'carrierwave', '1.0'
gem "mini_magick"
gem "select2-rails", '3.5.4'
#gem "cancan"
gem 'cancancan', '~> 1.7'
gem "omniauth-google-oauth2"
# ransack unpinned resolves to a release requiring Ruby >= 2.6 (above this
# repo's Ruby 2.3 ceiling) and, from 2.3.1 on, activerecord >= 5.2.1 (above
# Rails 5.0). 2.3.0 is the one release compatible with both ceilings
# (activerecord >= 5.0, no upper bound; ruby >= 1.9). Revisit this pin at the
# 5.1/5.2 hop.
gem 'ransack', '2.3.0'
gem "will_paginate"
gem "cocoon"
gem 'wicked_pdf', '0.9.10'
gem 'wkhtmltopdf-binary' # bundle the binary so there's no system-level wkhtmltopdf dependency
gem 'friendly_id', '~> 5.0.0'
# doorkeeper 1.1.0 only requires `railties >= 3.1` (no upper cap) and still
# boots/works under Rails 5.0 — left unbumped; a full doorkeeper 1.1 -> 5.x
# OAuth-server migration is roadmap Task 10, not this hop.
gem 'doorkeeper', '1.1.0'

gem "omniauth-oauth2"#, '1.0.2'
#gem 'omniauth-fluxapp' , :path => '/home/tp/Desktop/flux'
gem 'omniauth-fluxapp' , :git  => 'https://github.com/stpnlr/omniauth-fluxapp.git'
gem 'tzinfo-data'

group :test do
  # Ruby 2.3 ceiling: simplecov >= 0.18 requires Ruby >= 2.4/2.5, so pin to the
  # last release supporting Ruby 2.3. Revisit once the Ruby ramp (§3) lands.
  gem 'simplecov', '~> 0.17.1', require: false

  # Rails 5.0 extracted `assigns`/`assert_template` out of Action Controller;
  # several controller tests use `assigns`, so pull them back in explicitly.
  gem 'rails-controller-testing'
end
