class EventsController < ApplicationController
  def index
    @upcoming_events = Event.upcoming.order(:date)
    @active_events = Event.active.order(:date)
  end

  def show
    @event = Event.find(params[:id])
    @submitted_lists = @event.army_lists.where(status: "submitted")
                             .includes(:army_list_items)
                             .order(:submitted_at)
  end
end
