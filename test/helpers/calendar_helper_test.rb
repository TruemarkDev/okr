require 'test_helper'

class CalendarHelperTest < ActionView::TestCase
  # CalendarHelper is currently an empty module (app/helpers/calendar_helper.rb).
  test "calendar helper defines no custom instance methods" do
    assert_equal [], CalendarHelper.instance_methods(false)
  end
end
