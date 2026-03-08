class Era < ApplicationRecord
  validates :mul_id, presence: true, uniqueness: true
  validates :name, presence: true
end
