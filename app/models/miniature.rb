class Miniature < ApplicationRecord
  belongs_to :chassis
  has_many :miniature_locks, dependent: :destroy
  has_many :army_list_items, dependent: :restrict_with_error

  delegate :variants, to: :chassis

  def display_name
    label.presence || chassis.name
  end

  def locked_for_event?(event)
    miniature_locks.exists?(event: event)
  end

  def available_for_event?(event)
    !locked_for_event?(event)
  end
end
