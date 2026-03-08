require "test_helper"

class SyncFactionForChassisJobTest < ActiveJob::TestCase
  setup do
    @chassis = chassis(:atlas)
    @faction = factions(:federated_suns)
    @sync_attempt = SyncAttempt.create!(
      chassis: @chassis,
      status: "running",
      factions_total: 2,
      factions_synced: 0,
      started_at: Time.current
    )
  end

  test "creates variant_faction records for matching variants" do
    variant = variants(:atlas_d)
    fake_results = [ { "Id" => variant.mul_id } ]

    stub_mul_client(fake_results) do
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    end

    assert variant.variant_factions.exists?(faction_id: @faction.mul_id)
  end

  test "increments factions_synced on success" do
    stub_mul_client([]) do
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    end

    assert_equal 1, @sync_attempt.reload.factions_synced
  end

  test "handles empty variant list" do
    stub_mul_client([]) do
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    end

    assert_equal 1, @sync_attempt.reload.factions_synced
  end

  test "appends error on API failure" do
    original = MulClient.method(:fetch_variants)
    MulClient.define_singleton_method(:fetch_variants) { |*args, **kwargs| raise MulClient::ApiError, "timeout" }

    begin
      # retry_on catches ApiError, so it won't propagate
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    ensure
      MulClient.define_singleton_method(:fetch_variants, original)
    end

    assert @sync_attempt.reload.error_messages.any? { |msg| msg.include?("timeout") }
  end

  test "checks completion after incrementing" do
    @sync_attempt.update!(factions_synced: 1, cards_total: 0, cards_synced: 0)

    stub_mul_client([]) do
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    end

    assert_equal "completed", @sync_attempt.reload.status
  end

  test "does not complete when other factions pending" do
    @sync_attempt.update!(factions_total: 10)

    stub_mul_client([]) do
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    end

    assert_equal "running", @sync_attempt.reload.status
  end

  test "is idempotent for variant_faction creation" do
    variant = variants(:atlas_d)
    fake_results = [ { "Id" => variant.mul_id } ]

    # Run twice — should not raise on duplicate
    stub_mul_client(fake_results) do
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    end

    @sync_attempt.update!(factions_synced: 0)

    stub_mul_client(fake_results) do
      SyncFactionForChassisJob.perform_now(@chassis.id, @faction.id, @sync_attempt.id)
    end

    assert_equal 1, variant.variant_factions.where(faction_id: @faction.mul_id).count
  end

  private

  def stub_mul_client(results, &block)
    original = MulClient.method(:fetch_variants)
    MulClient.define_singleton_method(:fetch_variants) { |*args, **kwargs| results }
    yield
  ensure
    MulClient.define_singleton_method(:fetch_variants, original)
  end
end
