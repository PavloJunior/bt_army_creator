module Admin
  class SyncAttemptsController < BaseController
    def index
      @chassis_with_syncs = Chassis.order(:name)
        .includes(:variants, :sync_attempts)

      @latest_attempts = SyncAttempt
        .where("id IN (SELECT MAX(id) FROM sync_attempts GROUP BY chassis_id)")
        .index_by(&:chassis_id)

      @recent_attempts_by_chassis = SyncAttempt
        .where(chassis_id: @chassis_with_syncs.map(&:id))
        .order(created_at: :desc)
        .group_by(&:chassis_id)
        .transform_values { |attempts| attempts.first(5) }

      @active_syncs_count = SyncAttempt.running.count
      @last_completed = SyncAttempt.completed.order(completed_at: :desc).first
      @total_chassis = Chassis.count
    end

    def show
      @sync_attempt = SyncAttempt.find(params[:id])
      @chassis = @sync_attempt.chassis
      @recent_attempts = @chassis.sync_attempts.order(created_at: :desc).limit(10)
    end
  end
end
