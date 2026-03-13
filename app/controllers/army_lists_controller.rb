class ArmyListsController < ApplicationController
  include ArmyListOwnership

  before_action :set_event
  before_action :set_army_list, only: [ :show, :edit, :update, :submit ]
  before_action :authorize_army_list!, only: [ :edit, :update, :submit ]

  def new
    @army_list = @event.army_lists.build
  end

  def create
    @army_list = @event.army_lists.build(army_list_params)
    if @army_list.save
      store_army_list_in_cookie(@army_list)
      redirect_to event_army_list_path(@event, @army_list)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @items = @army_list.army_list_items.includes(miniature: :chassis, variant: [])

    used_ids = @army_list.army_list_items.pluck(:miniature_id)
    locked_ids = @event.miniature_locks.pluck(:miniature_id)
    excluded_ids = (used_ids + locked_ids).uniq

    all_minis_by_chassis = Miniature.includes(:chassis).group_by(&:chassis)
    @chassis_data = all_minis_by_chassis.map do |chassis, minis|
      available = minis.reject { |m| excluded_ids.include?(m.id) }
      [ chassis, available.size, minis.size ]
    end.sort_by { |c, _, _| c.name }

    @is_owner = owner_of_army_list?(@army_list) || admin_signed_in?
  end

  def edit
    redirect_to event_army_list_path(@event, @army_list)
  end

  def update
    if @army_list.update(army_list_params)
      redirect_to event_army_list_path(@event, @army_list)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def submit
    @army_list.submit!
    redirect_to event_army_list_path(@event, @army_list),
                notice: "Lista armijna zgłoszona! Twoje modele są zablokowane."
  rescue ArmyList::LockConflictError => e
    redirect_to event_army_list_path(@event, @army_list), alert: e.message
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_army_list
    @army_list = @event.army_lists.find(params[:id])
  end

  def army_list_params
    params.require(:army_list).permit(:player_name, :tech_base)
  end
end
