class VariantFaction < ApplicationRecord
  belongs_to :variant

  validates :faction_id, uniqueness: { scope: :variant_id }
end
