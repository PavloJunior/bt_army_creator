class Variant < ApplicationRecord
  belongs_to :chassis
  has_many :variant_factions, dependent: :destroy
  has_many :variant_cards, dependent: :destroy

  validates :mul_id, presence: true, uniqueness: true
  validates :name, presence: true

  scope :for_era, ->(era_id) { where(era_id: era_id) }
  scope :introduced_by, ->(year) { where("CAST(date_introduced AS INTEGER) <= ?", year) }
  scope :for_technology, ->(tech) { where(technology: tech) }
  scope :usable, -> { where("battle_value > 0 OR point_value > 0") }
  scope :unusable, -> { where(battle_value: [ 0, nil ], point_value: [ 0, nil ]) }

  def usable?
    (battle_value.present? && battle_value > 0) || (point_value.present? && point_value > 0)
  end

  def card_for_skill(skill = 4)
    variant_cards.find_by(skill: skill)
  end
end
