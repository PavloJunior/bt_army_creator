class Chassis < ApplicationRecord
  has_many :variants, dependent: :destroy
  has_many :miniatures, dependent: :restrict_with_error
  has_many :sync_attempts, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
