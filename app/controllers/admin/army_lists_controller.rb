module Admin
  class ArmyListsController < BaseController
    before_action :set_event
    before_action :set_army_list, only: [ :show, :update, :destroy, :submit, :unlock, :deactivate, :reactivate ]

    def index
      @army_lists = @event.army_lists.order(:created_at)
    end

    def show
      @items = @army_list.army_list_items.includes(miniature: :chassis, variant: [])
    end

    def update
      if @army_list.update(army_list_params)
        redirect_to admin_event_army_list_path(@event, @army_list), notice: "Army list updated."
      else
        redirect_to admin_event_army_list_path(@event, @army_list), alert: @army_list.errors.full_messages.join(", ")
      end
    end

    def destroy
      @army_list.destroy
      redirect_to admin_event_path(@event), notice: "Army list deleted."
    end

    def submit
      @army_list.submit!
      redirect_to admin_event_path(@event), notice: "Army list submitted. Miniatures are now locked."
    rescue ArmyList::LockConflictError, ArmyList::PointCapExceededError => e
      redirect_to admin_event_path(@event), alert: e.message
    end

    def unlock
      @army_list.unlock!
      redirect_to admin_event_path(@event), notice: "Army list unlocked. Miniatures are available again."
    end

    def deactivate
      @army_list.deactivate!
      redirect_to admin_event_path(@event), notice: "Army list deactivated. Miniatures are available again."
    end

    def reactivate
      @army_list.reactivate!
      redirect_to admin_event_path(@event), notice: "Army list reactivated. Miniatures are locked again."
    rescue ArmyList::LockConflictError => e
      redirect_to admin_event_path(@event), alert: e.message
    end

    private

    def set_event
      @event = Event.find(params[:event_id])
    end

    def set_army_list
      @army_list = @event.army_lists.find(params[:id])
    end

    def army_list_params
      params.require(:army_list).permit(:bonus_points)
    end
  end
end
