class EventSide < ApplicationRecord
  belongs_to :event
  has_many :event_side_factions, dependent: :destroy
  has_many :army_lists, dependent: :restrict_with_error

  validates :name, presence: true
  validates :point_cap, presence: true, numericality: { greater_than: 0 }
  validates :max_players, numericality: { greater_than: 0 }, allow_nil: true
  validates :position, presence: true

  def active_army_lists
    army_lists.where.not(status: "inactive")
  end

  def player_count
    active_army_lists.count
  end

  # Integer division intentionally floors — remainder points are lost (e.g., 300/7 = 42 each)
  def per_player_point_cap
    count = player_count
    count <= 1 ? point_cap : point_cap / count
  end

  def projected_per_player_point_cap
    point_cap / (player_count + 1)
  end

  def full?
    max_players.present? && player_count >= max_players
  end

  # Returns which tech bases are available for this side.
  # If admin set allowed_tech_bases, use that override.
  # Otherwise, auto-detect from actual variant data.
  # Returns which tech bases are available for this side.
  # If admin set allowed_tech_bases, use that override.
  # Otherwise, auto-detect from actual variant data.
  def available_tech_bases
    if allowed_tech_bases.present?
      allowed_tech_bases.select { |b| ArmyList::TECH_BASES.include?(b) }
    else
      detect_tech_bases
    end
  end

  def recalculate_caps!
    army_lists.where(status: "submitted").find_each(&:unlock!)
  end

  private

  # Auto-detects which tech bases have usable variants for this side's factions.
  # Side factions define the scope — the tech base only controls technology
  # exclusion (e.g., IS tech base excludes "Clan" technology).
  def detect_tech_bases
    side_faction_ids = event_side_factions.pluck(:faction_mul_id)
    return [] if side_faction_ids.empty?

    era_ids = event.event_era_restrictions.any? ? event.event_era_restrictions.pluck(:era_mul_id) : nil
    pv_column = Variant.arel_table[event.point_value_method]

    bases = []

    %w[inner_sphere clan].each do |tech_base|
      excluded_tech = { "inner_sphere" => "Clan", "clan" => "Inner Sphere" }[tech_base]

      scope = Variant.usable.joins(:variant_factions)
                     .where(pv_column.gt(0))
                     .where(variant_factions: { faction_id: side_faction_ids })
                     .where.not(technology: excluded_tech)
      scope = scope.where(era_id: era_ids) if era_ids

      bases << tech_base if scope.exists?
    end

    bases << "mixed" if bases.size > 1
    bases
  end
end
