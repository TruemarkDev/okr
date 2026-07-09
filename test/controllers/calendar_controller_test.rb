require 'test_helper'

class CalendarControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get monthly" do
    get :monthly
    assert_response :success
  end

end
