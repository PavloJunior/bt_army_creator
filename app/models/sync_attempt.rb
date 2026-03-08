class SyncAttempt < ApplicationRecord
  STATUSES = %w[running completed failed].freeze

  belongs_to :chassis

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :running, -> { where(status: "running") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }

  after_update_commit -> { broadcast_replace_to "sync_dashboard", target: "sync_attempt_#{id}", partial: "admin/sync_attempts/progress", locals: { sync_attempt: self } }

  def duration
    return nil unless started_at
    ((completed_at || Time.current) - started_at).round
  end

  def progress_text
    parts = []
    parts << "Factions: #{factions_synced}/#{factions_total}" if factions_total > 0
    parts << "Cards: #{cards_synced}/#{cards_total}" if cards_total > 0
    parts.join(" · ")
  end

  def check_completion!
    reload
    return unless status == "running"
    return if factions_total > 0 && factions_synced < factions_total
    return if cards_total > 0 && cards_synced < cards_total

    update!(status: "completed", completed_at: Time.current)
  end

  def fail!(message)
    append_error(message)
    update!(status: "failed", completed_at: Time.current)
  end

  def append_error(message)
    with_lock do
      reload
      self.error_messages = (error_messages || []) + [ message ]
      save!
    end
  end
end
