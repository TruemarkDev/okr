require 'test_helper'

class ReportingManagerTest < ActiveSupport::TestCase
  test "belongs_to user and manager (both User)" do
    reporting_manager = reporting_managers(:one)
    assert_respond_to reporting_manager, :user
    assert_respond_to reporting_manager, :manager
  end

  test "default scope excludes archived reporting_managers" do
    employee = User.create!(email: "rm_employee@example.com", password: "password123",
                             name: "RM Employee", nickname: "rmemployee",
                             employee_code: "RME001", role: "employee")
    manager = User.create!(email: "rm_manager@example.com", password: "password123",
                            name: "RM Manager", nickname: "rmmanager",
                            employee_code: "RMM001", role: "manager")
    archived = ReportingManager.create!(user_id: employee.id, manager_id: manager.id, status: "archived")

    assert_not_includes ReportingManager.pluck(:id), archived.id
    assert_includes ReportingManager.unscoped.pluck(:id), archived.id
  end

  test "status defaults to active" do
    employee = User.create!(email: "rm_employee2@example.com", password: "password123",
                             name: "RM Employee2", nickname: "rmemployee2",
                             employee_code: "RME002", role: "employee")
    manager = User.create!(email: "rm_manager2@example.com", password: "password123",
                            name: "RM Manager2", nickname: "rmmanager2",
                            employee_code: "RMM002", role: "manager")
    reporting_manager = ReportingManager.create!(user_id: employee.id, manager_id: manager.id)

    assert_equal "active", reporting_manager.reload.status
  end

  test "manager association resolves the User referenced by manager_id" do
    employee = User.create!(email: "rm_employee3@example.com", password: "password123",
                             name: "RM Employee3", nickname: "rmemployee3",
                             employee_code: "RME003", role: "employee")
    manager = User.create!(email: "rm_manager3@example.com", password: "password123",
                            name: "RM Manager3", nickname: "rmmanager3",
                            employee_code: "RMM003", role: "manager")
    reporting_manager = ReportingManager.create!(user_id: employee.id, manager_id: manager.id)

    assert_equal manager, reporting_manager.manager
    assert_equal employee, reporting_manager.user
  end

  test "user's reporting_employees derives from manager_id" do
    employee = User.create!(email: "rm_employee4@example.com", password: "password123",
                             name: "RM Employee4", nickname: "rmemployee4",
                             employee_code: "RME004", role: "employee")
    manager = User.create!(email: "rm_manager4@example.com", password: "password123",
                            name: "RM Manager4", nickname: "rmmanager4",
                            employee_code: "RMM004", role: "manager")
    ReportingManager.create!(user_id: employee.id, manager_id: manager.id)

    assert_includes manager.reporting_employees.collect(&:user_id), employee.id
    assert_includes manager.users.collect(&:id), employee.id
  end
end
