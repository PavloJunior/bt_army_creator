class ArmyList < ApplicationRecord
  class LockConflictError < StandardError; end

  belongs_to :event
  has_many :army_list_items, dependent: :destroy
  has_many :miniatures, through: :army_list_items
  has_many :miniature_locks, dependent: :destroy

  validates :player_name, presence: true
  validates :status, inclusion: { in: %w[draft submitted] }

  def total_points
    army_list_items.includes(:variant).sum do |item|
      item.variant.send(event.point_value_method) || 0
    end
  end

  def points_remaining
    event.point_cap - total_points
  end

  def submitted?
    status == "submitted"
  end

  def draft?
    status == "draft"
  end

  def submit!
    transaction do
      army_list_items.includes(:miniature).each do |item|
        if item.miniature.locked_for_event?(event)
          raise LockConflictError, "#{item.miniature.display_name} nie jest już dostępna"
        end

        MiniatureLock.create!(
          miniature: item.miniature,
          event: event,
          army_list: self
        )
      end

      update!(status: "submitted", submitted_at: Time.current)
    end

    broadcast_lock_updates
  rescue ActiveRecord::RecordNotUnique
    raise LockConflictError, "Jedna lub więcej miniatur została właśnie zajęta przez innego gracza. Sprawdź swoją listę."
  end

  def unlock!
    transaction do
      miniature_locks.destroy_all
      update!(status: "draft", submitted_at: nil)
    end

    broadcast_unlock_updates
  end

  private

  def broadcast_lock_updates
    army_list_items.includes(:miniature).each do |item|
      Turbo::StreamsChannel.broadcast_remove_to(
        "event_#{event_id}_miniatures",
        target: "available_miniature_#{item.miniature_id}"
      )
    end
  end

  def broadcast_unlock_updates
    # Can't render per-user partials in a broadcast (each viewer has their own army_list),
    # so trigger a full page refresh for all subscribers instead.
    Turbo::StreamsChannel.broadcast_refresh_to("event_#{event_id}_miniatures")
  end
end
