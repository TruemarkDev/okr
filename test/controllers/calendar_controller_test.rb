require 'test_helper'

# Characterization tests for CalendarController. Pin current behavior with the
# existing fixture graph; not a judgment on correctness.
class CalendarControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  # ---- day -------------------------------------------------------------------

  test "day defaults to today" do
    get :day
    assert_response :success
    assert_equal Date.today, assigns(:date)
    assert_not_nil assigns(:entries)
    assert_not_nil assigns(:work_logs)
  end

  test "day honours an explicit date param" do
    get :day, date: '2000-01-15'
    assert_response :success
    assert_equal Date.parse('2000-01-15'), assigns(:date)
  end

  # ---- week (js-only template) ----------------------------------------------

  test "week defaults to a trailing 7-day window" do
    xhr :get, :week
    assert_response :success
    assert_equal Date.today - 6.days, assigns(:start_date)
    assert_equal assigns(:start_date) + 6.days, assigns(:end_date)
    # one bucket per day in the window
    assert_equal 7, assigns(:entry_hash).size
  end

  test "week honours an explicit start date" do
    xhr :get, :week, date: '2000-01-01'
    assert_response :success
    assert_equal Date.parse('2000-01-01'), assigns(:start_date)
    assert_equal Date.parse('2000-01-07'), assigns(:end_date)
  end

  # ---- monthly ---------------------------------------------------------------

  test "should get monthly" do
    get :monthly
    assert_response :success
    assert_equal Date.today.beginning_of_month, assigns(:start_date)
    assert_equal Date.today.end_of_month, assigns(:end_date)
    assert_not_nil assigns(:prev_month)
    assert_not_nil assigns(:next_month)
  end

  test "monthly honours an explicit date param" do
    get :monthly, date: '2000-06-15'
    assert_response :success
    assert_equal Date.parse('2000-06-01'), assigns(:start_date)
    assert_equal Date.parse('2000-06-30'), assigns(:end_date)
  end
end
