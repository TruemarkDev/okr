require 'test_helper'

class TeamsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
    @team = teams(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:teams)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create team" do
    assert_difference('Team.count') do
      post :create, params: { team: { code: @team.code, description: @team.description, is_deleted: @team.is_deleted, managers_count: @team.managers_count, members_count: @team.members_count, name: @team.name, pending_tasks: @team.pending_tasks, project_id: @team.project_id, status: @team.status } }
    end

    assert_redirected_to team_path(assigns(:team))
  end

  test "should show team" do
    get :show, params: { id: @team }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @team }
    assert_response :success
  end

  test "should update team" do
    patch :update, params: { id: @team, team: { code: @team.code, description: @team.description, is_deleted: @team.is_deleted, managers_count: @team.managers_count, members_count: @team.members_count, name: @team.name, pending_tasks: @team.pending_tasks, project_id: @team.project_id, status: @team.status } }
    assert_redirected_to team_path(assigns(:team))
  end

  test "should destroy team" do
    assert_difference('Team.count', -1) do
      delete :destroy, params: { id: @team }
    end

    assert_redirected_to teams_path
  end

  test "destroy soft-deletes tasks and archives team_members directly (no through-scope pitfall)" do
    project = Project.create!(name: "Destroy Team Project", code: "DTP1")
    team = Team.create!(name: "Destroy Team", code: "DT1", project_id: project.id)
    task = Task.create!(project_id: project.id, team_id: team.id, name: "Destroy Team Task")
    user = User.create!(email: "destroy_team_member@example.com", password: "password123",
                         name: "Destroy Team Member", nickname: "destroyteammember",
                         employee_code: "DTM001", role: "employee")
    team_member = TeamMember.create!(team_id: team.id, user_id: user.id, role: "member")

    delete :destroy, params: { id: team }

    assert_redirected_to teams_path
    assert Team.unscoped.find(team.id).is_deleted
    assert Task.unscoped.find(task.id).is_deleted
    # Unlike Project#destroy (which archives is_deleted teams first, breaking the
    # has_many :through join before archiving team_members), TeamsController#destroy
    # operates on @team.team_members directly, so the archive actually takes effect.
    assert_equal 'archived', TeamMember.unscoped.find(team_member.id).status
  end

  test "index with project_id param scopes teams to that project's active teams" do
    project = Project.create!(name: "Index Scope Project", code: "ISP1")
    active_team = Team.create!(name: "Active Team", code: "IATC1", project_id: project.id, status: "active")
    archived_team = Team.create!(name: "Archived Team", code: "IARC1", project_id: project.id, status: "archived")

    get :index, params: { project_id: project.id }

    assert_response :success
    team_ids = assigns(:teams).collect(&:id)
    assert_includes team_ids, active_team.id
    assert_not_includes team_ids, archived_team.id
  end

  test "show assigns team_leads and members" do
    get :show, params: { id: @team }
    assert_response :success
    assert_not_nil assigns(:team_leads)
    assert_not_nil assigns(:members)
  end

  test "add_members assigns team, users and current members" do
    get :add_members, params: { team_id: @team }
    assert_response :success
    assert_equal @team, assigns(:team)
    assert_not_nil assigns(:users)
    assert_not_nil assigns(:members)
  end

  test "create with invalid params (missing project_id) re-renders new without creating a record" do
    assert_no_difference('Team.count') do
      post :create, params: { team: { code: 'INVALIDNEW1', name: 'Invalid New Team' } }
    end
    assert_response :success
    assert_template :new
  end
end
