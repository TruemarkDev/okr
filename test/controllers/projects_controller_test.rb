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
      post :create, project: { code: 'NEWCODE', description: @project.description, is_deleted: @project.is_deleted, name: @project.name }
    end

    assert_redirected_to project_path(assigns(:project))
  end

  test "should show project" do
    get :show, id: @project
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @project
    assert_response :success
  end

  test "should update project" do
    # Unique code so the uniqueness validation passes and update redirects.
    patch :update, id: @project, project: { code: 'UPDATEDCODE', description: @project.description, is_deleted: @project.is_deleted, name: @project.name }
    assert_redirected_to project_path(assigns(:project))
  end

  test "should destroy project" do
    # Project#destroy is overridden to soft-delete (sets is_deleted), so the row
    # is not removed and Project.count is unchanged.
    assert_no_difference('Project.count') do
      delete :destroy, id: @project
    end

    assert_redirected_to projects_path
  end
end
