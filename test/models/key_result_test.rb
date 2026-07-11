require 'test_helper'

# Characterization tests for KeyResult — pin CURRENT behavior.
# KeyResult belongs_to user/objective, joins Task through task_key_results,
# reaches work_logs through tasks, validates name, and has an :active scope.
class KeyResultTest < ActiveSupport::TestCase
  # --- validations ------------------------------------------------------

  test "valid with a name" do
    assert KeyResult.new(name: "KR").valid?
  end

  test "requires name" do
    kr = KeyResult.new(name: nil)
    refute kr.valid?
    assert_includes kr.errors[:name], "can't be blank"
  end

  test "objective_id and dates are NOT validated on KeyResult" do
    assert KeyResult.new(name: "bare").valid?
  end

  # --- associations -----------------------------------------------------

  test "belongs to objective" do
    assert_equal objectives(:one), key_results(:one).objective
  end

  test "belongs to user" do
    assert_equal users(:admin), key_results(:one).user
  end

  test "has_many task_key_results (fixtures link task 1 twice)" do
    assert_respond_to key_results(:one), :task_key_results
    assert_equal 2, key_results(:one).task_key_results.count
  end

  test "has_many tasks through task_key_results reaches fixture task" do
    assert_respond_to key_results(:one), :tasks
    assert_includes key_results(:one).tasks.map(&:id), tasks(:one).id
  end

  test "has_many work_logs through tasks reaches fixture work_log" do
    assert_respond_to key_results(:one), :work_logs
    assert_includes key_results(:one).work_logs.map(&:id), work_logs(:one).id
  end

  test "reaches a newly joined task through a task_key_result join" do
    kr = KeyResult.create!(name: "fresh", objective_id: objectives(:one).id)
    # Task has an after_save callback (update_team_task_count) that needs a team,
    # so give it the fixture team to exercise the real join path.
    task = Task.create!(name: "T", user_id: users(:admin).id, team_id: teams(:one).id)
    TaskKeyResult.create!(task_id: task.id, key_result_id: kr.id)
    assert_includes kr.reload.tasks, task
  end

  # --- scopes -----------------------------------------------------------

  test "active scope excludes soft-deleted key_results" do
    kept    = KeyResult.create!(name: "kept", objective_id: objectives(:one).id)
    deleted = KeyResult.create!(name: "gone", objective_id: objectives(:one).id, is_deleted: true)
    assert_includes KeyResult.active, kept
    refute_includes KeyResult.active, deleted
  end

  test "is_deleted defaults to false" do
    assert_equal false, KeyResult.create!(name: "kr").is_deleted
  end
end
