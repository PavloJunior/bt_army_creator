class SyncChassisJob < ApplicationJob
  queue_as :default
  retry_on MulClient::ApiError, wait: :polynomially_longer, attempts: 5
  limits_concurrency to: 1, key: ->(chassis_id) { "sync_chassis_#{chassis_id}" }

  def perform(chassis_id)
    chassis = Chassis.find(chassis_id)
    sync_attempt = chassis.sync_attempts.create!(
      status: "running",
      started_at: Time.current
    )

    # Phase 1: Sync variants inline
    sync_variants(chassis)
    sync_attempt.update!(variants_count: chassis.variants.count)

    # Phase 2: Enqueue per-faction jobs
    sync_attempt.update!(factions_total: Faction.count)
    Faction.find_each do |faction|
      SyncFactionForChassisJob.perform_later(chassis.id, faction.id, sync_attempt.id)
    end

    # Phase 3: Enqueue per-card jobs
    variants_needing_cards = chassis.variants.usable.select { |v| !v.card_for_skill(4)&.image&.attached? }
    sync_attempt.update!(cards_total: variants_needing_cards.size)
    variants_needing_cards.each do |variant|
      FetchVariantCardJob.perform_later(variant.id, skill: 4, sync_attempt_id: sync_attempt.id)
    end

    # If nothing to do in either phase, check completion immediately
    sync_attempt.check_completion!
  rescue => e
    sync_attempt&.fail!("Orchestrator error: #{e.message}") if sync_attempt&.persisted? && sync_attempt&.status == "running"
    raise
  end

  private

  def sync_variants(chassis)
    variants_data = MulClient.fetch_variants(chassis.name)
    variants_data = variants_data.select { |data| data["Class"]&.casecmp(chassis.name)&.zero? }
    if chassis.unit_type.present?
      variants_data = variants_data.select { |data| data.dig("Type", "Name") == chassis.unit_type }
    end

    ApplicationRecord.transaction do
      variants_data.each do |data|
        variant = Variant.find_or_initialize_by(mul_id: data["Id"])
        next if variant.persisted? && variant.chassis_id != chassis.id
        variant.chassis = chassis
        variant.assign_attributes(
          name:             data["Name"],
          variant_code:     data["Variant"],
          battle_value:     data["BattleValue"],
          point_value:      data["BFPointValue"],
          tonnage:          data["Tonnage"]&.to_i,
          unit_type:        data.dig("Type", "Name"),
          technology:       data.dig("Technology", "Name"),
          role:             data.dig("Role", "Name"),
          date_introduced:  data["DateIntroduced"],
          era_id:           data["EraId"],
          era_name:         Era.find_by(mul_id: data["EraId"])&.name || "Unknown",
          rules_level:      data["Rules"],
          image_url:        data["ImageUrl"],
          bf_move:          data["BFMove"],
          bf_armor:         data["BFArmor"],
          bf_structure:     data["BFStructure"],
          bf_threshold:     data["BFThreshold"],
          bf_damage_short:  data["BFDamageShort"],
          bf_damage_medium: data["BFDamageMedium"],
          bf_damage_long:   data["BFDamageLong"],
          bf_size:          data["BFSize"],
          bf_overheat:      data["BFOverheat"],
          bf_abilities:     data["BFAbilities"],
          raw_mul_data:     data
        )
        variant.save!
      end

      if variants_data.any?
        representative = variants_data.find { |d| d["Tonnage"].to_i > 0 } || variants_data.first
        chassis.update!(
          tonnage:       representative["Tonnage"]&.to_i,
          unit_type:     representative.dig("Type", "Name"),
          image_url:     representative["ImageUrl"],
          mul_synced_at: Time.current
        )
      end
    end
  end
end
