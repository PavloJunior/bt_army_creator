class ArmyListItem < ApplicationRecord
  include AlphaStrikePvAdjustment

  belongs_to :army_list
  belongs_to :miniature
  belongs_to :variant

  validates :miniature_id, uniqueness: { scope: :army_list_id }
  validates :skill, numericality: { only_integer: true, in: 0..8 }
  validate :variant_belongs_to_chassis
  validate :variant_matches_tech_base
  validate :variant_matches_selected_factions

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
end
