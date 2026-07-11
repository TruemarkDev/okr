require 'test_helper'

# Characterization tests for Comment — pin current behavior, do not fix or judge it.
class CommentTest < ActiveSupport::TestCase

  def build_comment(attrs = {})
    Comment.new({
      user: users(:admin),
      body: 'hello',
      source: tasks(:one)
    }.merge(attrs))
  end

  # --- validations -----------------------------------------------------------

  test "valid with user, body and source" do
    assert build_comment.valid?
  end

  test "requires user_id" do
    c = build_comment(user: nil)
    assert_not c.valid?
    assert_includes c.errors[:user_id], "can't be blank"
  end

  test "requires body" do
    c = build_comment(body: nil)
    assert_not c.valid?
    assert_includes c.errors[:body], "can't be blank"
  end

  test "requires source" do
    c = build_comment(source: nil)
    assert_not c.valid?
    assert_includes c.errors[:source], "can't be blank"
  end

  # --- polymorphic source ----------------------------------------------------

  test "source is polymorphic and resolves to the task" do
    assert_equal tasks(:one), comments(:one).source
    assert_equal 'Task', comments(:one).source_type
  end

  # --- active scope ----------------------------------------------------------

  test "active scope excludes soft-deleted comments" do
    live = build_comment; live.save!
    dead = build_comment; dead.save!; dead.update_attribute(:is_deleted, true)
    assert_includes Comment.active, live
    assert_not_includes Comment.active, dead
  end

  # --- after_save :update_comment_count --------------------------------------

  test "saving a comment refreshes the source's comments_count" do
    task = tasks(:one)
    build_comment(source: task).save!
    task.reload
    assert_equal task.comments.active.count, task.comments_count
  end
end
