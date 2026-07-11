require 'test_helper'

class ProjectManagerTest < ActiveSupport::TestCase
  test "belongs_to project and user" do
    project_manager = project_managers(:one)
    assert_respond_to project_manager, :project
    assert_respond_to project_manager, :user
  end

  test "default scope excludes archived project_managers" do
    project = Project.create!(name: "PM Scope Project", code: "PMSP1")
    user = User.create!(email: "pm_scope_user@example.com", password: "password123",
                         name: "PM Scope User", nickname: "pmscopeuser",
                         employee_code: "PMS001", role: "employee")
    archived = ProjectManager.create!(project_id: project.id, user_id: user.id, status: "archived")

    assert_not_includes ProjectManager.pluck(:id), archived.id
    assert_includes ProjectManager.unscoped.pluck(:id), archived.id
  end

  test "status defaults to active" do
    project = Project.create!(name: "PM Status Project", code: "PMSTP1")
    user = User.create!(email: "pm_status_user@example.com", password: "password123",
                         name: "PM Status User", nickname: "pmstatususer",
                         employee_code: "PST001", role: "employee")
    project_manager = ProjectManager.create!(project_id: project.id, user_id: user.id)

    assert_equal "active", project_manager.reload.status
  end

  test "after_save updates the user's admin_projects_count" do
    project = Project.create!(name: "PM AfterSave Project", code: "PMASP1")
    user = User.create!(email: "pm_aftersave_user@example.com", password: "password123",
                         name: "PM AfterSave User", nickname: "pmaftersaveuser",
                         employee_code: "PAS001", role: "employee")

    ProjectManager.create!(project_id: project.id, user_id: user.id)

    assert_equal 1, user.reload.admin_projects_count
  end

  test "after_destroy updates the user's admin_projects_count back down" do
    project = Project.create!(name: "PM AfterDestroy Project", code: "PMADP1")
    user = User.create!(email: "pm_afterdestroy_user@example.com", password: "password123",
                         name: "PM AfterDestroy User", nickname: "pmafterdestroyuser",
                         employee_code: "PAD001", role: "employee")
    project_manager = ProjectManager.create!(project_id: project.id, user_id: user.id)
    assert_equal 1, user.reload.admin_projects_count

    project_manager.destroy

    assert_equal 0, user.reload.admin_projects_count
  end
end
