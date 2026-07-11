require 'test_helper'

class TeamMemberTest < ActiveSupport::TestCase
  test "belongs_to team and user" do
    team_member = team_members(:one)
    assert_respond_to team_member, :team
    assert_respond_to team_member, :user
  end

  test "default scope excludes archived team_members" do
    project = Project.create!(name: "TM Scope Project", code: "TMSP1")
    team = Team.create!(name: "TM Scope Team", code: "TMST1", project_id: project.id)
    user = User.create!(email: "tm_scope_user@example.com", password: "password123",
                         name: "TM Scope User", nickname: "tmscopeuser",
                         employee_code: "TMS001", role: "employee")
    archived = TeamMember.create!(team_id: team.id, user_id: user.id, role: "member", status: "archived")

    assert_not_includes TeamMember.pluck(:id), archived.id
    assert_includes TeamMember.unscoped.pluck(:id), archived.id
  end

  test "update_member_counts sets team member/manager counts and project member_count for a lead" do
    project = Project.create!(name: "Counts Project", code: "CNTSP1")
    team = Team.create!(name: "Counts Team", code: "CNTST1", project_id: project.id)
    user = User.create!(email: "counts_user@example.com", password: "password123",
                         name: "Counts User", nickname: "countsuser",
                         employee_code: "CNT001", role: "employee")

    TeamMember.create!(team_id: team.id, user_id: user.id, role: "lead")

    assert_equal 1, team.reload.members_count
    assert_equal 1, team.reload.managers_count
    assert_equal 1, project.reload.member_count
  end

  test "update_member_counts does not bump managers_count for a non-lead role" do
    project = Project.create!(name: "Counts Project2", code: "CNTSP2")
    team = Team.create!(name: "Counts Team2", code: "CNTST2", project_id: project.id)
    user = User.create!(email: "counts_user2@example.com", password: "password123",
                         name: "Counts User2", nickname: "countsuser2",
                         employee_code: "CNT002", role: "employee")

    TeamMember.create!(team_id: team.id, user_id: user.id, role: "member")

    assert_equal 1, team.reload.members_count
    assert_equal 0, team.reload.managers_count
    assert_equal 1, project.reload.member_count
  end
end
