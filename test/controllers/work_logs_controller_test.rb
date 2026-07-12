require 'test_helper'

class WorkLogsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
    @work_log = work_logs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:work_logs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create work_log" do
    # WorkLog validates presence of task_id and that date is within the last 6
    # days, so supply both for the create-success path.
    assert_difference('WorkLog.count') do
      post :create, params: { work_log: { end_time: @work_log.end_time, is_deleted: @work_log.is_deleted, name: @work_log.name, start_time: @work_log.start_time, task_id: @work_log.task_id, date: Date.today, user_id: @work_log.user_id } }
    end

    assert_redirected_to work_log_path(assigns(:work_log))
  end

  test "should show work_log" do
    get :show, params: { id: @work_log }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @work_log }
    assert_response :success
  end

  test "should update work_log" do
    patch :update, params: { id: @work_log, work_log: { end_time: @work_log.end_time, is_deleted: @work_log.is_deleted, name: @work_log.name, start_time: @work_log.start_time, task: @work_log.task, user_id: @work_log.user_id } }
    assert_redirected_to work_log_path(assigns(:work_log))
  end

  test "should destroy work_log" do
    assert_difference('WorkLog.count', -1) do
      delete :destroy, params: { id: @work_log }
    end

    # Signed-in admin is a manager, so destroy redirects to the worklogs report.
    assert_redirected_to reports_worklogs_path
  end

  # --- deepened characterization --------------------------------------------

  test "index assigns only active work logs" do
    get :index
    assert_response :success
    assert_equal WorkLog.active.to_a.sort_by(&:id), assigns(:work_logs).to_a.sort_by(&:id)
  end

  test "create sets user to current_user and derives minutes from hours and mins" do
    post :create, params: { work_log: { name: 'x', task_id: 1, date: Date.today,
                              hours: '1', mins: '30' } }
    assert_equal users(:admin).id, assigns(:work_log).user_id
    assert_equal 90, assigns(:work_log).minutes
  end

  test "owner destroy of a recent log takes the owner branch (no manager flash)" do
    # admin owns work_log one and it is dated today, so the owner+recent branch
    # wins over the manager branch: it destroys silently, without the flash.
    delete :destroy, params: { id: @work_log }
    assert_nil flash[:notice]
    assert_nil WorkLog.find_by_id(@work_log.id)
  end

  test "delete_request flags the log when requested by its owner" do
    post :delete_request, params: { id: @work_log }
    assert @work_log.reload.delete_request
    assert_redirected_to reports_worklogs_path
  end

  test "ignore_request clears the delete_request flag for a manager" do
    @work_log.update_attribute(:delete_request, true)
    post :ignore_request, params: { id: @work_log }
    assert_not @work_log.reload.delete_request
    assert_redirected_to reports_worklogs_path
  end
end
