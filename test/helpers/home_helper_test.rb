require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  # HomeHelper is currently an empty module (app/helpers/home_helper.rb).
  test "home helper defines no custom instance methods" do
    assert_equal [], HomeHelper.instance_methods(false)
  end
end
