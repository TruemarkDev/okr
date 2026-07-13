require 'test_helper'

# Characterization tests for UsersController — the user/role/password-management
# surface (adjacent auth-risk class to the Doorkeeper work). Pins current behavior
# of the permission-sensitive paths: `user_params` permitting :role / :password /
# manager_ids, `change_password`, the soft-delete `destroy` (archive_user), and the
# CanCan `load_and_authorize_resource` boundary. Signs in as admin (can :manage,
# :all) except where an employee is used to characterize denial.
class UsersControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
    @user = users(:admin)
  end

  def new_user_attrs(overrides = {})
    {
      name: 'New Person',
      nickname: "np#{SecureRandom.hex(3)}",
      email: "np-#{SecureRandom.hex(4)}@example.com",
      employee_code: "NP#{SecureRandom.hex(3)}",
      password: 'password123',
      password_confirmation: 'password123',
      role: 'employee'
    }.merge(overrides)
  end

  # --- read paths ----------------------------------------------------------

  test "index lists active users ordered by name" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "new assigns a blank user" do
    get :new
    assert_response :success
    assert assigns(:user).new_record?
  end

  # --- create: exercises user_params (role/password/manager_ids) -----------

  test "create with valid params creates a user and redirects" do
    assert_difference('User.count', 1) do
      post :create, params: { user: new_user_attrs(role: 'Manager') }
    end
    assert_equal 'Manager', assigns(:user).role
    assert_redirected_to user_path(assigns(:user))
  end

  test "create with invalid params does not create and re-renders new" do
    assert_no_difference('User.count') do
      post :create, params: { user: new_user_attrs(email: '') }
    end
    assert_response :success
    assert assigns(:user).errors.any?
  end

  # --- update: role change -------------------------------------------------

  test "update changes the role and redirects" do
    target = User.create!(new_user_attrs)
    patch :update, params: { id: target.friendly_id, user: { role: 'Manager' } }
    assert_redirected_to user_path(assigns(:user))
    assert_equal 'Manager', target.reload.role
  end

  # --- change_password -----------------------------------------------------

  test "change_password POST updates the current user's password" do
    post :change_password, params: { user: { password: 'newpassword1', password_confirmation: 'newpassword1' } }
    assert_redirected_to user_path(assigns(:user))
    assert users(:admin).reload.valid_password?('newpassword1')
  end

  # --- destroy: soft delete via archive_user -------------------------------

  test "destroy soft-deletes the user (archive_user) rather than removing the row" do
    target = User.create!(new_user_attrs)
    assert_no_difference('User.count') do
      delete :destroy, params: { id: target.friendly_id }
    end
    assert target.reload.is_deleted
    assert_redirected_to users_url
  end

  # --- authorization boundary (CanCan load_and_authorize_resource) ---------

  test "employee cannot create a user and is redirected to root with an alert" do
    sign_out users(:admin)
    sign_in users(:one) # role: employee
    assert_no_difference('User.count') do
      post :create, params: { user: new_user_attrs }
    end
    assert_redirected_to root_url
    assert_not_nil flash[:alert]
  end
end
