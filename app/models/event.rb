class Event < ApplicationRecord
  has_many :event_era_restrictions, dependent: :destroy
  has_many :event_faction_restrictions, dependent: :destroy
  has_many :event_sides, -> { order(:position) }, dependent: :destroy
  has_many :army_lists, dependent: :destroy
  has_many :miniature_locks, dependent: :destroy

  validates :name, presence: true
  validates :game_system, presence: true, inclusion: { in: %w[classic_bt alpha_strike] }
  validates :point_cap, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[upcoming active completed] }
  validate :themed_must_have_sides

  scope :upcoming, -> { where(status: "upcoming") }
  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }

  def point_value_method
    game_system == "classic_bt" ? :battle_value : :point_value
  end

  def point_value_label
    game_system == "classic_bt" ? "BV" : "PV"
  end

  def game_system_label
    game_system == "classic_bt" ? "Classic BattleTech" : "Alpha Strike"
  end

  def available_variants_for_chassis(chassis, tech_base: nil, faction_mul_ids: nil, event_side: nil)
    scope = chassis.variants.usable.where(Variant.arel_table[point_value_method].gt(0))

    if event_era_restrictions.any?
      scope = scope.where(era_id: event_era_restrictions.pluck(:era_mul_id))
    end

    faction_filter_ids = nil

    if event_side
      faction_filter_ids = event_side.event_side_factions.pluck(:faction_mul_id)
    elsif event_faction_restrictions.any?
      faction_filter_ids = event_faction_restrictions.pluck(:faction_mul_id)
    end

    if tech_base.present? && tech_base != "mixed"
      excluded_tech = { "inner_sphere" => "Clan", "clan" => "Inner Sphere" }[tech_base]
      scope = scope.where.not(technology: excluded_tech) if excluded_tech

      # For themed events, side factions define the scope — don't further
      # restrict by tech-base faction mapping (a Clan faction can field IS-tech units)
      unless event_side
        tech_ids = Faction.for_tech_base(tech_base).pluck(:mul_id)
        faction_filter_ids = faction_filter_ids ? (faction_filter_ids & tech_ids) : tech_ids
      end
    end

    if faction_mul_ids.present?
      faction_filter_ids = faction_filter_ids ? (faction_filter_ids & faction_mul_ids) : faction_mul_ids
    end

    if faction_filter_ids
      scope = scope.joins(:variant_factions)
                   .where(variant_factions: { faction_id: faction_filter_ids })
    end

    scope.distinct
  end

  def available_miniatures
    locked_ids = miniature_locks.pluck(:miniature_id)
    scope = Miniature.includes(:chassis)
    scope = scope.where.not(id: locked_ids) if locked_ids.any?
    scope
  end

  private

  def themed_must_have_sides
    return unless themed?
    # Skip on new records — sides are saved after the event is created
    return if new_record?

    sides_count = event_sides.reject(&:marked_for_destruction?).size
    unless sides_count.between?(2, 4)
      errors.add(:base, "Themed events must have between 2 and 4 sides")
    end
  end
end
