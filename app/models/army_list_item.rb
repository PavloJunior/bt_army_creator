class ArmyListItem < ApplicationRecord
  include AlphaStrikePvAdjustment

  belongs_to :army_list
  belongs_to :miniature
  belongs_to :variant

  validates :miniature_id, uniqueness: { scope: :army_list_id }
  validates :skill, numericality: { only_integer: true, in: 0..8 }
  validate :variant_belongs_to_chassis
  validate :variant_matches_tech_base

  def card_image
    variant.card_for_skill(skill)
  end

  private

  def variant_belongs_to_chassis
    return unless miniature && variant
    unless variant.chassis_id == miniature.chassis_id
      errors.add(:variant, "must belong to the same chassis as the miniature")
    end
  end

  def variant_matches_tech_base
    return unless variant && army_list
    tech_base = army_list.tech_base
    return if tech_base.blank? || tech_base == "mixed"

    faction_mul_ids = Faction.for_tech_base(tech_base).pluck(:mul_id)
    unless variant.variant_factions.exists?(faction_id: faction_mul_ids)
      errors.add(:variant, "is not available for the #{army_list.tech_base_label} tech base")
    end
  end
end
