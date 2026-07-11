require 'test_helper'

class ReportsHelperTest < ActionView::TestCase
  # ReportsHelper is currently an empty module (app/helpers/reports_helper.rb).
  # Pin that fact so any future method addition surfaces here for coverage.
  test "reports helper defines no custom instance methods" do
    assert_equal [], ReportsHelper.instance_methods(false)
  end
end
