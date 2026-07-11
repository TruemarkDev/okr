require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  test "requires name, code and project_id" do
    team = Team.new
    assert_not team.valid?
    assert_includes team.errors[:name], "can't be blank"
    assert_includes team.errors[:code], "can't be blank"
    assert_includes team.errors[:project_id], "can't be blank"
  end

  test "default scope excludes is_deleted teams and orders by name ascending" do
    project = Project.create!(name: "Order Project", code: "ORDP1")
    Team.create!(name: "ZZZ Team", code: "ZZZT1", project_id: project.id)
    Team.create!(name: "AAA Team", code: "AAAT1", project_id: project.id)
    deleted = Team.create!(name: "Deleted Team", code: "DELT1", project_id: project.id, is_deleted: true)

    names = Team.where(project_id: project.id).collect(&:name)
    assert_equal names.sort, names
    assert_not_includes Team.where(project_id: project.id).pluck(:id), deleted.id
  end

  test "active scope filters on status column, not is_deleted" do
    project = Project.create!(name: "Status Project", code: "STAP1")
    active_team = Team.create!(name: "Active Team", code: "ACTT1", project_id: project.id, status: "active")
    archived_team = Team.create!(name: "Archived Team", code: "ARCT1", project_id: project.id, status: "archived")

    active_ids = Team.where(project_id: project.id).active.pluck(:id)
    assert_includes active_ids, active_team.id
    assert_not_includes active_ids, archived_team.id
  end

  test "belongs_to project and has_many team_members, tasks, users, okrs, key_results" do
    team = teams(:one)
    assert_respond_to team, :project
    assert_respond_to team, :team_members
    assert_respond_to team, :tasks
    assert_respond_to team, :users
    assert_respond_to team, :okrs
    assert_respond_to team, :key_results
    assert_respond_to team, :leads
    assert_respond_to team, :team_leads
    assert_respond_to team, :members
  end

  test "leads association only includes team_members with role lead" do
    project = Project.create!(name: "Leads Project", code: "LEADP1")
    team = Team.create!(name: "Leads Team", code: "LEADT1", project_id: project.id)
    lead_user = User.create!(email: "lead_user@example.com", password: "password123",
                              name: "Lead User", nickname: "leaduser",
                              employee_code: "LU001", role: "employee")
    member_user = User.create!(email: "member_user@example.com", password: "password123",
                                name: "Member User", nickname: "memberuser",
                                employee_code: "MU001", role: "employee")
    TeamMember.create!(team_id: team.id, user_id: lead_user.id, role: "lead")
    TeamMember.create!(team_id: team.id, user_id: member_user.id, role: "member")

    lead_ids = team.reload.team_leads.collect(&:id)
    assert_includes lead_ids, lead_user.id
    assert_not_includes lead_ids, member_user.id
  end

  test "update_project_team_count sets project's team_count from active teams" do
    project = Project.create!(name: "Count Project", code: "COUNTP1")
    Team.create!(name: "Active Team", code: "ACTT2", project_id: project.id, status: "active")
    archived = Team.create!(name: "Archived Team", code: "ARCT2", project_id: project.id, status: "archived")

    assert_equal 1, project.reload.team_count
    archived.update_attributes(status: "active")
    assert_equal 2, project.reload.team_count
  end

  test "for_user returns teams under the user's projects or team ids" do
    project = Project.create!(name: "ForUser Project", code: "FUP1")
    team = Team.create!(name: "ForUser Team", code: "FUT1", project_id: project.id)
    user = User.create!(email: "for_user@example.com", password: "password123",
                         name: "For User", nickname: "foruser",
                         employee_code: "FU001", role: "employee")
    ProjectManager.create!(project_id: project.id, user_id: user.id)

    team_ids = Team.for_user(user).pluck(:id)
    assert_includes team_ids, team.id
  end

  test "admind_by_user returns teams under the user's admin (led) teams" do
    project = Project.create!(name: "AdmindProject", code: "ADMP1")
    team = Team.create!(name: "AdmindTeam", code: "ADMT1", project_id: project.id)
    user = User.create!(email: "admind_user@example.com", password: "password123",
                         name: "Admind User", nickname: "admind_user",
                         employee_code: "AU001", role: "employee")
    TeamMember.create!(team_id: team.id, user_id: user.id, role: "lead")

    team_ids = Team.admind_by_user(user).pluck(:id)
    assert_includes team_ids, team.id
  end

  test "assignable_by_user returns teams within the user's own or admin-teams' projects" do
    project = Project.create!(name: "AssignProject", code: "ASSP1")
    team = Team.create!(name: "AssignTeam", code: "ASST1", project_id: project.id)
    user = User.create!(email: "assign_user@example.com", password: "password123",
                         name: "Assign User", nickname: "assignuser",
                         employee_code: "AS001", role: "employee")
    ProjectManager.create!(project_id: project.id, user_id: user.id)

    team_ids = Team.assignable_by_user(user).pluck(:id)
    assert_includes team_ids, team.id
  end
end
