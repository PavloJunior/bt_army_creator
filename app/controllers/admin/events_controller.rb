module Admin
  class EventsController < BaseController
    before_action :set_event, only: [ :show, :edit, :update, :destroy, :activate, :complete ]

    def index
      @events = Event.order(date: :desc)
    end

    def show
      @army_lists = @event.army_lists.includes(:army_list_items).order(:created_at)
    end

    def new
      @event = Event.new
      @eras = Era.order(:sort_order)
      @factions = Faction.order(:name)
    end

    def create
      @event = Event.new(event_params)
      set_themed_point_cap
      if @event.save
        save_restrictions(@event)
        redirect_to admin_event_path(@event), notice: "Event created."
      else
        @eras = Era.order(:sort_order)
        @factions = Faction.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @eras = Era.order(:sort_order)
      @factions = Faction.order(:name)
    end

    def update
      @event.assign_attributes(event_params)
      set_themed_point_cap
      if @event.save
        save_restrictions(@event)
        redirect_to admin_event_path(@event), notice: "Event updated."
      else
        @eras = Era.order(:sort_order)
        @factions = Faction.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to admin_events_path, notice: "Event deleted."
    end

    def activate
      @event.update!(status: "active")
      redirect_to admin_event_path(@event), notice: "Event is now active."
    end

    def complete
      @event.update!(status: "completed")
      redirect_to admin_event_path(@event), notice: "Event completed."
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:name, :date, :game_system, :point_cap, :notes, :themed)
    end

    def set_themed_point_cap
      return unless @event.themed? && params[:sides].present?

      total = params[:sides].sum { |s| s[:point_cap].to_i }
      @event.point_cap = total if total > 0
    end

    def save_restrictions(event)
      # Era restrictions
      event.event_era_restrictions.destroy_all
      if params[:era_ids].present?
        params[:era_ids].each do |era_mul_id|
          era = Era.find_by(mul_id: era_mul_id)
          next unless era
          event.event_era_restrictions.create!(era_mul_id: era.mul_id, era_name: era.name)
        end
      end

      if event.themed?
        save_sides(event)
      else
        # Clear sides if switching from themed to non-themed
        event.event_sides.destroy_all if event.event_sides.any?

        # Faction restrictions
        event.event_faction_restrictions.destroy_all
        if params[:faction_ids].present?
          params[:faction_ids].each do |faction_mul_id|
            faction = Faction.find_by(mul_id: faction_mul_id)
            next unless faction
            event.event_faction_restrictions.create!(faction_mul_id: faction.mul_id, faction_name: faction.name)
          end
        end
      end
    end

    def save_sides(event)
      # Clear event-level faction restrictions when themed
      event.event_faction_restrictions.destroy_all

      sides_params = params[:sides] || []
      existing_side_ids = event.event_sides.pluck(:id)
      submitted_side_ids = sides_params.map { |s| s[:id]&.to_i }.compact

      # Destroy sides that are no longer present
      ids_to_destroy = existing_side_ids - submitted_side_ids
      event.event_sides.where(id: ids_to_destroy).destroy_all if ids_to_destroy.any?

      sides_params.each_with_index do |side_data, index|
        side = if side_data[:id].present?
          EventSide.find_by(id: side_data[:id], event_id: event.id)
        end

        cap_changed = false

        side_attrs = {
          name: side_data[:name],
          point_cap: side_data[:point_cap].to_i,
          max_players: side_data[:max_players].presence&.to_i,
          position: side_data[:position].presence&.to_i || (index + 1),
          allowed_tech_bases: Array(side_data[:allowed_tech_bases]).select(&:present?)
        }

        if side
          old_cap = side.point_cap
          side.update!(side_attrs)
          cap_changed = old_cap != side.point_cap
        else
          side = event.event_sides.create!(side_attrs)
        end

        # Update side factions
        side.event_side_factions.destroy_all
        faction_ids = side_data[:faction_ids] || []
        faction_ids.each do |faction_mul_id|
          faction = Faction.find_by(mul_id: faction_mul_id)
          next unless faction
          side.event_side_factions.create!(faction_mul_id: faction.mul_id, faction_name: faction.name)
        end

        # Recalculate caps if point_cap changed
        side.recalculate_caps! if cap_changed
      end

      # Update event point_cap as sum of side caps
      event.update_column(:point_cap, event.event_sides.reload.sum(:point_cap))
    end
  end
end
