class ArmyListItem < ApplicationRecord
  belongs_to :army_list
  belongs_to :miniature
  belongs_to :variant

  validates :miniature_id, uniqueness: { scope: :army_list_id }
  validates :skill, numericality: { only_integer: true, in: 0..8 }
  validate :variant_belongs_to_chassis

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
end
