source 'https://rubygems.org'

# Targets Rails 8.0 / Ruby 3.3+ (roadmap's target_stack). This is the last
# Rails/Ruby version hop -- no further hop is queued.
gem 'rails', '~> 8.0.0'

# Rails 4.2 extracted the class-level `respond_to`/`respond_with` API (used by
# Api::V1::CredentialsController) out of Action Controller into this gem.
gem 'responders', '~> 3.0'

gem 'nokogiri', '~> 1.19.4'
gem 'loofah', '~> 2.25.1'
gem 'rails-html-sanitizer', '~> 1.7.0'

# devise's omniauth integration is written against OmniAuth 1.x request-phase
# semantics; this app's omniauth-fluxapp / omniauth-oauth2 /
# omniauth-google-oauth2 strategies haven't migrated to OmniAuth 2.0 (GET ->
# POST request phase, needs omniauth-rails_csrf_protection). Keep on 1.x
# until that migration is deliberately scoped.
gem 'omniauth', '~> 1.9'

# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5.7'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Terser (not Uglifier -- its ES5-only parser chokes on the ES6 class syntax
# Rails 8's bundled ActiveStorage/ActionText JS ships with).
gem 'execjs', '~> 2.7.0'
gem 'terser', '~> 1.2'
gem 'multipart-post', '< 2.0'

# Pinned to the last Faraday 1.x release -- transitive dep of
# oauth2/omniauth-google-oauth2 (`>= 0.8, < 3.0`); avoids the 2.x
# adapter-registration breaking change.
gem 'faraday', '~> 1.10'

# Transitive dep of sass-listen (via sass-rails' watcher chain).
gem 'ffi', '~> 1.17.4'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.2.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.3.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# Pinned to the last classic (non-Turbolinks-5-rewrite) release; its
# `URI.escape` crash on Ruby 3.0+ is patched in
# config/initializers/turbolinks_uri_escape_compat.rb -- do not remove that
# initializer.
gem 'turbolinks', '~> 2.5.4'
gem 'jquery-turbolinks', '2.0.2'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.15.1'

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]


# Custom devise views use `render "devise/shared/error_messages", resource:
# resource` (5.0's replacement for the removed `devise_error_messages!`
# helper). 5.0.1-5.0.4 also carry two security fixes (open-redirect in
# FailureApp via Referer; a confirmable email-change race).
gem 'devise', '~> 5.0.4'

gem "foundation-rails",'5.2.1.0'
gem 'hirb'
gem 'thin'
gem 'carrierwave', '1.0'
gem "mini_magick"
gem "select2-rails", '3.5.11'
gem 'cancancan', '~> 3.6'
# Pinned to the last release whose own `omniauth` dependency is `~> 1.1`
# (newer releases require `omniauth ~> 2.0`, incompatible with the
# `omniauth ~> 1.9` pin above).
gem 'omniauth-google-oauth2', '0.8.2'
gem 'ransack', '~> 4.4.1'
gem "will_paginate"
gem "cocoon"
# wkhtmltopdf itself is unmaintained upstream but still renders correctly
# (see config/initializers/wicked_pdf.rb) -- no forcing function to swap
# rendering engines.
gem 'wicked_pdf', '~> 2.8'
gem 'wkhtmltopdf-binary' # bundle the binary so there's no system-level wkhtmltopdf dependency
gem 'friendly_id', '~> 5.7.0'
gem 'doorkeeper', '~> 5.1.2'

gem "omniauth-oauth2"
# omniauth-fluxapp has no rubygems.org release and the upstream repo
# (last pushed 2021-10-03, appears abandoned) has no tags either, so it's
# pinned to a `:ref` rather than left floating on `master`.
gem 'omniauth-fluxapp' , :git => 'https://github.com/stpnlr/omniauth-fluxapp.git', :ref => 'a00079af6e6ebb9dae5ca4c50ff4dfb01a20f159'
gem 'tzinfo-data'

# csv moves from a default gem to a bundled gem in Ruby 3.4; declare it
# explicitly to silence the "will no longer be part of the default gems"
# boot warning under Ruby 3.3.
gem 'csv'

group :test do
  # simplecov 1.x's "rails" profile changes its file-discovery semantics
  # enough to shift the reported coverage denominator without any actual
  # coverage change -- stayed on 0.22.0 for a stable, comparable percentage.
  gem 'simplecov', '~> 0.22.0', require: false

  # Rails 5.0 extracted `assigns`/`assert_template` out of Action Controller;
  # several controller tests use `assigns`, so pull them back in explicitly.
  gem 'rails-controller-testing'
end
