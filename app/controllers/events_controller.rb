class EventsController < ApplicationController
  include ArmyListOwnership
  include SharedParticipantAuth

  def index
    @upcoming_events = Event.upcoming.order(:date)
    @active_events = Event.active.order(:date)
    @my_draft_event_ids = my_draft_event_ids
  end

  def show
    @event = Event.find(params[:id])
    @submitted_lists = @event.army_lists.where(status: "submitted")
                             .includes(:army_list_items, :event_side)
                             .order(:submitted_at)
    @my_drafts = @event.army_lists.where(id: army_list_ids_from_cookie, status: "draft")
                       .includes(:army_list_items, :event_side)
    @my_inactive = @event.army_lists.where(id: army_list_ids_from_cookie, status: "inactive")
                         .includes(:army_list_items, :event_side)

    if @event.themed?
      @event_sides = @event.event_sides.includes(:event_side_factions)
      @submitted_by_side = @submitted_lists.group_by(&:event_side_id)
    end

    if @event.shared_army_list?
      @shared_army_list = @event.shared_army_list_record
      @shared_current_participant = current_participant(@shared_army_list) if @shared_army_list
    end
  end

  private

  def my_draft_event_ids
    ids = army_list_ids_from_cookie
    return Set.new if ids.empty?
    ArmyList.where(id: ids, status: "draft").distinct.pluck(:event_id).to_set
  end
end
