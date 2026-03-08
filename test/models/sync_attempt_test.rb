require "test_helper"

class SyncAttemptTest < ActiveSupport::TestCase
  setup do
    @chassis = chassis(:atlas)
  end

  test "valid with required attributes" do
    attempt = SyncAttempt.new(chassis: @chassis, status: "running")
    assert attempt.valid?
  end

  test "requires chassis" do
    attempt = SyncAttempt.new(status: "running")
    assert_not attempt.valid?
    assert attempt.errors[:chassis].any?
  end

  test "requires status" do
    attempt = SyncAttempt.new(chassis: @chassis, status: nil)
    assert_not attempt.valid?
  end

  test "status must be valid" do
    attempt = SyncAttempt.new(chassis: @chassis, status: "invalid")
    assert_not attempt.valid?
  end

  test "defaults" do
    attempt = SyncAttempt.create!(chassis: @chassis)
    assert_equal "running", attempt.status
    assert_equal 0, attempt.variants_count
    assert_equal 0, attempt.factions_total
    assert_equal 0, attempt.factions_synced
    assert_equal 0, attempt.cards_total
    assert_equal 0, attempt.cards_synced
    assert_equal [], attempt.error_messages
  end

  test "running scope" do
    assert_includes SyncAttempt.running, sync_attempts(:atlas_running)
    assert_not_includes SyncAttempt.running, sync_attempts(:atlas_completed)
  end

  test "completed scope" do
    assert_includes SyncAttempt.completed, sync_attempts(:atlas_completed)
    assert_not_includes SyncAttempt.completed, sync_attempts(:atlas_running)
  end

  test "failed scope" do
    assert_includes SyncAttempt.failed, sync_attempts(:commando_failed)
    assert_not_includes SyncAttempt.failed, sync_attempts(:atlas_running)
  end

  test "duration returns seconds when completed" do
    attempt = sync_attempts(:atlas_completed)
    assert attempt.duration > 0
  end

  test "duration returns elapsed time when still running" do
    attempt = sync_attempts(:atlas_running)
    assert attempt.duration > 0
  end

  test "duration returns nil without started_at" do
    attempt = SyncAttempt.new(chassis: @chassis)
    assert_nil attempt.duration
  end

  test "progress_text shows faction and card progress" do
    attempt = sync_attempts(:atlas_running)
    text = attempt.progress_text
    assert_includes text, "Factions: 1/2"
    assert_includes text, "Cards: 3/10"
  end

  test "progress_text omits zero totals" do
    attempt = SyncAttempt.new(chassis: @chassis, factions_total: 0, cards_total: 0)
    assert_equal "", attempt.progress_text
  end

  test "check_completion! marks completed when all done" do
    attempt = SyncAttempt.create!(
      chassis: @chassis,
      status: "running",
      factions_total: 2,
      factions_synced: 2,
      cards_total: 3,
      cards_synced: 3,
      started_at: 1.minute.ago
    )
    attempt.check_completion!
    assert_equal "completed", attempt.reload.status
    assert_not_nil attempt.completed_at
  end

  test "check_completion! does not mark completed when factions pending" do
    attempt = SyncAttempt.create!(
      chassis: @chassis,
      status: "running",
      factions_total: 2,
      factions_synced: 1,
      cards_total: 0,
      cards_synced: 0,
      started_at: 1.minute.ago
    )
    attempt.check_completion!
    assert_equal "running", attempt.reload.status
  end

  test "check_completion! does not mark completed when cards pending" do
    attempt = SyncAttempt.create!(
      chassis: @chassis,
      status: "running",
      factions_total: 2,
      factions_synced: 2,
      cards_total: 3,
      cards_synced: 1,
      started_at: 1.minute.ago
    )
    attempt.check_completion!
    assert_equal "running", attempt.reload.status
  end

  test "check_completion! is idempotent on already completed" do
    attempt = sync_attempts(:atlas_completed)
    original_completed_at = attempt.completed_at
    attempt.check_completion!
    assert_equal original_completed_at, attempt.reload.completed_at
  end

  test "check_completion! marks completed when both totals are zero" do
    attempt = SyncAttempt.create!(
      chassis: @chassis,
      status: "running",
      factions_total: 0,
      factions_synced: 0,
      cards_total: 0,
      cards_synced: 0,
      started_at: 1.minute.ago
    )
    attempt.check_completion!
    assert_equal "completed", attempt.reload.status
  end

  test "fail! sets status and records error" do
    attempt = SyncAttempt.create!(
      chassis: @chassis,
      status: "running",
      started_at: 1.minute.ago
    )
    attempt.fail!("Something went wrong")
    attempt.reload
    assert_equal "failed", attempt.status
    assert_not_nil attempt.completed_at
    assert_includes attempt.error_messages, "Something went wrong"
  end

  test "append_error adds to error_messages" do
    attempt = SyncAttempt.create!(chassis: @chassis, status: "running", started_at: 1.minute.ago)
    attempt.append_error("Error 1")
    attempt.append_error("Error 2")
    attempt.reload
    assert_equal [ "Error 1", "Error 2" ], attempt.error_messages
  end

  test "chassis association" do
    assert_equal @chassis, sync_attempts(:atlas_completed).chassis
  end

  test "destroying chassis destroys sync_attempts" do
    chassis = Chassis.create!(name: "Tempchass")
    chassis.sync_attempts.create!(status: "completed", started_at: 1.hour.ago, completed_at: Time.current)
    assert_difference "SyncAttempt.count", -1 do
      chassis.destroy
    end
  end
end
