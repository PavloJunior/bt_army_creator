class Event < ApplicationRecord
  has_many :event_era_restrictions, dependent: :destroy
  has_many :event_faction_restrictions, dependent: :destroy
  has_many :army_lists, dependent: :destroy
  has_many :miniature_locks, dependent: :destroy

  validates :name, presence: true
  validates :game_system, presence: true, inclusion: { in: %w[classic_bt alpha_strike] }
  validates :point_cap, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[upcoming active completed] }

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

  def available_variants_for_chassis(chassis, tech_base: nil, faction_mul_ids: nil)
    scope = chassis.variants.usable

    if event_era_restrictions.any?
      scope = scope.where(era_id: event_era_restrictions.pluck(:era_mul_id))
    end

    faction_filter_ids = nil

    if event_faction_restrictions.any?
      faction_filter_ids = event_faction_restrictions.pluck(:faction_mul_id)
    end

    if tech_base.present? && tech_base != "mixed"
      excluded_tech = { "inner_sphere" => "Clan", "clan" => "Inner Sphere" }[tech_base]
      scope = scope.where.not(technology: excluded_tech) if excluded_tech

      tech_ids = Faction.for_tech_base(tech_base).pluck(:mul_id)
      faction_filter_ids = faction_filter_ids ? (faction_filter_ids & tech_ids) : tech_ids
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
end
