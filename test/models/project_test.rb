require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test "requires name and code" do
    project = Project.new
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
    assert_includes project.errors[:code], "can't be blank"
  end

  test "validates uniqueness of code" do
    dup = Project.new(name: "Another", code: projects(:one).code)
    assert_not dup.valid?
    assert_includes dup.errors[:code], "has already been taken"
  end

  test "default scope orders by name ascending" do
    Project.create!(name: "AAA First", code: "AAA1")
    Project.create!(name: "ZZZ Last", code: "ZZZ1")
    names = Project.all.collect(&:name)
    assert_equal names.sort, names
  end

  test "active scope returns only non-deleted projects" do
    active_project = Project.create!(name: "Active One", code: "ACT1")
    deleted_project = Project.create!(name: "Deleted One", code: "DEL1", is_deleted: true)

    active_ids = Project.active.pluck(:id)
    assert_includes active_ids, active_project.id
    assert_not_includes active_ids, deleted_project.id
  end

  test "has_many teams, tasks, project_managers" do
    project = projects(:one)
    assert_respond_to project, :teams
    assert_respond_to project, :tasks
    assert_respond_to project, :project_managers
    assert_respond_to project, :users
    assert_respond_to project, :team_members
    assert_respond_to project, :project_members
  end

  test "members returns active project_members uniquely" do
    project = Project.create!(name: "Membership Test", code: "MEMB1")
    team = Team.create!(name: "Team A", code: "TEAMA1", project_id: project.id)
    active_user = User.create!(email: "active_member@example.com", password: "password123",
                                name: "Active Member", nickname: "activemember",
                                employee_code: "AM001", role: "employee")
    deleted_user = User.create!(email: "deleted_member@example.com", password: "password123",
                                 name: "Deleted Member", nickname: "deletedmember",
                                 employee_code: "DM001", role: "employee", is_deleted: true)
    TeamMember.create!(team_id: team.id, user_id: active_user.id, role: "member")
    TeamMember.create!(team_id: team.id, user_id: deleted_user.id, role: "member")

    member_ids = project.reload.members.collect(&:id)
    assert_includes member_ids, active_user.id
    assert_not_includes member_ids, deleted_user.id
  end

  test "update_user_project_count updates the given user's admin_projects_count" do
    project = Project.create!(name: "Count Project", code: "CNT1")
    user = User.create!(email: "counted_user@example.com", password: "password123",
                         name: "Counted User", nickname: "counteduser",
                         employee_code: "CU001", role: "employee")
    ProjectManager.create!(project_id: project.id, user_id: user.id)

    project.update_user_project_count(user)
    assert_equal user.projects.count, user.reload.admin_projects_count
  end

  test "update_numbers sets team_count from ALL non-deleted teams, not just active-status ones" do
    project = Project.create!(name: "Team Count Project", code: "TCP1")
    Team.create!(name: "Team X", code: "TEAMX1", project_id: project.id, status: "active")
    Team.create!(name: "Team Y", code: "TEAMY1", project_id: project.id, status: "archived")

    project.update_numbers
    # Characterization note: Project#update_numbers counts self.teams.count (all
    # non-deleted teams, any status) rather than self.teams.active.count -- so an
    # archived-status team still contributes to team_count here, unlike the
    # Team#update_project_team_count callback which uses project.teams.active.count.
    assert_equal 2, project.reload.team_count
    assert_equal project.teams.count, project.team_count
  end

  test "destroy soft-deletes the project and cascades is_deleted to teams and tasks" do
    project = Project.create!(name: "Cascade Project", code: "CAS1")
    team = Team.create!(name: "Cascade Team", code: "CTEAM1", project_id: project.id)
    task = Task.create!(project_id: project.id, team_id: team.id, name: "Cascade Task")

    assert_no_difference('Project.count') do
      project.destroy
    end

    assert project.reload.is_deleted
    assert Team.unscoped.find(team.id).is_deleted
    assert Task.unscoped.find(task.id).is_deleted
  end

  test "destroy archives project_managers directly" do
    project = Project.create!(name: "PM Archive Project", code: "PMA1")
    user = User.create!(email: "pm_archive_user@example.com", password: "password123",
                         name: "PM Archive User", nickname: "pmarchiveuser",
                         employee_code: "PMA001", role: "employee")
    project_manager = ProjectManager.create!(project_id: project.id, user_id: user.id)

    project.destroy

    assert_equal 'archived', ProjectManager.unscoped.find(project_manager.id).status
  end

  # Characterization note: Project#destroy marks each of the project's teams
  # is_deleted before it calls `self.team_members.update_all(status: 'archived')`.
  # Because `team_members` is a has_many :through => :teams association, and
  # Team itself carries `default_scope { where.not(is_deleted: true) }`, the
  # join used by that update_all no longer matches any rows once the teams are
  # already soft-deleted -- so team_members are NOT actually archived by
  # Project#destroy, even though the source reads as if they should be.
  test "destroy does NOT archive team_members due to teams already being soft-deleted first" do
    project = Project.create!(name: "TM Archive Project", code: "TMA1")
    team = Team.create!(name: "TM Archive Team", code: "TMATEAM1", project_id: project.id)
    user = User.create!(email: "tm_archive_user@example.com", password: "password123",
                         name: "TM Archive User", nickname: "tmarchiveuser",
                         employee_code: "TMA001", role: "employee")
    team_member = TeamMember.create!(team_id: team.id, user_id: user.id, role: "member")

    project.destroy

    assert_equal 'active', TeamMember.unscoped.find(team_member.id).status
  end
end
