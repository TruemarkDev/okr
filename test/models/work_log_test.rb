require 'test_helper'

# Characterization tests for WorkLog — pin current behavior, do not fix or judge it.
class WorkLogTest < ActiveSupport::TestCase

  def build_log(attrs = {})
    WorkLog.new({
      user: users(:admin),
      task_id: 1,
      name: 'log',
      date: Date.today
    }.merge(attrs))
  end

  # --- validations -----------------------------------------------------------

  test "requires task_id" do
    log = build_log(task_id: nil)
    assert_not log.valid?
    assert_includes log.errors[:task_id], "can't be blank"
  end

  test "valid with task_id and today's date" do
    assert build_log.valid?
  end

  test "date within the last 6 days is valid" do
    assert build_log(date: 3.days.ago.to_date).valid?
  end

  test "date older than 6 days is invalid" do
    log = build_log(date: 30.days.ago.to_date)
    assert_not log.valid?
    assert_includes log.errors[:date], 'Date should be older than 5 days'
  end

  test "future date is invalid" do
    log = build_log(date: 5.days.from_now.to_date)
    assert_not log.valid?
    assert_includes log.errors[:date], 'Date should be older than 5 days'
  end

  # --- active scope ----------------------------------------------------------

  test "active scope excludes soft-deleted logs" do
    live = build_log; live.save!
    dead = build_log; dead.save!; dead.update_attribute(:is_deleted, true)
    assert_includes WorkLog.active, live
    assert_not_includes WorkLog.active, dead
  end

  # --- associations ----------------------------------------------------------

  test "belongs to user and task" do
    assert_equal users(:admin), work_logs(:one).user
    assert_equal tasks(:one), work_logs(:one).task
  end

  # --- hours -----------------------------------------------------------------

  test "hours formats minutes as h:mm" do
    assert_equal '1:30', build_log(minutes: 90).hours
  end

  test "hours zero-pads the minutes component" do
    assert_equal '2:05', build_log(minutes: 125).hours
  end

  test "hours treats nil minutes as 0:00" do
    assert_equal '0:00', build_log(minutes: nil).hours
  end

  # --- self.user_logs_dated --------------------------------------------------

  test "user_logs_dated returns the user's log for today, ignoring the passed date" do
    # work_logs(:one) belongs to admin with date today; the method hard-codes
    # Date.today and ignores its second argument entirely.
    assert_equal work_logs(:one), WorkLog.user_logs_dated(users(:admin), 99.days.ago)
  end
end
