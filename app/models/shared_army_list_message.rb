class SharedArmyListMessage < ApplicationRecord
  belongs_to :army_list
  belongs_to :participant,
             class_name: "SharedArmyListParticipant",
             optional: true

  validates :body, length: { maximum: 2000 }
  validates :body, presence: true, unless: :deleted?
  validates :sender_name, presence: true

  scope :visible, -> { where(deleted_at: nil).order(:created_at) }

  after_create_commit :broadcast_chat_append
  after_update_commit :broadcast_chat_replace, if: :saved_change_to_deleted_at?

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current, body: "")
  end

  private

  def shared_stream
    "shared_army_list_#{army_list_id}"
  end

  def broadcast_chat_append
    Turbo::StreamsChannel.broadcast_append_to(
      shared_stream,
      target: "shared_chat_messages",
      partial: "shared_army_list_messages/message",
      locals: { message: self, event: army_list.event }
    )
  end

  def broadcast_chat_replace
    Turbo::StreamsChannel.broadcast_replace_to(
      shared_stream,
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "shared_army_list_messages/message",
      locals: { message: self, event: army_list.event }
    )
  end
end
