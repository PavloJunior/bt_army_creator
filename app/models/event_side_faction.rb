class EventSideFaction < ApplicationRecord
  belongs_to :event_side

  validates :faction_mul_id, uniqueness: { scope: :event_side_id }
  validates :faction_name, presence: true
end
