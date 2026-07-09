require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get activities" do
    get :activities
    assert_response :success
  end

end
