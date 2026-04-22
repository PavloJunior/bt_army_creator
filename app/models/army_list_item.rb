class ArmyListItem < ApplicationRecord
  include AlphaStrikePvAdjustment

  belongs_to :army_list
  belongs_to :miniature
  belongs_to :variant
  belongs_to :added_by_participant,
             class_name: "SharedArmyListParticipant",
             optional: true

  validates :miniature_id, uniqueness: { scope: :army_list_id }
  validates :skill, numericality: { only_integer: true, in: 0..8 }
  validate :variant_belongs_to_chassis
  validate :variant_matches_tech_base
  validate :variant_matches_selected_factions

  after_commit :reset_shared_list_acceptances, if: :army_list_shared?

  after_create_commit :broadcast_shared_create, if: :army_list_shared?
  after_destroy_commit :broadcast_shared_destroy, if: :army_list_shared?
  after_update_commit :broadcast_shared_update, if: :army_list_shared?

  def card_image
    variant.card_for_skill(skill)
  end

  def exceeds_point_cap?
    return false unless variant && army_list

    army_list.total_points > army_list.effective_point_cap
  end

  private

  def variant_belongs_to_chassis
    return unless miniature && variant
    unless miniature.chassis.group_chassis_ids.include?(variant.chassis_id)
      errors.add(:variant, "must belong to the same chassis as the miniature")
    end
  end

  def variant_matches_tech_base
    return unless variant && army_list
    tech_base = army_list.tech_base
    return if tech_base.blank? || tech_base == "mixed"

    excluded_tech = { "inner_sphere" => "Clan", "clan" => "Inner Sphere" }[tech_base]
    if excluded_tech && variant.technology == excluded_tech
      errors.add(:variant, "is not available for the #{army_list.tech_base_label} tech base")
      return
    end

    faction_mul_ids = Faction.for_tech_base(tech_base).pluck(:mul_id)
    unless variant.variant_factions.exists?(faction_id: faction_mul_ids)
      errors.add(:variant, "is not available for the #{army_list.tech_base_label} tech base")
    end
  end

  def variant_matches_selected_factions
    return unless variant && army_list
    selected = army_list.army_list_factions.pluck(:faction_mul_id)
    return if selected.empty?

    unless variant.variant_factions.exists?(faction_id: selected)
      errors.add(:variant, "does not belong to any of the selected factions")
    end
  end

  def army_list_shared?
    army_list&.shared?
  end

  def reset_shared_list_acceptances
    army_list.active_participants.update_all(accepted_at: nil)
  end

  def shared_stream
    "shared_army_list_#{army_list_id}"
  end

  def broadcast_shared_create
    Turbo::StreamsChannel.broadcast_append_to(
      shared_stream,
      target: "army_list_items",
      partial: "army_list_items/item",
      locals: broadcast_item_locals
    )
    broadcast_shared_chrome_updates
  end

  def broadcast_shared_destroy
    Turbo::StreamsChannel.broadcast_remove_to(
      shared_stream,
      target: ActionView::RecordIdentifier.dom_id(self)
    )
    broadcast_shared_chrome_updates
  end

  def broadcast_shared_update
    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "army_list_items/item",
      locals: broadcast_item_locals
    )
    broadcast_shared_chrome_updates
  end

  # Updates that every item mutation needs to broadcast to keep all viewers in
  # sync: point total, count badge, action buttons, acceptance banner, and the
  # affected chassis availability cards.
  def broadcast_shared_chrome_updates
    list = army_list.reload
    event = list.event

    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: "point_total",
      partial: "army_lists/point_total",
      locals: { army_list: list, event: event }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      shared_stream,
      target: "army_item_count",
      content: list.army_list_items.size.to_s
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: "army_list_actions",
      partial: "army_lists/actions",
      locals: { army_list: list, event: event, is_owner: true }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: "shared_acceptance_banner",
      partial: "shared_army_lists/acceptance_banner",
      locals: { army_list: list, event: event }
    )

    # Item mutations clear everyone's acceptance via update_all (bypassing
    # callbacks), so the roster's per-participant ✓/○ marks would otherwise
    # go stale. Re-broadcast the roster to keep it in sync with the banner.
    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: "shared_participant_roster",
      partial: "shared_army_lists/participant_roster",
      locals: { army_list: list, event: event }
    )

    broadcast_available_chassis_cards(list, event)
  end

  def broadcast_available_chassis_cards(list, event)
    primary = miniature.chassis
    chassis_group = [ primary ] + primary.sibling_chassis.to_a

    used_ids = list.army_list_items.pluck(:miniature_id)
    locked_ids = event.miniature_locks.pluck(:miniature_id)
    excluded_ids = used_ids + locked_ids
    faction_filter = list.army_list_factions.pluck(:faction_mul_id).presence
    # Pass event_side so themed events keep the side's faction scope on the
    # re-rendered chassis cards — matching the initial page render.
    event_side = list.event_side

    chassis_group.uniq.each do |c|
      available_count = c.miniatures_pool.where.not(id: excluded_ids).count
      total_count = c.miniatures_pool.count
      variants = event.available_variants_for_chassis(
        c, tech_base: list.tech_base, faction_mul_ids: faction_filter, event_side: event_side
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        shared_stream,
        target: "available_chassis_#{c.id}",
        partial: "chassis/available_chassis",
        locals: {
          chassis: c,
          available_count: available_count,
          total_count: total_count,
          variants: variants,
          event: event,
          army_list: list
        }
      )
    end
  end

  def broadcast_item_locals
    { item: self, event: army_list.event, army_list: army_list, is_owner: true }
  end
end
