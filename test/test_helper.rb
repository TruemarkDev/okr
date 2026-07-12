require 'simplecov'
SimpleCov.start 'rails'
SimpleCov.coverage_dir(ENV['COVERAGE_DIR']) if ENV['COVERAGE_DIR']

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# Force routes to be drawn once, right now, instead of leaving them to Rails
# 7.1+'s lazy `Rails::Engine::LazyRouteSet` (routes are only drawn on first
# interaction with `Rails.application.routes`, normally the first `get`/`post`
# dispatch, which in `ActionController::TestCase` happens *inside* `process`
# -- wrapped in `Rails.application.executor.wrap` -- not during `setup`).
# `devise_for :users` in config/routes.rb is what populates `Devise.mappings`,
# so until routes are drawn, `Devise::Test::ControllerHelpers#sign_in` (called
# from many controller tests' `setup` blocks, before any request is
# dispatched) raises `RuntimeError: Could not find a valid mapping for
# #<User ...>`. Whether this happens is a pure test-order race: it only
# surfaces when a `sign_in`-in-setup test is the very first thing in the
# whole process to touch anything Devise-mapping-related, i.e. no earlier
# test happened to already trigger a request dispatch first -- reproduced
# deterministically as ProjectsControllerEmployeeAuthorizationTest failing on
# `--seed=2`/`--seed=3` (whenever Minitest's random test order puts it first)
# and passing on other seeds. Pre-Rails-7.1, routes were drawn eagerly at
# boot, so every test's `setup` could rely on `Devise.mappings` already being
# populated regardless of order; this one-line eager draw restores that
# guarantee for the test environment without touching test order or masking
# the error with a rescue/retry.
Rails.application.reload_routes!

class ActiveSupport::TestCase
  # `ActiveRecord::Migration.check_pending!` (a public class method) was
  # removed by Rails 7.1/8.0 -- the pending-migration check it did is now
  # handled automatically by `rails/testing/maintain_test_schema` (loaded via
  # `rails/test_help`, required above) instead. Guarded (rather than deleted)
  # since it was written during the roadmap Task 9 dual-boot window, when
  # this file had to run unmodified against both Rails 7.0 (Gemfile, where
  # the method still existed) and Rails 8.0 (Gemfile.next); harmless to leave
  # guarded now that the dual-boot scaffold itself is retired (Task 12).
  ActiveRecord::Migration.check_pending! if ActiveRecord::Migration.respond_to?(:check_pending!)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# Devise 3.5 Minitest integration: gives ActionController::TestCase access to
# sign_in / sign_out for controller tests (ApplicationController has a global
# authenticate_user! before_action).
class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end
