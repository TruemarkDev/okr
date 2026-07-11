require 'test_helper'

# Characterization tests for TaskKeyResult — pin current behavior, do not fix or judge it.
# It is the join model backing Task <-> KeyResult (and the derived Task#users).
class TaskKeyResultTest < ActiveSupport::TestCase

  test "belongs to task and key_result" do
    tkr = task_key_results(:one)
    assert_equal tasks(:one), tkr.task
    assert_equal key_results(:one), tkr.key_result
  end

  test "acts as the join backing Task#key_results" do
    assert_includes tasks(:one).key_results, key_results(:one)
  end

  test "can be created linking a task to a key_result" do
    tkr = TaskKeyResult.create!(task_id: 1, key_result_id: 1)
    assert_equal tasks(:one), tkr.task
    assert_equal key_results(:one), tkr.key_result
  end
end
