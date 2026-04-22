class Event < ApplicationRecord
  # Virtual attribute — admin supplies the tech base for the auto-created
  # shared army list via the event form. Persisted on the ArmyList, not on Event.
  attr_accessor :shared_tech_base

  has_many :event_era_restrictions, dependent: :destroy
  has_many :event_faction_restrictions, dependent: :destroy
  # army_lists must be destroyed BEFORE event_sides — EventSide has
  # `dependent: :restrict_with_error` on its army_lists association (to block
  # side deletion while lists reference it). Without this order, destroying a
  # themed event silently fails when sides still have attached lists.
  has_many :army_lists, dependent: :destroy
  has_many :event_sides, -> { order(:position) }, dependent: :destroy
  has_many :miniature_locks, dependent: :destroy

  validates :name, presence: true
  validates :game_system, presence: true, inclusion: { in: %w[classic_bt alpha_strike] }
  validates :point_cap, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[upcoming active completed] }
  validate :themed_must_have_sides
  validate :shared_and_themed_are_mutually_exclusive
  validate :shared_tech_base_is_valid_when_shared
  validate :shared_tech_base_change_requires_empty_draft_list

  after_create :create_shared_army_list_if_needed
  after_update :sync_shared_army_list_tech_base

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
    side_faction_ids = event_side&.event_side_factions&.pluck(:faction_mul_id)
    side_has_factions = side_faction_ids.present?

    if side_has_factions
      faction_filter_ids = side_faction_ids
    elsif event_faction_restrictions.any?
      faction_filter_ids = event_faction_restrictions.pluck(:faction_mul_id)
    end

    if tech_base.present? && tech_base != "mixed"
      excluded_tech = { "inner_sphere" => "Clan", "clan" => "Inner Sphere" }[tech_base]
      scope = scope.where.not(technology: excluded_tech) if excluded_tech

      # For themed events, side factions define the scope — don't further
      # restrict by tech-base faction mapping (a Clan faction can field IS-tech units).
      # An unrestricted side (no event_side_factions) falls through to the tech-base mapping.
      unless side_has_factions
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

  def shared_army_list_record
    return nil unless shared_army_list?
    army_lists.order(:id).first
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

  def shared_and_themed_are_mutually_exclusive
    if shared_army_list? && themed?
      errors.add(:base, "An event cannot be both shared and themed")
    end
  end

  def shared_tech_base_is_valid_when_shared
    return unless shared_army_list?
    # On create the virtual attr must be set to a valid value. On update it's
    # optional — nil means "don't touch the list's tech_base".
    return if shared_tech_base.blank? && persisted?

    unless ArmyList::TECH_BASES.include?(shared_tech_base)
      errors.add(:shared_tech_base, "must be one of #{ArmyList::TECH_BASES.join(', ')}")
    end
  end

  def create_shared_army_list_if_needed
    return unless shared_army_list?

    army_lists.create!(
      player_name: "Shared Force — #{name}",
      status: "draft",
      tech_base: shared_tech_base.presence || "mixed"
    )
  end

  def shared_tech_base_change_requires_empty_draft_list
    return unless persisted? && shared_army_list?
    return if shared_tech_base.blank?

    list = shared_army_list_record
    return unless list
    return if shared_tech_base == list.tech_base

    if list.status != "draft"
      errors.add(:shared_tech_base, "cannot be changed once the shared list has been submitted")
    elsif list.army_list_items.exists?
      errors.add(:shared_tech_base, "cannot be changed while the shared list contains units")
    end
  end

  def sync_shared_army_list_tech_base
    return unless shared_army_list?
    return if shared_tech_base.blank?

    list = shared_army_list_record
    return unless list && list.status == "draft" && shared_tech_base != list.tech_base

    # with_lock guards against a participant adding an item between our
    # validation pass and the update. The empty? recheck inside the lock keeps
    # the write safe even though the validation already rejected the non-empty
    # case for the user-facing path.
    list.with_lock do
      next unless list.army_list_items.empty?
      list.update!(tech_base: shared_tech_base)
    end
  end
end
