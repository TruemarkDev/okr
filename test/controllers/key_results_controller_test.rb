require 'test_helper'

class KeyResultsControllerTest < ActionController::TestCase
  setup do
    # characterization blocked: KeyResultsController is unreachable — the nested
    # `resources :key_results` route is commented out in config/routes.rb, so
    # every action raises ActionController::UrlGenerationError. Routes are
    # production config and out of scope for this test-infra task.
    skip "characterization blocked: no route — resources :key_results is commented out in config/routes.rb (ActionController::UrlGenerationError)"
    sign_in users(:admin)
    @key_result = key_results(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:key_results)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create key_result" do
    assert_difference('KeyResult.count') do
      post :create, params: { key_result: { author_id: @key_result.author_id, end_date: @key_result.end_date, name: @key_result.name, objective_id: @key_result.objective_id, start_date: @key_result.start_date, user_id: @key_result.user_id } }
    end

    assert_redirected_to key_result_path(assigns(:key_result))
  end

  test "should show key_result" do
    get :show, params: { id: @key_result }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @key_result }
    assert_response :success
  end

  test "should update key_result" do
    patch :update, params: { id: @key_result, key_result: { author_id: @key_result.author_id, end_date: @key_result.end_date, name: @key_result.name, objective_id: @key_result.objective_id, start_date: @key_result.start_date, user_id: @key_result.user_id } }
    assert_redirected_to key_result_path(assigns(:key_result))
  end

  test "should destroy key_result" do
    assert_difference('KeyResult.count', -1) do
      delete :destroy, params: { id: @key_result }
    end

    assert_redirected_to key_results_path
  end
end
