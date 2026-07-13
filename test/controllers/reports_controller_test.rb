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

  test "worklogs current month handles nil work_log minutes" do
    # work_logs(:one) has date Date.today and minutes == nil; the aggregation
    # coerces via `x.minutes.to_i` so a nil contributes 0 instead of raising.
    get :worklogs
    assert_response :success
    hours = assigns(:hours)[work_logs(:one).user_id][work_logs(:one).date.day]['hours']
    assert_equal 0, hours
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

  test "assignments handles a nil-minutes worklog on an in-range task" do
    # work_logs(:one) has minutes == nil; scoping the date range to cover
    # tasks(:one)'s 2014 dates pulls it into the per-task time-spent sum,
    # which coerces via `l.minutes.to_i` so a nil contributes 0 instead of
    # raising TypeError: nil can't be coerced into Integer.
    get :assignments, params: { start_date: '2014-01-01', end_date: '2014-12-31' }
    assert_response :success
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

  # ==========================================================================
  # Broad hardening pass (discretionary): report_type branches, the worklogs
  # `detailed` branch, employee-role @opts branches, and CSV/XLS export formats
  # across every action. Pins CURRENT behavior only.
  # ==========================================================================

  # ---- employees_daily: remaining report_type branches -----------------------

  test "employees_daily team report type resolves the team" do
    get :employees_daily, params: { report: { type: 'team', team_id: 1 } }
    assert_response :success
    assert_equal 'team', assigns(:report_type)
    assert_equal 1, assigns(:team).id
  end

  test "employees_daily managing_users report type scopes to managed users" do
    get :employees_daily, params: { report: { type: 'managing_users' } }
    assert_response :success
    assert_equal 'managing_users', assigns(:report_type)
    assert_not_nil assigns(:users)
  end

  test "employees_daily employees report type scopes to the given user_id" do
    get :employees_daily, params: { report: { type: 'employees', user_id: users(:admin).id } }
    assert_response :success
    assert_equal 'employees', assigns(:report_type)
    assert_equal [users(:admin).id], assigns(:users).map(&:id)
  end

  # ---- employees_time_range: remaining report_type branches ------------------

  test "employees_time_range project report type resolves the project" do
    get :employees_time_range, params: { report: { type: 'project', project_id: 1 } }
    assert_response :success
    assert_equal 'project', assigns(:report_type)
    assert_equal 1, assigns(:project).id
  end

  test "employees_time_range team report type resolves the team" do
    get :employees_time_range, params: { report: { type: 'team', team_id: 1 } }
    assert_response :success
    assert_equal 1, assigns(:team).id
  end

  test "employees_time_range managing_users report type scopes to managed users" do
    get :employees_time_range, params: { report: { type: 'managing_users' } }
    assert_response :success
    assert_equal 'managing_users', assigns(:report_type)
  end

  test "employees_time_range employees report type scopes to the given user_id" do
    get :employees_time_range, params: { report: { type: 'employees', user_id: users(:admin).id } }
    assert_response :success
    assert_equal [users(:admin).id], assigns(:users).map(&:id)
  end

  test "employees_time_range honours explicit start and end dates" do
    get :employees_time_range, params: { report: { type: 'all_users',
                               start_date: '2000-01-05', end_date: '2000-01-20' } }
    assert_response :success
    assert_equal Date.parse('2000-01-05'), assigns(:start_date)
    assert_equal Date.parse('2000-01-20'), assigns(:end_date)
  end

  # ---- employees_time_range / worklogs: employee (non-manager) @opts ---------

  test "employees_time_range as employee with admin project and team builds opts" do
    emp = employee
    emp.update_columns(admin_projects_count: 1, admin_teams_count: 1)
    sign_in emp
    get :employees_time_range
    assert_response :success
    assert_equal 'user', assigns(:report_type)
    assert_includes assigns(:opts).map(&:last), 'project'
    assert_includes assigns(:opts).map(&:last), 'team'
  end

  test "worklogs as employee defaults to accessible report type" do
    sign_in employee
    get :worklogs
    assert_response :success
    assert_equal 'accessible', assigns(:report_type)
  end

  # ---- worklogs: remaining report_type branches ------------------------------

  test "worklogs project report type resolves the project" do
    get :worklogs, params: { report: { type: 'project', project_id: 1 } }
    assert_response :success
    assert_equal 1, assigns(:project).id
  end

  test "worklogs team report type resolves the team" do
    get :worklogs, params: { report: { type: 'team', team_id: 1 } }
    assert_response :success
    assert_equal 1, assigns(:team).id
  end

  test "worklogs managing_users report type scopes to managed users" do
    get :worklogs, params: { report: { type: 'managing_users' } }
    assert_response :success
    assert_equal 'managing_users', assigns(:report_type)
  end

  test "worklogs accessible report type scopes to accessible users" do
    get :worklogs, params: { report: { type: 'accessible' } }
    assert_response :success
    assert_equal 'accessible', assigns(:report_type)
    assert_not_nil assigns(:users)
  end

  test "worklogs employees report type scopes to the given user_id" do
    get :worklogs, params: { report: { type: 'employees', user_id: users(:admin).id } }
    assert_response :success
    assert_equal [users(:admin).id], assigns(:users).map(&:id)
  end

  # ---- worklogs: detailed branch (per-user/per-day grouping) ------------------

  test "worklogs detailed builds per-user per-day log rows" do
    # work_logs(:one): user 1, date today, minutes nil -> to_i 0. The detailed
    # branch groups by user_id then day-of-month and records max rows/day.
    get :worklogs, params: { detailed: true }
    assert_response :success
    assert_not_nil assigns(:user_logs)
    assert_not_nil assigns(:user_rows)
    # the log's user/day should have one entry in @user_rows
    assert_equal 1, assigns(:user_rows)[work_logs(:one).user_id]
  end

  # ---- tasks: remaining report_type branches ---------------------------------

  test "tasks team report type resolves the team" do
    users(:admin).update_column(:admin_teams_count, 1)
    get :tasks, params: { report: { type: 'team', team_id: 1 },
                start_date: '2000-01-01', end_date: '2000-01-31' }
    assert_response :success
    assert_equal 'team', assigns(:report_type)
    assert_equal 1, assigns(:team).id
  end

  test "tasks users report type resolves the user assignments" do
    users(:admin).update_column(:admin_projects_count, 1)
    get :tasks, params: { report: { type: 'users', user_id: users(:admin).id },
                start_date: '2000-01-01', end_date: '2000-01-31' }
    assert_response :success
    assert_equal 'users', assigns(:report_type)
    assert_equal users(:admin).id, assigns(:user).id
  end

  test "tasks project report populates assignees and work_logs when tasks present" do
    users(:admin).update_column(:admin_projects_count, 1)
    # tasks(:one) spans 2014; widen the range so it is included and @tasks present
    get :tasks, params: { report: { type: 'project', project_id: 1 },
                start_date: '2014-01-01', end_date: '2014-12-31' }
    assert_response :success
    assert assigns(:tasks).present?
    assert assigns(:assignees).key?(tasks(:one).id)
  end

  # ---- task: tracker_id branch and no-user_id logs branch --------------------

  test "task resolves by tracker_id" do
    users(:admin).update_column(:admin_projects_count, 1)
    # Both task fixtures share tracker_id 'MyString'; Task's default_scope orders
    # id desc, so find_by_tracker_id returns whichever has the higher id. Pin the
    # resolved-by-tracker-id behavior via the tracker_id, not a specific fixture id.
    get :task, params: { tracker_id: tasks(:one).tracker_id }
    assert_response :success
    assert_not_nil assigns(:task)
    assert_equal 'MyString', assigns(:task).tracker_id
  end

  test "task without user_id loads all logs for the task" do
    users(:admin).update_column(:admin_projects_count, 1)
    get :task, params: { id: 1 }
    assert_response :success
    assert_not_nil assigns(:logs)
    assert_not_nil assigns(:stats)
  end

  # ---- get_selection_list: users type ----------------------------------------

  test "get_selection_list users type assigns the aggregated user list" do
    get :get_selection_list, params: { type: 'users' }, xhr: true
    assert_response :success
    assert_not_nil assigns(:users)
  end

  # ---- assignments: permission-denied branch ---------------------------------

  test "assignments as employee requesting an inaccessible user is denied" do
    sign_in employee
    get :assignments, params: { user_id: users(:admin).id }
    assert_redirected_to root_path
    assert_equal 'Permission denied', flash[:notice]
  end

  # ---- remaining employee-role logic branches --------------------------------

  test "employee_day as employee scopes users to self plus managed" do
    emp = employee
    sign_in emp
    get :employee_day
    assert_response :success
    assert_includes assigns(:users).map(&:id), emp.id
  end

  test "employee_range as employee scopes users to self plus managed" do
    emp = employee
    sign_in emp
    get :employee_range
    assert_response :success
    assert_includes assigns(:users).map(&:id), emp.id
  end

  test "tasks as employee with admin team builds team and users opts" do
    emp = employee
    emp.update_columns(admin_teams_count: 1, admin_projects_count: 1)
    sign_in emp
    # Use the team branch (Team.find is global); an employee does not own project 1.
    get :tasks, params: { report: { type: 'team', team_id: 1 },
                start_date: '2000-01-01', end_date: '2000-01-31' }
    assert_response :success
    opt_values = assigns(:opts).map(&:last)
    assert_includes opt_values, 'team'
    assert_includes opt_values, 'users'
  end

  test "worklogs falls back to self when report type is unrecognised" do
    # An unknown report_type (here 'user') falls through to the else branch
    # scoping @users to just the current user.
    get :worklogs, params: { report: { type: 'user' } }
    assert_response :success
    assert_equal [users(:admin).id], assigns(:users).map(&:id)
  end

  # ---- CSV / XLS export formats ----------------------------------------------
  # Exercises the CSV/XLS export paths of each action. These used to 500
  # (ActionView::MissingTemplate) because the actions called `render
  # "reports/csv_report.csv.erb"` / `"reports/excel_report.xls.erb"` /
  # `"reports/worklog_detailed.xls.erb"` — a filename with the format embedded,
  # which doesn't resolve under Rails 8's template lookup. Fixed by rendering
  # `render template: "reports/csv_report", formats: :csv` (etc.) instead.

  def assert_export_success(action, params: {}, format: :csv)
    get action, params: params, format: format
    assert_response :success
  end

  test "employees_daily csv/xls export succeeds" do
    assert_export_success(:employees_daily, format: :csv)
    assert_export_success(:employees_daily, format: :xls)
  end

  test "employees_time_range csv export succeeds" do
    assert_export_success(:employees_time_range, format: :csv)
  end

  test "employee_day csv export succeeds" do
    assert_export_success(:employee_day, params: { employee_id: users(:admin).id })
  end

  test "employee_range csv export succeeds" do
    assert_export_success(:employee_range, params: { employee_id: users(:admin).id,
                      start_date: '2014-01-01', end_date: '2014-12-31' })
  end

  test "tasks csv export succeeds" do
    users(:admin).update_column(:admin_projects_count, 1)
    assert_export_success(:tasks, params: { report: { type: 'project', project_id: 1 },
                      start_date: '2014-01-01', end_date: '2014-12-31' })
  end

  test "employee_tasks csv export succeeds" do
    assert_export_success(:employee_tasks, params: { task_id: 1, user_id: users(:admin).id,
                      start_date: '2014-01-01', end_date: '2014-12-31' })
  end

  test "task csv export succeeds" do
    users(:admin).update_column(:admin_projects_count, 1)
    assert_export_success(:task, params: { id: 1 })
  end

  test "okrs csv export succeeds" do
    assert_export_success(:okrs)
  end

  test "worklogs csv/xls export succeeds" do
    assert_export_success(:worklogs, format: :csv)
    assert_export_success(:worklogs, format: :xls)
  end

  test "worklogs detailed xls export succeeds" do
    assert_export_success(:worklogs, params: { detailed: true }, format: :xls)
  end

  test "day_log csv export succeeds" do
    assert_export_success(:day_log, params: { user_id: 'ADMIN001', date: '2014-01-01' })
  end

  test "assignments csv export succeeds" do
    # Default (current-quarter) range excludes the 2014 fixture task, so @fields is
    # empty and the export still renders successfully.
    assert_export_success(:assignments)
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
