class SharedArmyListParticipant < ApplicationRecord
  belongs_to :army_list
  has_many :authored_items,
           class_name: "ArmyListItem",
           foreign_key: :added_by_participant_id,
           dependent: :nullify
  has_many :messages,
           class_name: "SharedArmyListMessage",
           foreign_key: :participant_id,
           dependent: :nullify

  validates :display_name, presence: true, length: { maximum: 40 }
  validates :token, presence: true, uniqueness: true
  validate :display_name_unique_per_active_list

  before_validation :generate_token, on: :create

  scope :active, -> { where(left_at: nil) }

  after_commit :reset_other_acceptances_on_membership_change, on: [ :create, :update ]
  after_create_commit :broadcast_shared_roster_on_create
  after_update_commit :broadcast_shared_roster_on_update, if: :saved_change_to_left_at_or_accepted_at?

  def active?
    left_at.nil?
  end

  def accepted?
    accepted_at.present? && active?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  def unaccept!
    update_columns(accepted_at: nil)
  end

  def leave!
    transaction do
      update!(left_at: Time.current, accepted_at: nil)
      # Grab ids before nullifying — after update_all the scope returns nothing.
      detached_item_ids = authored_items.pluck(:id)
      authored_items.update_all(added_by_participant_id: nil)
      broadcast_detached_items(detached_item_ids) if detached_item_ids.any?
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(24)
  end

  def display_name_unique_per_active_list
    return if display_name.blank? || army_list_id.blank?

    scope = SharedArmyListParticipant
      .where(army_list_id: army_list_id, left_at: nil)
      .where("LOWER(display_name) = ?", display_name.downcase)
    scope = scope.where.not(id: id) if persisted?

    if scope.exists?
      errors.add(:display_name, "is already taken on this shared list")
    end
  end

  def reset_other_acceptances_on_membership_change
    # Clear others' acceptances only when the active set changes:
    # - a new participant joins (create), or
    # - an existing participant leaves (left_at just flipped).
    return unless saved_change_to_id? || saved_change_to_left_at?

    army_list.active_participants
             .where.not(id: id)
             .update_all(accepted_at: nil)
  end

  def saved_change_to_left_at_or_accepted_at?
    saved_change_to_left_at? || saved_change_to_accepted_at?
  end

  def shared_stream
    "shared_army_list_#{army_list_id}"
  end

  def broadcast_shared_roster_on_create
    broadcast_shared_roster
  end

  def broadcast_shared_roster_on_update
    broadcast_shared_roster
  end

  def broadcast_shared_roster
    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: "shared_participant_roster",
      partial: "shared_army_lists/participant_roster",
      locals: { army_list: army_list, event: army_list.event }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: "shared_acceptance_banner",
      partial: "shared_army_lists/acceptance_banner",
      locals: { army_list: army_list, event: army_list.event }
    )
  end

  # leave! nullifies added_by_participant_id via update_all, which skips
  # callbacks. Re-broadcast each affected item so other viewers' attribution
  # badges drop the departed participant's name instead of showing it until
  # the next list mutation.
  def broadcast_detached_items(item_ids)
    ArmyListItem
      .where(id: item_ids)
      .includes(:miniature, :variant, army_list: :event)
      .each do |item|
        Turbo::StreamsChannel.broadcast_replace_to(
          shared_stream,
          target: ActionView::RecordIdentifier.dom_id(item),
          partial: "army_list_items/item",
          locals: {
            item: item,
            event: item.army_list.event,
            army_list: item.army_list,
            is_owner: true
          }
        )
      end
  end
end
