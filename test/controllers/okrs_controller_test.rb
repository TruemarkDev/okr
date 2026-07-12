require 'test_helper'

class OkrsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
    @okr = okrs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:okrs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create okr" do
    assert_difference('Okr.count') do
      post :create, params: { okr: { end_date: @okr.end_date, name: @okr.name, start_date: @okr.start_date, user_id: @okr.user_id } }
    end

    assert_redirected_to user_okr_path(assigns(:okr).user_id, assigns(:okr))
  end

  test "should show okr" do
    get :show, params: { id: @okr }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @okr }
    assert_response :success
  end

  test "should update okr" do
    patch :update, params: { id: @okr, okr: { end_date: @okr.end_date, name: @okr.name, start_date: @okr.start_date, user_id: @okr.user_id } }
    assert_redirected_to user_okr_path(assigns(:okr).user_id, assigns(:okr))
  end

  test "should destroy okr" do
    assert_difference('Okr.count', -1) do
      delete :destroy, params: { id: @okr }
    end

    assert_redirected_to okrs_path
  end

  # --- deeper characterization -----------------------------------------

  test "index assigns @okrs (active) and @okr to the first" do
    get :index
    assert_not_nil assigns(:okrs)
    assert_equal assigns(:okrs).first, assigns(:okr)
  end

  test "new builds an okr with one objective and two key_results" do
    get :new
    okr = assigns(:okr)
    assert_equal 1, okr.objectives.size
    assert_equal 2, okr.objectives.first.key_results.size
  end

  test "show assigns @user from the okr and the user's active okrs" do
    get :show, params: { id: @okr }
    assert_response :success
    assert_equal @okr.user, assigns(:user)
    assert_not_nil assigns(:okrs)
  end

  test "create with nested objectives cascades dates down to children" do
    assert_difference('Objective.count', 1) do
      post :create, params: { okr: {
        name: "Nested OKR",
        user_id: users(:admin).id,
        start_date: "2015-01-01",
        end_date: "2015-03-31",
        objectives_attributes: {
          "0" => {
            name: "Ship it",
            key_results_attributes: { "0" => { name: "KR one" } }
          }
        }
      } }
    end
    okr = assigns(:okr)
    assert_redirected_to user_okr_path(okr.user_id, okr)
    obj = okr.objectives.first
    assert_equal Date.new(2015, 1, 1), obj.start_date
    assert_equal Date.new(2015, 3, 31), obj.end_date
    assert_equal Date.new(2015, 1, 1), okr.key_results.first.start_date
  end

  test "create with missing name re-renders new" do
    assert_no_difference('Okr.count') do
      post :create, params: { okr: { name: "", user_id: users(:admin).id,
                           start_date: @okr.start_date, end_date: @okr.end_date } }
    end
    assert_template :new
  end

  test "update changing dates cascades to existing children" do
    okr = Okr.create!(name: "Editable", user_id: users(:admin).id,
                      start_date: Date.new(2014, 1, 1), end_date: Date.new(2014, 3, 31),
                      objectives_attributes: [{ name: "Obj" }])
    patch :update, params: { id: okr, okr: { start_date: "2016-07-01", end_date: "2016-09-30" } }
    assert_redirected_to user_okr_path(okr.user_id, okr)
    assert_equal Date.new(2016, 7, 1), okr.objectives.first.reload.start_date
  end

  test "destroy is a hard delete not a soft delete" do
    okr = Okr.create!(name: "Doomed", user_id: users(:admin).id,
                      start_date: Date.today, end_date: Date.today)
    delete :destroy, params: { id: okr }
    assert_nil Okr.where(id: okr.id).first
  end

  test "approve sets approved true for a manager via nested route" do
    okr = Okr.create!(name: "Pending", user_id: users(:admin).id,
                      start_date: Date.today, end_date: Date.today, approved: false)
    post :approve, params: { user_id: users(:admin).id, id: okr }, xhr: true
    assert okr.reload.approved
  end
end
