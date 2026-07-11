require 'test_helper'

# Characterization tests for Objective — pin CURRENT behavior.
# Objective belongs_to okr/user, has_many key_results and tasks (through KRs),
# accepts nested key_results, validates name, and has an :active scope.
class ObjectiveTest < ActiveSupport::TestCase
  # --- validations ------------------------------------------------------

  test "valid with a name" do
    assert Objective.new(name: "Obj").valid?
  end

  test "requires name" do
    obj = Objective.new(name: nil)
    refute obj.valid?
    assert_includes obj.errors[:name], "can't be blank"
  end

  test "user_id and dates are NOT validated on Objective" do
    # Unlike Okr, Objective only validates name — dates/user come from the
    # cascade, so a bare objective with just a name is valid.
    assert Objective.new(name: "bare").valid?
  end

  # --- associations -----------------------------------------------------

  test "belongs to okr" do
    assert_equal okrs(:one), objectives(:one).okr
  end

  test "belongs to user" do
    assert_equal users(:admin), objectives(:one).user
  end

  test "has_many key_results" do
    assert_includes objectives(:one).key_results, key_results(:one)
  end

  test "has_many tasks through key_results" do
    # fixtures link task 1 to key_result 1 (which belongs to objective 1) via
    # two task_key_results rows, so the fixture task is reachable here.
    assert_respond_to objectives(:one), :tasks
    assert_includes objectives(:one).tasks.map(&:id), tasks(:one).id
  end

  # --- scopes -----------------------------------------------------------

  test "active scope excludes soft-deleted objectives" do
    kept    = Objective.create!(name: "kept", okr_id: okrs(:one).id)
    deleted = Objective.create!(name: "gone", okr_id: okrs(:one).id, is_deleted: true)
    assert_includes Objective.active, kept
    refute_includes Objective.active, deleted
  end

  test "is_deleted defaults to false" do
    assert_equal false, Objective.create!(name: "obj").is_deleted
  end

  # --- nested attributes ------------------------------------------------

  test "accepts nested key_results attributes" do
    obj = Objective.create!(
      name: "Obj",
      okr_id: okrs(:one).id,
      key_results_attributes: [{ name: "KR1" }]
    )
    assert_equal 1, obj.key_results.count
    assert_equal "KR1", obj.key_results.first.name
  end

  test "rejects nested key_result when name is blank" do
    obj = Objective.create!(
      name: "Obj",
      okr_id: okrs(:one).id,
      key_results_attributes: [{ name: "" }]
    )
    assert_equal 0, obj.key_results.count
  end

  test "allows destroying nested key_result via _destroy" do
    obj = Objective.create!(
      name: "Obj",
      okr_id: okrs(:one).id,
      key_results_attributes: [{ name: "KR" }]
    )
    kr_id = obj.key_results.first.id
    obj.update!(key_results_attributes: [{ id: kr_id, _destroy: "1" }])
    assert_equal 0, obj.key_results.count
    assert_nil KeyResult.where(id: kr_id).first
  end

  # --- no cascade of its own -------------------------------------------

  test "saving an objective does not cascade to its key_results" do
    # Only Okr#update_children cascades. Objective has no such callback, so
    # editing an objective's dates leaves its key_results untouched.
    obj = Objective.create!(
      name: "Obj",
      okr_id: okrs(:one).id,
      start_date: Date.new(2014, 1, 1),
      end_date: Date.new(2014, 3, 31),
      key_results_attributes: [{ name: "KR", start_date: Date.new(2020, 1, 1) }]
    )
    kr = obj.key_results.first
    obj.update!(start_date: Date.new(2016, 1, 1))
    assert_equal Date.new(2020, 1, 1), kr.reload.start_date
  end
end
