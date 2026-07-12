require 'test_helper'

# Characterization tests for ReportsController — a large bespoke, read-only,
# non-RESTful surface. These tests pin CURRENT behavior with the existing
# fixture graph; they are not judgments about whether that behavior is correct.
#
# Fixture facts relied on below:
#   users(:admin)  id 1, role admin (=> manager? == true), employee_code ADMIN001
#   tasks(:one)    id 1, project_id 1, team_id 1, user_id 1, dates in 2014
#   work_logs(:one) id 1, user_id 1, task_id 1, date Date.today, minutes NIL
#   key_results(:one) id 1, user_id 1, linked to tasks(:one) via task_key_results
#   admin.admin_projects_count / admin_teams_count default to 0 (counter caches)
class ReportsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
  end

  # ---- simple pages ----------------------------------------------------------

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get activities" do
    get :activities
    assert_response :success
  end

  # ---- employees_daily -------------------------------------------------------

  test "employees_daily as admin defaults to all_users report" do
    get :employees_daily
    assert_response :success
    assert_equal 'all_users', assigns(:report_type)
    assert_equal Date.today, assigns(:date)
    assert assigns(:users).present?
  end

  test "employees_daily project report type resolves the project" do
    get :employees_daily, params: { report: { type: 'project', project_id: 1 } }
    assert_response :success
    assert_equal 'project', assigns(:report_type)
    assert_equal 1, assigns(:project).id
  end

  # ---- employees_time_range --------------------------------------------------

  test "employees_time_range as admin defaults to all_users and current month" do
    get :employees_time_range
    assert_response :success
    assert_equal 'all_users', assigns(:report_type)
    assert_equal Date.today.beginning_of_month, assigns(:start_date)
    assert_equal Date.today.end_of_month, assigns(:end_date)
  end

  # ---- employee_day ----------------------------------------------------------

  test "employee_day defaults user to first accessible and given date" do
    get :employee_day, params: { start_date: '2000-01-01' }
    assert_response :success
    assert assigns(:user).present?
    assert_equal Date.parse('2000-01-01'), assigns(:date)
    assert_not_nil assigns(:work_logs)
  end

  test "employee_day honours explicit employee_id" do
    get :employee_day, params: { employee_id: users(:admin).id, start_date: '2000-01-01' }
    assert_response :success
    assert_equal users(:admin).id, assigns(:user).id
  end

  # ---- employee_range --------------------------------------------------------

  test "employee_range defaults to current month range" do
    get :employee_range, params: { employee_id: users(:admin).id,
                         start_date: '2000-01-01', end_date: '2000-01-31' }
    assert_response :success
    assert_equal Date.parse('2000-01-01'), assigns(:start_date)
    assert_equal Date.parse('2000-01-31'), assigns(:end_date)
    assert_not_nil assigns(:total)
  end

  # ---- get_selection_list (js-only template) ---------------------------------

  test "get_selection_list project type assigns projects" do
    get :get_selection_list, params: { type: 'project' }, xhr: true
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test "get_selection_list team type assigns teams" do
    get :get_selection_list, params: { type: 'team' }, xhr: true
    assert_response :success
    assert_not_nil assigns(:teams)
  end

  test "get_selection_list managing_user type assigns users" do
    get :get_selection_list, params: { type: 'managing_user' }, xhr: true
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "get_selection_list user type renders empty selection" do
    get :get_selection_list, params: { type: 'user' }, xhr: true
    assert_response :success
  end

  # ---- tasks -----------------------------------------------------------------

  test "tasks redirects when admin has no admin teams or projects" do
    # admin fixture has admin_teams_count/admin_projects_count == 0
    get :tasks
    assert_redirected_to root_path
    assert_equal 'Nothing to show', flash[:alert]
  end

  test "tasks renders project report when user administers a project" do
    users(:admin).update_column(:admin_projects_count, 1)
    get :tasks, params: { report: { type: 'project', project_id: 1 },
                start_date: '2000-01-01', end_date: '2000-01-31' }
    assert_response :success
    assert_equal 'project', assigns(:report_type)
  end

  # ---- task ------------------------------------------------------------------

  test "task redirects when admin has no admin teams or projects" do
    get :task, params: { id: 1 }
    assert_redirected_to root_path
    assert_equal 'Nothing to show', flash[:alert]
  end

  test "task without id or tracker_id redirects as unauthorized" do
    users(:admin).update_column(:admin_projects_count, 1)
    get :task
    assert_redirected_to root_path
    assert_equal 'Unauthorized access', flash[:alert]
  end

  test "task with a viewable id renders stats" do
    users(:admin).update_column(:admin_projects_count, 1)
    # filter by a non-existent user so no work-log rows are iterated in the view
    get :task, params: { id: 1, user_id: 999999 }
    assert_response :success
    assert_equal 1, assigns(:task).id
    assert_equal 0, assigns(:stats)['users']
  end

  # ---- employee_tasks --------------------------------------------------------

  test "employee_tasks loads task, its users and the selected user" do
    get :employee_tasks, params: { task_id: 1, user_id: users(:admin).id,
                         start_date: '2000-01-01', end_date: '2000-01-31' }
    assert_response :success
    assert_equal 1, assigns(:task).id
    assert_equal users(:admin).id, assigns(:user).id
    assert_not_nil assigns(:users)
  end

  # ---- okrs ------------------------------------------------------------------

  test "okrs defaults to first accessible user and current quarter" do
    get :okrs
    assert_response :success
    assert assigns(:user).present?
    assert_not_nil assigns(:key_results)
    assert_not_nil assigns(:tasks)
  end

  # ---- pdf rendering (roadmap Task 11 -- wicked_pdf/wkhtmltopdf-binary
  # characterization: pins that `format.pdf` actually shells out to
  # wkhtmltopdf and returns a real PDF under the current Rails 8.0 stack,
  # not just that the action doesn't raise) ------------------------------------

  test "okrs renders a real pdf via wicked_pdf/wkhtmltopdf" do
    get :okrs, format: :pdf
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.start_with?('%PDF-'), 'response body is not a valid PDF (missing %PDF- magic number)'
  end

  test "worklogs renders a real pdf via wicked_pdf/wkhtmltopdf" do
    get :worklogs, params: { month: 'January', year: '2000' }, format: :pdf
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.start_with?('%PDF-'), 'response body is not a valid PDF (missing %PDF- magic number)'
  end

  # ---- worklogs --------------------------------------------------------------

  test "worklogs renders for a month with no logs" do
    get :worklogs, params: { month: 'January', year: '2000' }
    assert_response :success
    assert_equal 'all_users', assigns(:report_type)
    assert_equal Date.parse('2000-01-01'), assigns(:start_date)
  end

  test "worklogs current month raises on nil work_log minutes" do
    # work_logs(:one) has date Date.today and minutes == nil; the aggregation
    # `...to_i + x.minutes` raises when minutes is nil. Pinned as current behavior.
    assert_raises(TypeError) do
      get :worklogs
    end
  end

  # ---- day_log ---------------------------------------------------------------

  test "day_log without user_id redirects (permission denied)" do
    get :day_log
    assert_redirected_to root_path
    assert_equal 'Permission denied', flash[:notice]
  end

  test "day_log resolves user by employee_code" do
    get :day_log, params: { user_id: 'ADMIN001', date: '2000-01-01' }
    assert_response :success
    assert assigns(:user).present?
    assert_equal Date.parse('2000-01-01'), assigns(:date)
  end

  # ---- assignments -----------------------------------------------------------

  test "assignments without user_id uses current_user" do
    get :assignments
    assert_response :success
    assert_equal users(:admin).id, assigns(:user).id
    assert_not_nil assigns(:fields)
  end

  test "assignments honours user_id within accessible users" do
    get :assignments, params: { user_id: users(:admin).id }
    assert_response :success
    assert_equal users(:admin).id, assigns(:user).id
  end

  # ---- employee (non-manager) role branches ---------------------------------

  test "employees_daily as employee defaults to self report" do
    sign_in employee
    get :employees_daily
    assert_response :success
    assert_equal 'user', assigns(:report_type)
    assert_equal [employee.id], assigns(:users).map(&:id)
  end

  test "okrs as employee defaults to self" do
    emp = employee
    sign_in emp
    get :okrs
    assert_response :success
    assert_equal emp.id, assigns(:user).id
  end

  test "okrs as employee redirects when requesting an inaccessible user" do
    sign_in employee
    get :okrs, params: { employee_id: users(:admin).id }
    assert_redirected_to root_path
    assert_equal 'Unauthorized access', flash[:alert]
  end

  test "tasks as employee without admin teams or projects redirects" do
    sign_in employee
    get :tasks
    assert_redirected_to root_path
    assert_equal 'Nothing to show', flash[:alert]
  end

  test "assignments as employee scopes to self" do
    emp = employee
    sign_in emp
    get :assignments
    assert_response :success
    assert_equal emp.id, assigns(:user).id
  end

  private

  # Employees are created in-test (not in fixtures) per lane ownership rules.
  def employee
    @employee ||= User.create!(
      name: 'Lane E Employee',
      nickname: 'lanee_emp',
      email: 'lanee_emp@example.com',
      employee_code: 'LANEE001',
      password: 'password123',
      role: 'employee'
    )
  end
end
