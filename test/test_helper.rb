require 'simplecov'
SimpleCov.start 'rails'
SimpleCov.coverage_dir(ENV['COVERAGE_DIR']) if ENV['COVERAGE_DIR']

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # `ActiveRecord::Migration.check_pending!` (a public class method) was
  # removed by Rails 7.1/8.0 -- the pending-migration check it did is now
  # handled automatically by `rails/testing/maintain_test_schema` (loaded via
  # `rails/test_help`, required above) instead. Guard the call so this file
  # keeps working unmodified on both the current Gemfile (Rails 7.0, where
  # the method still exists) and Gemfile.next (Rails 8.0, roadmap Task 9)
  # during the dual-boot window.
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
