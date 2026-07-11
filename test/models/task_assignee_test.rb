require 'test_helper'

# Characterization tests for TaskAssignee — pin current behavior, do not fix or judge it.
# NOTE: the task_assignees has_many/through associations are commented out on both
# Task and User; this model is only exercised bare (associations + default_scope).
class TaskAssigneeTest < ActiveSupport::TestCase

  test "belongs to task and user" do
    ta = task_assignees(:one)
    assert_equal tasks(:one), ta.task
    assert_equal users(:admin), ta.user
  end

  test "default_scope hides rows with status archived" do
    archived = TaskAssignee.create!(task_id: 1, user_id: 1, status: 'archived')
    assert_not_includes TaskAssignee.all.to_a, archived
  end

  test "default_scope keeps non-archived rows" do
    active = TaskAssignee.create!(task_id: 1, user_id: 1, status: 'active')
    assert_includes TaskAssignee.all.to_a, active
  end

  test "unscoped bypasses the archived default_scope" do
    archived = TaskAssignee.create!(task_id: 1, user_id: 1, status: 'archived')
    assert_includes TaskAssignee.unscoped.where(id: archived.id).to_a, archived
  end
end
