class Faction < ApplicationRecord
  has_many :variant_factions, primary_key: :mul_id, foreign_key: :faction_id

  validates :mul_id, presence: true, uniqueness: true
  validates :name, presence: true
end
