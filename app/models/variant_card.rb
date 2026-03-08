class VariantCard < ApplicationRecord
  belongs_to :variant

  has_one_attached :image

  validates :skill, presence: true, numericality: { only_integer: true, in: 0..8 }
  validates :variant_id, uniqueness: { scope: :skill }
end
