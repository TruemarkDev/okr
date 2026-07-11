require 'test_helper'

# Characterization tests for app/models/ability.rb (CanCanCan rules).
# Pins the CURRENT authorization behavior for admin / manager / employee /
# guest, including the employee scoping to own OKRs/tasks, reporting employees,
# and project/team membership. Asserts what the rules DO today.
class AbilityTest < ActiveSupport::TestCase
  def make_user!(attrs = {})
    defaults = {
      name: 'Ability User',
      nickname: 'abil',
      email: "abil-#{SecureRandom.hex(4)}@example.com",
      employee_code: "AB#{SecureRandom.hex(3)}",
      password: 'password123',
      role: 'employee'
    }
    User.create!(defaults.merge(attrs))
  end

  def build_project_and_team
    project = Project.create!(name: "Proj #{SecureRandom.hex(3)}", code: "PRJ#{SecureRandom.hex(3)}")
    team = Team.create!(name: "Team #{SecureRandom.hex(3)}", code: "TM#{SecureRandom.hex(3)}", project: project)
    [project, team]
  end

  # ---- admin --------------------------------------------------------------

  test "admin can manage everything" do
    ability = Ability.new(users(:admin))
    assert ability.can?(:manage, :all)
    assert ability.can?(:manage, User)
    assert ability.can?(:destroy, Okr.new)
    assert ability.can?(:manage, :oauth_applications)
  end

  # ---- manager ------------------------------------------------------------

  test "manager can manage everything and oauth_applications symbol" do
    manager = make_user!(role: 'manager')
    ability = Ability.new(manager)
    assert ability.can?(:manage, :all)
    assert ability.can?(:manage, User)
    assert ability.can?(:manage, Task.new)
    assert ability.can?(:manage, :oauth_applications)
  end

  # ---- guest (nil user -> User.new, role nil) -----------------------------

  # Ability#initialize does `user ||= User.new`; that guest has role nil, and
  # admin?/manager?/employee? all call role.downcase -> raises. So building an
  # Ability for a guest (or any role-less user) blows up.
  test "guest user (nil) raises because role helpers dereference nil role" do
    assert_raises(NoMethodError) { Ability.new(nil) }
  end

  test "user with nil role raises when building ability" do
    roleless = User.new
    assert_raises(NoMethodError) { Ability.new(roleless) }
  end

  # ---- employee: projects & teams -----------------------------------------

  test "employee can read but not manage arbitrary projects/teams" do
    emp = make_user!(role: 'employee')
    project, _team = build_project_and_team
    ability = Ability.new(emp)

    assert ability.can?(:read, Project)
    assert ability.can?(:read, Team)
    assert ability.can?(:index, Team)
    # not a project manager of this project -> cannot edit
    refute ability.can?(:edit, project)
  end

  test "employee can edit/update projects they manage" do
    emp = make_user!(role: 'employee')
    project, _team = build_project_and_team
    ProjectManager.create!(project: project, user: emp)
    ability = Ability.new(emp.reload)

    assert ability.can?(:edit, project)
    assert ability.can?(:update, project)
  end

  test "employee can manage teams whose project they manage" do
    emp = make_user!(role: 'employee')
    project, team = build_project_and_team
    ProjectManager.create!(project: project, user: emp)
    ability = Ability.new(emp.reload)

    assert ability.can?(:manage, team)
  end

  test "employee cannot manage a team in a project they do not manage" do
    emp = make_user!(role: 'employee')
    _project, team = build_project_and_team
    ability = Ability.new(emp)

    refute ability.can?(:manage, team)
  end

  # ---- employee: users ----------------------------------------------------

  test "employee can read all users" do
    emp = make_user!(role: 'employee')
    ability = Ability.new(emp)
    assert ability.can?(:read, User)
  end

  test "employee can edit themselves and their reporting employees only" do
    emp = make_user!(role: 'employee')
    report = make_user!(role: 'employee')
    other = make_user!(role: 'employee')
    ReportingManager.create!(user: report, manager: emp)
    ability = Ability.new(emp.reload)

    assert ability.can?(:edit, emp)
    assert ability.can?(:update, emp)
    assert ability.can?(:edit, report)
    refute ability.can?(:edit, other)
  end

  test "employee can change_password on User" do
    emp = make_user!(role: 'employee')
    ability = Ability.new(emp)
    assert ability.can?(:change_password, User)
  end

  # ---- employee: OKRs -----------------------------------------------------

  test "employee can read their own okr and reporting employees' okrs" do
    emp = make_user!(role: 'employee')
    report = make_user!(role: 'employee')
    stranger = make_user!(role: 'employee')
    ReportingManager.create!(user: report, manager: emp)
    ability = Ability.new(emp.reload)

    own = Okr.create!(user: emp, name: 'Own', start_date: Date.today, end_date: Date.today + 10)
    reports_okr = Okr.create!(user: report, name: 'Report', start_date: Date.today, end_date: Date.today + 10)
    strangers = Okr.create!(user: stranger, name: 'Stranger', start_date: Date.today, end_date: Date.today + 10)

    assert ability.can?(:read, own)
    assert ability.can?(:read, reports_okr)
    refute ability.can?(:read, strangers)
  end

  test "employee can destroy okrs of reporting employees but not their own" do
    emp = make_user!(role: 'employee')
    report = make_user!(role: 'employee')
    ReportingManager.create!(user: report, manager: emp)
    ability = Ability.new(emp.reload)

    own = Okr.create!(user: emp, name: 'Own', start_date: Date.today, end_date: Date.today + 10)
    reports_okr = Okr.create!(user: report, name: 'Report', start_date: Date.today, end_date: Date.today + 10)

    # destroy rule only checks user.user_ids (reporting employees), NOT self
    refute ability.can?(:destroy, own)
    assert ability.can?(:destroy, reports_okr)
  end

  test "employee cru on unapproved okrs of self or reporting employees" do
    emp = make_user!(role: 'employee')
    report = make_user!(role: 'employee')
    ReportingManager.create!(user: report, manager: emp)
    ability = Ability.new(emp.reload)

    unapproved = Okr.create!(user: emp, name: 'Un', start_date: Date.today, end_date: Date.today + 10, approved: false)
    approved = Okr.create!(user: emp, name: 'Ap', start_date: Date.today, end_date: Date.today + 10, approved: true)

    assert ability.can?(:update, unapproved)
    assert ability.can?(:create, unapproved)
    # cru rule is gated on approved => false, so approved okrs are not updatable via it
    refute ability.can?(:update, approved)
  end

  # ---- employee: tasks ----------------------------------------------------

  test "employee can manage a task they authored" do
    emp = make_user!(role: 'employee')
    _project, team = build_project_and_team
    task = Task.create!(name: 'Mine', team: team, project: team.project, user: emp)
    ability = Ability.new(emp.reload)

    assert ability.can?(:manage, task)
  end

  test "employee can manage tasks in a project they manage" do
    emp = make_user!(role: 'employee')
    author = make_user!(role: 'employee')
    project, team = build_project_and_team
    ProjectManager.create!(project: project, user: emp)
    task = Task.create!(name: 'InProj', team: team, project: project, user: author)
    ability = Ability.new(emp.reload)

    assert ability.can?(:manage, task)
  end

  test "employee can manage tasks in a team they lead (admin_team_ids)" do
    emp = make_user!(role: 'employee')
    author = make_user!(role: 'employee')
    _project, team = build_project_and_team
    TeamMember.create!(team: team, user: emp, role: 'lead')
    task = Task.create!(name: 'InTeam', team: team, project: team.project, user: author)
    ability = Ability.new(emp.reload)

    assert ability.can?(:manage, task)
  end

  test "employee cannot manage an unrelated task but a new (nil-id) task is allowed" do
    emp = make_user!(role: 'employee')
    author = make_user!(role: 'employee')
    _project, team = build_project_and_team
    task = Task.create!(name: 'Unrelated', team: team, project: team.project, user: author)
    ability = Ability.new(emp.reload)

    refute ability.can?(:manage, task)
    # nil-id (unpersisted) task short-circuits both manage and read rules to true
    assert ability.can?(:manage, Task.new)
    assert ability.can?(:read, Task.new)
  end

  test "employee can read a task assigned to them via key results (task.user_ids)" do
    emp = make_user!(role: 'employee')
    author = make_user!(role: 'employee')
    _project, team = build_project_and_team

    okr = Okr.create!(user: emp, name: 'OKR', start_date: Date.today, end_date: Date.today + 10)
    objective = Objective.create!(okr: okr, user: emp, name: 'Obj')
    kr = KeyResult.create!(objective: objective, user: emp, name: 'KR')
    task = Task.create!(name: 'Assigned', team: team, project: team.project, user: author)
    TaskKeyResult.create!(task: task, key_result: kr)
    ability = Ability.new(emp.reload)

    assert task.user_ids.include?(emp.id)
    assert ability.can?(:read, task)
    # read is allowed via assignment, but manage (no assignment branch) is not
    refute ability.can?(:manage, task)
  end

  test "employee can read a task in a team they are a member of (team_ids)" do
    emp = make_user!(role: 'employee')
    author = make_user!(role: 'employee')
    _project, team = build_project_and_team
    TeamMember.create!(team: team, user: emp) # plain member, not lead
    task = Task.create!(name: 'TeamRead', team: team, project: team.project, user: author)
    ability = Ability.new(emp.reload)

    assert ability.can?(:read, task)
  end
end
