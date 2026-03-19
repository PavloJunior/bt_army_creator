class ArmyList < ApplicationRecord
  class LockConflictError < StandardError; end
  class PointCapExceededError < StandardError; end

  TECH_BASES = %w[inner_sphere clan mixed].freeze

  belongs_to :event
  has_many :army_list_items, dependent: :destroy
  has_many :army_list_factions, dependent: :destroy
  has_many :miniatures, through: :army_list_items
  has_many :miniature_locks, dependent: :destroy

  validates :player_name, presence: true
  validates :status, inclusion: { in: %w[draft submitted inactive] }
  validates :tech_base, presence: true, inclusion: { in: TECH_BASES }

  def selected_faction_mul_ids
    ids = army_list_factions.pluck(:faction_mul_id)
    ids.presence
  end

  def tech_base_label
    { "inner_sphere" => "Inner Sphere", "clan" => "Clan", "mixed" => "Mixed" }[tech_base]
  end

  def total_points
    army_list_items.includes(:variant).sum do |item|
      if event.game_system == "alpha_strike"
        item.adjusted_point_value || 0
      else
        item.variant.battle_value || 0
      end
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

  def inactive?
    status == "inactive"
  end

  def all_cards_ready?
    pending_cards_count == 0
  end

  def pending_cards_count
    army_list_items.includes(variant: { variant_cards: :image_attachment }).count do |item|
      card = item.card_image
      !card&.image&.attached?
    end
  end

  def submit!
    if total_points > event.point_cap
      raise PointCapExceededError,
        "Nie można zgłosić listy — przekroczono limit #{event.point_cap} #{event.point_value_label} (razem: #{total_points} #{event.point_value_label})"
    end

    items = army_list_items.includes(:miniature)
    locked = items.select { |item| item.miniature.locked_for_event?(event) }

    if locked.any?
      names = locked.map { |item| item.miniature.chassis.name }.uniq.join(", ")
      raise LockConflictError, "Następujące modele nie są już dostępne: #{names}"
    end

    transaction do
      items.each do |item|
        MiniatureLock.create!(
          miniature: item.miniature,
          event: event,
          army_list: self
        )
      end

      update!(status: "submitted", submitted_at: Time.current)
    end

    prefetch_missing_cards
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

  def deactivate!
    transaction do
      miniature_locks.destroy_all
      update!(status: "inactive")
    end

    broadcast_lock_updates
  end

  def reactivate!
    items = army_list_items.includes(:miniature)
    locked = items.select { |item| item.miniature.locked_for_event?(event) }

    if locked.any?
      names = locked.map { |item| item.miniature.chassis.name }.uniq.join(", ")
      raise LockConflictError, "Następujące modele nie są już dostępne: #{names}"
    end

    transaction do
      items.each do |item|
        MiniatureLock.create!(
          miniature: item.miniature,
          event: event,
          army_list: self
        )
      end
      update!(status: "submitted", submitted_at: Time.current)
    end

    prefetch_missing_cards
    broadcast_lock_updates
  rescue ActiveRecord::RecordNotUnique
    raise LockConflictError, "Jedna lub więcej miniatur została właśnie zajęta przez innego gracza. Sprawdź swoją listę."
  end

  private

  def prefetch_missing_cards
    army_list_items.includes(variant: { variant_cards: { image_attachment: :blob } }).each do |item|
      card = item.card_image
      next if card&.image&.attached?
      FetchVariantCardJob.perform_later(item.variant_id, skill: item.skill)
    end
  end

  def broadcast_lock_updates
    Turbo::StreamsChannel.broadcast_refresh_to("event_#{event_id}_miniatures")
  end

  def broadcast_unlock_updates
    # Can't render per-user partials in a broadcast (each viewer has their own army_list),
    # so trigger a full page refresh for all subscribers instead.
    Turbo::StreamsChannel.broadcast_refresh_to("event_#{event_id}_miniatures")
  end
end
