require 'test_helper'

# Characterization tests for User — pins CURRENT behavior of the auth-critical
# model (Devise modules, role helpers, visibility helpers, derived assignments,
# validations, soft-delete). These assert what the code DOES today, quirks
# included; they are not a statement of what it SHOULD do.
class UserTest < ActiveSupport::TestCase
  # ---- helpers ------------------------------------------------------------

  def build_user(attrs = {})
    defaults = {
      name: 'Probe User',
      nickname: 'probe',
      email: "probe-#{SecureRandom.hex(4)}@example.com",
      employee_code: "PC#{SecureRandom.hex(3)}",
      password: 'password123',
      role: 'employee'
    }
    User.new(defaults.merge(attrs))
  end

  def create_user!(attrs = {})
    build_user(attrs).tap(&:save!)
  end

  # Builds a project + team so Task callbacks (which touch team/project) don't blow up.
  def build_project_and_team
    project = Project.create!(name: "Proj #{SecureRandom.hex(3)}", code: "PRJ#{SecureRandom.hex(3)}")
    team = Team.create!(name: "Team #{SecureRandom.hex(3)}", code: "TM#{SecureRandom.hex(3)}", project: project)
    [project, team]
  end

  # ---- Devise configuration ----------------------------------------------

  test "includes the expected devise modules" do
    modules = User.devise_modules
    assert_includes modules, :database_authenticatable
    assert_includes modules, :recoverable
    assert_includes modules, :rememberable
    assert_includes modules, :trackable
    assert_includes modules, :validatable
    assert_includes modules, :omniauthable
  end

  test "omniauth providers are google_oauth2 and fluxapp" do
    assert_equal [:google_oauth2, :fluxapp], User.omniauth_providers
  end

  # ---- role helpers (case handling) --------------------------------------

  test "admin? downcases the role string" do
    assert build_user(role: 'admin').admin?
    assert build_user(role: 'ADMIN').admin?
    assert build_user(role: 'Admin').admin?
    refute build_user(role: 'employee').admin?
    refute build_user(role: 'manager').admin?
  end

  test "manager? is true for both manager and admin (any case)" do
    assert build_user(role: 'manager').manager?
    assert build_user(role: 'Manager').manager?
    assert build_user(role: 'admin').manager?
    assert build_user(role: 'ADMIN').manager?
    refute build_user(role: 'employee').manager?
  end

  test "employee? downcases the role string" do
    assert build_user(role: 'employee').employee?
    assert build_user(role: 'EMPLOYEE').employee?
    refute build_user(role: 'admin').employee?
    refute build_user(role: 'manager').employee?
  end

  test "role helpers raise when role is nil (no nil-guard)" do
    u = build_user(role: nil)
    assert_raises(NoMethodError) { u.admin? }
    assert_raises(NoMethodError) { u.manager? }
    assert_raises(NoMethodError) { u.employee? }
  end

  test "admin fixture reports admin and manager but not employee" do
    admin = users(:admin)
    assert admin.admin?
    assert admin.manager?
    refute admin.employee?
  end

  # ---- validations (including quirks) ------------------------------------

  test "name and nickname presence are enforced" do
    u = build_user(name: nil, nickname: nil)
    refute u.valid?
    assert_includes u.errors[:name], "can't be blank"
    assert_includes u.errors[:nickname], "can't be blank"
  end

  test "email presence is enforced (via devise :validatable)" do
    u = build_user(email: nil)
    refute u.valid?
    assert_includes u.errors[:email], "can't be blank"
  end

  test "email uniqueness is enforced (via devise :validatable)" do
    existing = users(:admin)
    u = build_user(email: existing.email)
    refute u.valid?
    assert_includes u.errors[:email], "has already been taken"
  end

  # QUIRK: `validate :employee_code, presence: true, uniqueness: true` uses
  # `validate` (not `validates`), so the presence/uniqueness options are ignored.
  # employee_code is therefore NOT actually validated.
  test "employee_code presence is NOT enforced (validate vs validates quirk)" do
    u = build_user(employee_code: nil)
    u.valid?
    assert_empty u.errors[:employee_code]
  end

  test "employee_code uniqueness is NOT enforced (validate vs validates quirk)" do
    existing = users(:admin)
    u = build_user(employee_code: existing.employee_code)
    u.valid?
    assert_empty u.errors[:employee_code]
    assert u.save, "duplicate employee_code should still save"
  end

  test "password length is enforced by devise validatable" do
    u = build_user(password: 'short')
    refute u.valid?
    assert u.errors[:password].any?
  end

  # ---- soft delete / scopes ----------------------------------------------

  test "is_deleted defaults to false and active scope excludes deleted" do
    u = create_user!
    assert_equal false, u.is_deleted
    assert_includes User.active, u
    u.update_attribute(:is_deleted, true)
    refute_includes User.active, u
  end

  test "by_name scope orders users by name ascending" do
    names = User.by_name.pluck(:name)
    assert_equal names.sort, names
  end

  test "manager_user scope matches admin and 'Manager' (case-sensitive on Manager)" do
    sql = User.manager_user.to_sql
    assert_match(/role in \('admin','Manager'\)/, sql)
  end

  # ---- visibility helpers -------------------------------------------------

  test "project_ids reflects project_managers memberships" do
    u = create_user!
    project, _team = build_project_and_team
    ProjectManager.create!(project: project, user: u)
    assert_equal [project.id], u.reload.project_ids
  end

  test "team_ids reflects team_members memberships" do
    u = create_user!
    _project, team = build_project_and_team
    TeamMember.create!(team: team, user: u)
    assert_includes u.reload.team_ids, team.id
  end

  test "admin_team_ids reflects teams the user leads" do
    u = create_user!
    _project, team = build_project_and_team
    TeamMember.create!(team: team, user: u, role: 'lead')
    assert_includes u.reload.admin_team_ids, team.id
  end

  test "user_ids returns the ids of reporting employees" do
    manager = create_user!(role: 'manager')
    employee = create_user!(role: 'employee')
    ReportingManager.create!(user: employee, manager: manager)
    assert_equal [employee.id], manager.reload.user_ids
    assert_includes manager.users, employee
  end

  test "reporting_employees excludes archived rows (default scope)" do
    manager = create_user!(role: 'manager')
    employee = create_user!(role: 'employee')
    rm = ReportingManager.create!(user: employee, manager: manager)
    assert_equal [employee.id], manager.reload.user_ids
    rm.update_attribute(:status, 'archived')
    assert_equal [], manager.reload.user_ids
  end

  # ---- derived assignments (through key_results) -------------------------

  test "assignments are derived through the user's key results" do
    u = create_user!
    _project, team = build_project_and_team
    okr = Okr.create!(user: u, name: 'OKR', start_date: Date.today, end_date: Date.today + 30)
    objective = Objective.create!(okr: okr, user: u, name: 'Obj')
    kr = KeyResult.create!(objective: objective, user: u, name: 'KR')
    task = Task.create!(name: 'Task', team: team, project: team.project, user: u)
    TaskKeyResult.create!(task: task, key_result: kr)

    assert_includes u.reload.assignments, task
    assert_includes u.key_results, kr
    assert_includes u.objectives, objective
  end

  test "assigned_and_written_tasks unions authored and assigned tasks" do
    u = create_user!
    _project, team = build_project_and_team
    authored = Task.create!(name: 'Authored', team: team, project: team.project, user: u)

    result = u.reload.assigned_and_written_tasks
    assert_includes result, authored
  end

  # ---- archive_user callback cascade -------------------------------------

  test "archive_user soft-deletes the user and archives memberships" do
    u = create_user!
    project, team = build_project_and_team
    pm = ProjectManager.create!(project: project, user: u)
    tm = TeamMember.create!(team: team, user: u)

    u.archive_user

    assert u.reload.is_deleted
    assert_equal 'archived', pm.reload.status
    assert_equal 'archived', TeamMember.unscoped.find(tm.id).status
  end

  # ---- omniauth class method ----------------------------------------------

  test "find_for_google_oauth2 returns an existing user matching the token email" do
    u = create_user!
    token = OpenStruct.new(info: { 'email' => u.email })
    assert_equal u, User.find_for_google_oauth2(token)
  end

  test "find_for_google_oauth2 returns nil when no user matches (create is commented out)" do
    token = OpenStruct.new(info: { 'email' => 'nobody-here@example.com' })
    assert_nil User.find_for_google_oauth2(token)
  end

  # ---- associations present ----------------------------------------------

  test "has the oauth-related associations wired" do
    u = users(:admin)
    assert_respond_to u, :user_oauth_applications
    assert_respond_to u, :oauth_applications
    assert_respond_to u, :okrs
    assert_respond_to u, :tasks
    assert_respond_to u, :assignments
  end
end
