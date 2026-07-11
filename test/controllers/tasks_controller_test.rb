require 'test_helper'

class TasksControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
    @task = tasks(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tasks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create task" do
    assert_difference('Task.count') do
      post :create, task: { comments_count: @task.comments_count, description: @task.description, end_date: @task.end_date, name: @task.name, project_id: @task.project_id, start_date: @task.start_date, team_id: @task.team_id, tracker_id: @task.tracker_id, user_id: @task.user_id }
    end

    assert_redirected_to task_path(assigns(:task))
  end

  test "should show task" do
    get :show, id: @task
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @task
    assert_response :success
  end

  test "should update task" do
    patch :update, id: @task, task: { comments_count: @task.comments_count, description: @task.description, end_date: @task.end_date, name: @task.name, project_id: @task.project_id, start_date: @task.start_date, team_id: @task.team_id, tracker_id: @task.tracker_id, user_id: @task.user_id }
    assert_redirected_to task_path(assigns(:task))
  end

  test "should destroy task" do
    assert_difference('Task.count', -1) do
      delete :destroy, id: @task
    end

    assert_redirected_to tasks_path
  end

  # --- deepened characterization --------------------------------------------

  test "destroy is a soft delete, not a hard delete" do
    # Task.count drops (default_scope hides is_deleted) but no row is removed.
    assert_no_difference('Task.unscoped.count') do
      assert_difference('Task.count', -1) do
        delete :destroy, id: @task
      end
    end
  end

  test "index assigns pending and completed watching tasks" do
    get :index
    assert_not_nil assigns(:tasks)
    assert_not_nil assigns(:fin_tasks)
  end

  test "completed_index assigns finished tasks but has no template" do
    # The action runs and assigns, but there is no completed_index view, so
    # rendering raises MissingTemplate — pin that current behavior.
    assert_raises(ActionView::MissingTemplate) { get :completed_index }
  end

  test "show assigns team, project, sub_tasks and a new comment" do
    get :show, id: @task
    assert_response :success
    assert_equal @task.team, assigns(:team)
    assert_equal @task.team.project, assigns(:project)
    assert_not_nil assigns(:sub_tasks)
    assert assigns(:comment).new_record?
  end

  test "new prefilled with team when team_id given" do
    get :new, team_id: teams(:one).id
    assert_response :success
    assert_equal teams(:one).id, assigns(:task).team_id
    assert_equal teams(:one).project_id, assigns(:task).project_id
  end

  test "create derives project_id from the chosen team" do
    post :create, task: { name: 'X', description: 'd', start_date: Time.now,
                          end_date: Time.now, team_id: teams(:one).id, user_id: 1 }
    assert_equal teams(:one).project_id, assigns(:task).project_id
  end

  test "completion action marks the task completed (but has no template)" do
    # completion uses Task.find (not friendly.find), so it needs a numeric id.
    # The DB update runs before the implicit render, which raises MissingTemplate.
    assert_raises(ActionView::MissingTemplate) do
      post :completion, id: @task.id, task: { completed_on: Time.now.to_s }
    end
    @task.reload
    assert_equal 'completed', @task.status
    assert_not_nil @task.completed_on
  end
end
