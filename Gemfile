source 'https://rubygems.org'

# Dual-boot scaffold (FastRuby methodology): lets this app boot against either
# this Gemfile (current: Rails 4.2, promoted from Gemfile.next by roadmap
# Task 3) or Gemfile.next (next hop target, currently Rails 5.0 per Task 4)
# via BUNDLE_GEMFILE, and exposes NextRails.next?/current? for any code/config
# that needs to branch during a version hop. Keep this outside any group so
# the helpers are available everywhere. See https://github.com/fastruby/next_rails
gem 'next_rails'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.0'

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
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'execjs', '~> 2.7.0'
gem 'uglifier', '< 4'
gem 'multipart-post', '< 2.0'

gem 'faraday', '< 0.10'


# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', '3.1.4'

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


gem 'devise', '~> 3.5.10'

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
gem "ransack"
gem "will_paginate"
gem "cocoon"
gem 'wicked_pdf', '0.9.10'
gem 'wkhtmltopdf-binary' # bundle the binary so there's no system-level wkhtmltopdf dependency
gem 'friendly_id', '~> 5.0.0'
gem 'doorkeeper', '1.1.0'

gem "omniauth-oauth2"#, '1.0.2'
#gem 'omniauth-fluxapp' , :path => '/home/tp/Desktop/flux'
gem 'omniauth-fluxapp' , :git  => 'https://github.com/stpnlr/omniauth-fluxapp.git'
gem 'tzinfo-data'

group :test do
  # Ruby 2.3 ceiling: simplecov >= 0.18 requires Ruby >= 2.4/2.5, so pin to the
  # last release supporting Ruby 2.3. Revisit once the Ruby ramp (§3) lands.
  gem 'simplecov', '~> 0.17.1', require: false
end
