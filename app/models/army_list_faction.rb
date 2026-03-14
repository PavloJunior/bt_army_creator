class ArmyListFaction < ApplicationRecord
  belongs_to :army_list
  validates :faction_mul_id, presence: true, uniqueness: { scope: :army_list_id }
end
