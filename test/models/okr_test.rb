require 'test_helper'

# Characterization tests for Okr — pin CURRENT behavior, do not judge/fix it.
#
# Domain: Okr → Objective → KeyResult. The Okr is the source of truth for
# user_id/start_date/end_date and cascades them to its children via the
# after_save :update_children callback.
class OkrTest < ActiveSupport::TestCase
  def valid_attrs(overrides = {})
    {
      user_id:    users(:admin).id,
      name:       "Q1 growth",
      start_date: Date.new(2014, 1, 1),
      end_date:   Date.new(2014, 3, 31)
    }.merge(overrides)
  end

  # --- validations ------------------------------------------------------

  test "valid with name, user_id, start_date and end_date" do
    okr = Okr.new(valid_attrs)
    assert okr.valid?, okr.errors.full_messages.join(", ")
  end

  test "requires name" do
    okr = Okr.new(valid_attrs(name: nil))
    refute okr.valid?
    assert_includes okr.errors[:name], "can't be blank"
  end

  test "requires user_id" do
    okr = Okr.new(valid_attrs(user_id: nil))
    refute okr.valid?
    assert_includes okr.errors[:user_id], "can't be blank"
  end

  test "requires start_date" do
    okr = Okr.new(valid_attrs(start_date: nil))
    refute okr.valid?
    assert_includes okr.errors[:start_date], "can't be blank"
  end

  test "requires end_date" do
    okr = Okr.new(valid_attrs(end_date: nil))
    refute okr.valid?
    assert_includes okr.errors[:end_date], "can't be blank"
  end

  # --- associations -----------------------------------------------------

  test "belongs to user" do
    assert_equal users(:admin), okrs(:one).user
  end

  test "has_many objectives" do
    assert_includes okrs(:one).objectives, objectives(:one)
  end

  test "has_many key_results through objectives" do
    assert_includes okrs(:one).key_results, key_results(:one)
  end

  # --- scopes -----------------------------------------------------------

  test "active scope excludes soft-deleted okrs" do
    deleted = Okr.create!(valid_attrs(name: "gone", is_deleted: true))
    kept    = Okr.create!(valid_attrs(name: "here"))
    assert_includes Okr.active, kept
    refute_includes Okr.active, deleted
  end

  test "is_deleted defaults to false" do
    okr = Okr.create!(valid_attrs)
    assert_equal false, okr.is_deleted
  end

  test "approved scope only returns approved okrs" do
    approved     = Okr.create!(valid_attrs(approved: true))
    not_approved = Okr.create!(valid_attrs(approved: false))
    assert_includes Okr.approved, approved
    refute_includes Okr.approved, not_approved
  end

  test "approved defaults to false" do
    assert_equal false, Okr.create!(valid_attrs).approved
  end

  # --- nested attributes ------------------------------------------------

  test "accepts nested objectives attributes" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [{ name: "Ship v1" }]
    ))
    assert_equal 1, okr.objectives.count
    assert_equal "Ship v1", okr.objectives.first.name
  end

  test "rejects nested objective when name is blank" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [{ name: "" }]
    ))
    assert_equal 0, okr.objectives.count
  end

  test "accepts nested key_results through objectives" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [
        { name: "Obj", key_results_attributes: [{ name: "KR1" }] }
      ]
    ))
    assert_equal 1, okr.key_results.count
    assert_equal "KR1", okr.key_results.first.name
  end

  test "allows destroying nested objective via _destroy" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [{ name: "Obj" }]
    ))
    obj_id = okr.objectives.first.id
    okr.update!(objectives_attributes: [{ id: obj_id, _destroy: "1" }])
    assert_equal 0, okr.objectives.count
    assert_nil Objective.where(id: obj_id).first
  end

  # --- update_children cascade (the crown jewel) ------------------------

  test "update_children cascades user_id/start_date/end_date to objectives on save" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [{ name: "Obj" }]
    ))
    obj = okr.objectives.first.reload
    assert_equal okr.user_id, obj.user_id
    assert_equal okr.start_date, obj.start_date
    assert_equal okr.end_date, obj.end_date
  end

  test "update_children cascades to key_results on save" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [
        { name: "Obj", key_results_attributes: [{ name: "KR" }] }
      ]
    ))
    kr = okr.key_results.first.reload
    assert_equal okr.user_id, kr.user_id
    assert_equal okr.start_date, kr.start_date
    assert_equal okr.end_date, kr.end_date
  end

  test "changing okr dates cascades to existing objectives and key_results" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [
        { name: "Obj", key_results_attributes: [{ name: "KR" }] }
      ]
    ))
    new_start = Date.new(2015, 6, 1)
    new_end   = Date.new(2015, 9, 30)
    okr.update!(start_date: new_start, end_date: new_end)

    assert_equal new_start, okr.objectives.first.reload.start_date
    assert_equal new_end,   okr.objectives.first.reload.end_date
    assert_equal new_start, okr.key_results.first.reload.start_date
    assert_equal new_end,   okr.key_results.first.reload.end_date
  end

  test "changing okr user_id cascades to objectives and key_results" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [
        { name: "Obj", key_results_attributes: [{ name: "KR" }] }
      ]
    ))
    okr.update!(user_id: users(:one).id)

    assert_equal users(:one).id, okr.objectives.first.reload.user_id
    assert_equal users(:one).id, okr.key_results.first.reload.user_id
  end

  test "update_children uses update_all so it bypasses child validations/callbacks" do
    # update_all writes directly; a blank objective name would normally be
    # invalid, but the cascade only touches user_id/start_date/end_date and
    # never re-validates children. Pin that a plain re-save succeeds even when
    # a child was created with an odd state.
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [{ name: "Obj" }]
    ))
    obj = okr.objectives.first
    obj.update_column(:name, "") # bypass validation to force a "bad" child
    assert okr.save, "re-saving okr should not fail despite invalid child"
    assert_equal okr.start_date, obj.reload.start_date
  end

  test "update_children is callable directly and returns child update" do
    okr = Okr.create!(valid_attrs(
      objectives_attributes: [{ name: "Obj" }]
    ))
    assert_nothing_raised { okr.update_children }
  end
end
