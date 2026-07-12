require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
    @project = projects(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create project" do
    # Project validates uniqueness of code; fixtures already use "MyString", so
    # pass a unique code to exercise the create-success path.
    assert_difference('Project.count') do
      post :create, params: { project: { code: 'NEWCODE', description: @project.description, is_deleted: @project.is_deleted, name: @project.name } }
    end

    assert_redirected_to project_path(assigns(:project))
  end

  test "should show project" do
    get :show, params: { id: @project }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @project }
    assert_response :success
  end

  test "should update project" do
    # Unique code so the uniqueness validation passes and update redirects.
    patch :update, params: { id: @project, project: { code: 'UPDATEDCODE', description: @project.description, is_deleted: @project.is_deleted, name: @project.name } }
    assert_redirected_to project_path(assigns(:project))
  end

  test "should destroy project" do
    # Project#destroy is overridden to soft-delete (sets is_deleted), so the row
    # is not removed and Project.count is unchanged.
    assert_no_difference('Project.count') do
      delete :destroy, params: { id: @project }
    end

    assert_redirected_to projects_path
  end

  test "create with invalid params re-renders new without creating a record" do
    assert_no_difference('Project.count') do
      post :create, params: { project: { code: '', name: '' } }
    end
    assert_response :success
    assert_template :new
  end

  test "update with a duplicate code re-renders edit without persisting" do
    Project.create!(name: "Other Project", code: "TAKEN1")
    patch :update, params: { id: @project, project: { code: 'TAKEN1', name: @project.name } }
    assert_response :success
    assert_template :edit
    assert_not_equal 'TAKEN1', @project.reload.code
  end

  test "show assigns teams, managers and members for the project" do
    get :show, params: { id: @project }
    assert_response :success
    assert_not_nil assigns(:teams)
    assert_not_nil assigns(:managers)
    assert_not_nil assigns(:members)
  end
end

class ProjectsControllerEmployeeAuthorizationTest < ActionController::TestCase
  tests ProjectsController

  setup do
    @employee = User.create!(email: "projects_employee@example.com", password: "password123",
                              name: "Projects Employee", nickname: "projectsemployee",
                              employee_code: "PREMP1", role: "employee")
    sign_in @employee
  end

  # Characterization note: Ability grants employees only :read/:edit/:update on
  # Project (no :new/:create rule), so load_and_authorize_resource denies new/create.
  test "employee cannot access new (no create ability granted)" do
    get :new
    assert_redirected_to root_url
  end

  test "employee cannot create a project (no create ability granted)" do
    assert_no_difference('Project.count') do
      post :create, params: { project: { code: 'EMPNEW1', name: 'Employee New Project' } }
    end
    assert_redirected_to root_url
  end

  test "employee can read any project" do
    project = Project.create!(name: "Readable Project", code: "READ1")
    get :show, params: { id: project }
    assert_response :success
  end
end
