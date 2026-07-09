require 'simplecov'
SimpleCov.start 'rails'
SimpleCov.coverage_dir(ENV['COVERAGE_DIR']) if ENV['COVERAGE_DIR']

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# Devise 3.5 Minitest integration: gives ActionController::TestCase access to
# sign_in / sign_out for controller tests (ApplicationController has a global
# authenticate_user! before_filter).
class ActionController::TestCase
  include Devise::TestHelpers
end
