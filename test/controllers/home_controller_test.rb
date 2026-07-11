require 'test_helper'

# Characterization tests for HomeController. Pin current behavior with the
# existing fixture graph; not a judgment on correctness.
#
# NOTE: HomeController#dashboard contains a typo (`parama[:date]`) that is only
# reached when params[:date] is present. Without a date param it short-circuits
# to Date.today, so the happy path works; with a date param it raises NameError.
class HomeControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
  end

  # ---- index / dashboard -----------------------------------------------------

  test "should get index" do
    get :index
    assert_response :success
    # index renders the dashboard template and its assigns
    assert_equal Date.today, assigns(:date)
    assert_not_nil assigns(:entry_hash)
  end

  test "should get dashboard" do
    get :dashboard
    assert_response :success
    assert_equal Date.today - 6.days, assigns(:start_date)
    assert_equal assigns(:start_date) + 6.days, assigns(:end_date)
    assert_equal 7, assigns(:entry_hash).size
    assert_not_nil assigns(:entries)
    assert_not_nil assigns(:work_logs)
  end

  test "dashboard with a date param raises NameError (parama typo)" do
    assert_raises(NameError) do
      get :dashboard, date: '2000-01-01'
    end
  end

  test "index with a date param raises NameError (via dashboard)" do
    assert_raises(NameError) do
      get :index, date: '2000-01-01'
    end
  end

  # ---- search ----------------------------------------------------------------

  test "search redirects to the task when tracker_id matches" do
    # tasks(:one) has tracker_id 'MyString' and is authored by admin, so it is
    # searchable for the admin user.
    get :search, search: { keyword: 'MyString' }
    assert_redirected_to controller: 'tasks', action: 'show', id: 'MyString'
  end

  test "search renders results when nothing matches by tracker_id" do
    get :search, search: { keyword: 'no-such-tracker-zzz' }
    assert_response :success
    assert_not_nil assigns(:tasks)
  end

  test "search works over POST as well" do
    post :search, search: { keyword: 'no-such-tracker-zzz' }
    assert_response :success
    assert_not_nil assigns(:tasks)
  end
end
