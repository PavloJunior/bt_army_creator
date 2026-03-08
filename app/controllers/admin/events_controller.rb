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
      if @event.update(event_params)
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
      params.require(:event).permit(:name, :date, :game_system, :point_cap, :notes)
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
end
