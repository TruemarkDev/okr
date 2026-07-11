require 'test_helper'

# Characterization tests for DoorkeeperApplication.
#
# NOTE: `app/models/doorkeeper_application.rb` defines an empty ActiveRecord
# model whose inferred table name is `doorkeeper_applications` — a table that
# does NOT exist in the schema (Doorkeeper is wired to the `oauth_applications`
# table via Doorkeeper::Application, and this bare class is unused in app code).
# These tests pin that current reality: the class exists, but any operation that
# needs the schema raises because the backing table is missing.
class DoorkeeperApplicationTest < ActiveSupport::TestCase
  test "class is defined as an ActiveRecord model" do
    assert DoorkeeperApplication < ActiveRecord::Base
  end

  test "infers the non-existent doorkeeper_applications table name" do
    assert_equal 'doorkeeper_applications', DoorkeeperApplication.table_name
  end

  test "instantiating raises because the backing table does not exist" do
    error = assert_raises(ActiveRecord::StatementInvalid) { DoorkeeperApplication.new }
    assert_match(/doorkeeper_applications/, error.message)
  end

  test "querying raises because the backing table does not exist" do
    assert_raises(ActiveRecord::StatementInvalid) { DoorkeeperApplication.count }
  end
end
