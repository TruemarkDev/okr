require 'test_helper'

# Characterization tests for Task — pin current behavior, do not fix or judge it.
class TaskTest < ActiveSupport::TestCase

  # Build a valid, saveable task. Task#update_team_task_count (after_save) calls
  # team.update_attributes, so a real team association is required or save blows up.
  def build_task(attrs = {})
    Task.new({
      name: 'Char Task',
      description: 'desc',
      start_date: Time.now,
      end_date: Time.now,
      team: teams(:one),
      project: projects(:one),
      user: users(:admin)
    }.merge(attrs))
  end

  # --- default_scope ---------------------------------------------------------

  test "default_scope excludes rows with is_deleted true" do
    t = build_task
    t.save!
    t.update_attribute(:is_deleted, true)
    assert_not_includes Task.all.to_a, t
  end

  test "default_scope keeps non-deleted rows" do
    t = build_task
    t.save!
    assert_includes Task.all.to_a, t
  end

  test "default_scope orders by id desc" do
    a = build_task; a.save!
    b = build_task; b.save!
    ids = Task.all.map(&:id)
    assert_equal ids.sort.reverse, ids
    # newest (largest id) comes first
    assert ids.index(b.id) < ids.index(a.id)
  end

  test "Task.unscoped bypasses default_scope and sees deleted rows" do
    t = build_task
    t.save!
    t.update_attribute(:is_deleted, true)
    assert_includes Task.unscoped.where(id: t.id).to_a, t
  end

  # --- scopes ----------------------------------------------------------------

  test "active scope returns only non-deleted" do
    live = build_task; live.save!
    dead = build_task; dead.save!; dead.update_attribute(:is_deleted, true)
    assert_includes Task.active, live
    assert_not_includes Task.active, dead
  end

  test "root scope returns tasks with nil task_id" do
    root = build_task; root.save!
    sub = build_task(task_id: root.id); sub.save!
    assert_includes Task.root, root
    assert_not_includes Task.root, sub
  end

  test "sub scope returns tasks with a non-nil task_id" do
    root = build_task; root.save!
    sub = build_task(task_id: root.id); sub.save!
    assert_includes Task.sub, sub
    assert_not_includes Task.sub, root
  end

  test "pending scope matches status active and completed scope matches status completed" do
    p = build_task(status: 'active'); p.save!
    c = build_task(status: 'completed'); c.save!
    assert_includes Task.pending, p
    assert_not_includes Task.pending, c
    assert_includes Task.completed, c
    assert_not_includes Task.completed, p
  end

  # --- self-referential root_task / sub_tasks --------------------------------

  test "sub_tasks and root_task association resolve via task_id" do
    root = build_task; root.save!
    sub = build_task(task_id: root.id); sub.save!
    assert_includes root.sub_tasks, sub
    assert_equal root, sub.root_task
  end

  # --- key_results many-to-many through task_key_results ---------------------

  test "key_results are reachable through task_key_results" do
    assert_includes tasks(:one).key_results, key_results(:one)
  end

  # --- derived users through key_results (uniq) ------------------------------

  test "users are derived through key_results" do
    # task one -> task_key_results(one/two) -> key_result one -> user 1 (admin)
    assert_includes tasks(:one).users, users(:admin)
  end

  test "derived users are uniq even with duplicate key_result joins" do
    # task_key_results fixtures point task 1 at key_result 1 twice; users must dedupe
    assert_equal tasks(:one).users.to_a.uniq, tasks(:one).users.to_a
  end

  # --- searchable_for_user ---------------------------------------------------

  test "searchable_for_user includes the user's authored task" do
    # tasks(:one).user_id == 1 (admin), so admin's task_ids covers it
    assert_includes Task.searchable_for_user(users(:admin)), tasks(:one)
  end

  test "searchable_for_user matches on project_id membership" do
    # admin is a project_manager for project 1 (project_managers fixture)
    t = build_task
    t.save!
    assert_includes Task.searchable_for_user(users(:admin)), t
  end

  # --- before_create :add_tracker_id -----------------------------------------

  test "add_tracker_id sets tracker_id to unscoped last tracker_id + 1" do
    expected = Task.unscoped.last.try(:tracker_id).to_i + 1
    t = build_task(tracker_id: nil)
    t.save!
    # Rails 4.2 type-casts attribute values on assignment (not just on
    # read/save as in 4.1), so the string column stringifies the integer the
    # callback assigned immediately, in-memory.
    assert_equal expected.to_s, t.tracker_id
    # ...and it persists to the string column as the stringified value
    assert_equal expected.to_s, t.reload.tracker_id
  end

  # --- before_update :update_completion --------------------------------------

  test "moving status active -> completed stamps completed_on" do
    t = build_task(status: 'active'); t.save!
    assert_nil t.completed_on
    t.update_attributes(status: 'completed')
    assert_not_nil t.completed_on
  end

  test "moving status completed -> active clears completed_on" do
    t = build_task(status: 'completed', completed_on: Time.now); t.save!
    t.update_attributes(status: 'active')
    assert_nil t.completed_on
  end

  # --- after_save :update_team_task_count ------------------------------------

  test "saving a pending task refreshes the team's pending_tasks count" do
    team = teams(:one)
    t = build_task(team: team, status: 'active'); t.save!
    team.reload
    assert_equal team.tasks.active.pending.count, team.pending_tasks
  end

  # --- updatable_by_user -----------------------------------------------------

  test "updatable_by_user true when user is a derived assignee" do
    assert tasks(:one).updatable_by_user(users(:admin))
  end

  test "updatable_by_user is falsy for an unrelated user" do
    stranger = users(:two)
    # user two authored nothing, is on no admin_team, manages no project here
    assert_nil tasks(:one).updatable_by_user(stranger)
  end

  # --- time_to_end -----------------------------------------------------------

  test "time_to_end says Due today when end_date is today" do
    t = build_task(end_date: Time.now)
    assert_equal 'Due today', t.time_to_end
  end

  test "time_to_end reports days left within a week" do
    t = build_task(end_date: 3.days.from_now)
    assert_match(/left/, t.time_to_end)
  end

  test "time_to_end reports Ended on for past dates" do
    t = build_task(end_date: 10.days.ago)
    assert_match(/^Ended on/, t.time_to_end)
  end

  test "time_to_end reports Due for far-future dates" do
    t = build_task(end_date: 30.days.from_now)
    assert_match(/^Due /, t.time_to_end)
  end

  # --- timestamp -------------------------------------------------------------

  test "timestamp formats created_at" do
    t = build_task; t.save!
    assert_equal t.created_at.strftime('%d %B %Y %H:%M:%S'), t.timestamp
  end
end
