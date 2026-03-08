class SyncFactionForChassisJob < ApplicationJob
  queue_as :default
  retry_on MulClient::ApiError, wait: :polynomially_longer, attempts: 5 do |job, error|
    # Final failure after all retries exhausted — increment counter so sync can complete
    _chassis_id, faction_id, sync_attempt_id = job.arguments
    sync_attempt = SyncAttempt.find_by(id: sync_attempt_id)
    if sync_attempt
      sync_attempt.append_error("Faction #{faction_id} (gave up): #{error.message}")
      sync_attempt.increment!(:factions_synced)
      sync_attempt.check_completion!
    end
  end
  limits_concurrency to: 1, key: ->(chassis_id, _faction_id, _sync_attempt_id) { "mul_api_faction_#{chassis_id}" }

  def perform(chassis_id, faction_id, sync_attempt_id)
    chassis = Chassis.find(chassis_id)
    faction = Faction.find(faction_id)
    sync_attempt = SyncAttempt.find(sync_attempt_id)

    variant_mul_ids = chassis.variants.pluck(:mul_id)
    return increment_and_check(sync_attempt) if variant_mul_ids.empty?

    results = MulClient.fetch_variants(chassis.name, faction_id: faction.mul_id)
    result_mul_ids = results.map { |r| r["Id"] }

    matching_ids = variant_mul_ids & result_mul_ids
    unless matching_ids.empty?
      matching_variants = chassis.variants.where(mul_id: matching_ids)
      matching_variants.each do |variant|
        variant.variant_factions.find_or_create_by!(
          faction_id: faction.mul_id,
          faction_name: faction.name
        )
      end
    end

    increment_and_check(sync_attempt)
  rescue MulClient::ApiError => e
    sync_attempt = SyncAttempt.find_by(id: sync_attempt_id)
    sync_attempt&.append_error("Faction #{faction_id}: #{e.message}")
    raise
  end

  private

  def increment_and_check(sync_attempt)
    sync_attempt.increment!(:factions_synced)
    sync_attempt.check_completion!
  end
end
