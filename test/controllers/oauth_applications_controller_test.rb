require 'test_helper'

class OauthApplicationsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
    @oauth_application = oauth_applications(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:oauth_applications)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create oauth_application" do
    # OauthApplicationsController#oauth_application_params requires the (plural)
    # :oauth_applications key; redirect_uri must be a valid absolute URI.
    assert_difference('OauthApplication.count') do
      post :create, oauth_applications: { name: @oauth_application.name, redirect_uri: 'https://example.com/callback' }
    end

    assert_redirected_to oauth_application_path(assigns(:oauth_application))
  end

  test "should show oauth_application" do
    get :show, id: @oauth_application
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @oauth_application
    assert_response :success
  end

  test "should update oauth_application" do
    patch :update, id: @oauth_application, oauth_applications: { name: @oauth_application.name, redirect_uri: 'https://example.com/callback' }
    assert_redirected_to oauth_application_path(assigns(:oauth_application))
  end

  test "should destroy oauth_application" do
    assert_difference('OauthApplication.count', -1) do
      delete :destroy, id: @oauth_application
    end

    assert_redirected_to oauth_applications_path
  end

  # ---- assigns / behavior characterization --------------------------------

  test "index assigns oauth_applications, first application, and its users" do
    get :index
    assert_not_nil assigns(:oauth_applications)
    assert_equal assigns(:oauth_applications).first, assigns(:oauth_application)
    assert_not_nil assigns(:users)
  end

  test "new assigns a blank application and the ordered list" do
    get :new
    assert assigns(:oauth_application).new_record?
    assert_not_nil assigns(:oauth_applications)
  end

  test "show assigns the application's users" do
    get :show, id: @oauth_application
    assert_equal @oauth_application, assigns(:oauth_application)
    assert_not_nil assigns(:users)
  end

  test "edit assigns user_ids of the application" do
    get :edit, id: @oauth_application
    assert_not_nil assigns(:user_ids)
  end

  test "create assigns the selected user_ids to the application" do
    assert_difference('OauthApplication.count') do
      post :create, oauth_applications: {
        name: 'With Users',
        redirect_uri: 'https://example.com/callback',
        user_ids: [users(:admin).id]
      }
    end
    app = assigns(:oauth_application)
    assert_equal [users(:admin).id], OauthApplication.find(app.id).user_ids
  end

  # ---- authorization ------------------------------------------------------

  test "manager can access index" do
    sign_out users(:admin)
    manager = User.create!(name: 'Mgr', nickname: 'mgr', email: "mgr-#{SecureRandom.hex(4)}@example.com",
                           employee_code: "MG#{SecureRandom.hex(3)}", password: 'password123', role: 'manager')
    sign_in manager
    get :index
    assert_response :success
  end

  test "employee is denied and redirected to root with an alert" do
    sign_out users(:admin)
    sign_in users(:one) # role: employee
    get :index
    assert_redirected_to root_url
    assert_not_nil flash[:alert]
  end
end
