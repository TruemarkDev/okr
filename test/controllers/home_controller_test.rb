require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get dashboard" do
    get :dashboard
    assert_response :success
  end

end
