class ArmyListsController < ApplicationController
  include ArmyListOwnership

  before_action :set_event
  before_action :set_army_list, only: [ :show, :edit, :update, :submit, :change_tech_base, :toggle_faction, :clear, :print_cards, :print_cards_ready ]
  before_action :authorize_army_list!, only: [ :edit, :update, :submit, :change_tech_base, :toggle_faction, :clear ]

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
    @sidebar_factions = Faction.for_sidebar(@army_list.tech_base)
    @selected_faction_mul_ids = @army_list.army_list_factions.pluck(:faction_mul_id)
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

  def change_tech_base
    new_tech_base = params[:tech_base]
    if @army_list.draft? && new_tech_base != @army_list.tech_base && ArmyList::TECH_BASES.include?(new_tech_base)
      @army_list.transaction do
        @army_list.army_list_items.destroy_all
        @army_list.army_list_factions.destroy_all
        @army_list.update!(tech_base: new_tech_base)
      end
      redirect_to event_army_list_path(@event, @army_list),
                  notice: "Zmieniono frakcję na #{@army_list.tech_base_label}. Lista została zresetowana."
    else
      redirect_to event_army_list_path(@event, @army_list)
    end
  end

  def toggle_faction
    if params[:clear_all] == "true"
      @army_list.army_list_factions.destroy_all
      redirect_to event_army_list_path(@event, @army_list)
      return
    end

    faction_mul_id = params[:faction_mul_id].to_i
    existing = @army_list.army_list_factions.find_by(faction_mul_id: faction_mul_id)

    if existing
      @army_list.transaction do
        existing.destroy!
        remove_mismatched_items!
      end
    else
      @army_list.army_list_factions.create!(faction_mul_id: faction_mul_id)
    end

    redirect_to event_army_list_path(@event, @army_list)
  end

  def clear
    if @army_list.draft?
      @army_list.army_list_items.destroy_all
      redirect_to event_army_list_path(@event, @army_list),
                  notice: "Lista została wyczyszczona."
    else
      redirect_to event_army_list_path(@event, @army_list)
    end
  end

  def print_cards
    unless @army_list.submitted? && @event.game_system == "alpha_strike"
      redirect_to event_army_list_path(@event, @army_list),
                  alert: "Drukowanie kart dostępne tylko dla zgłoszonych list Alpha Strike."
      return
    end

    @items = @army_list.army_list_items.includes(variant: { variant_cards: :image_attachment })
    render layout: "print"
  end

  def print_cards_ready
    pending = @army_list.pending_cards_count
    render json: { ready: pending == 0, pending: pending }
  end

  def submit
    @army_list.submit!
    redirect_to event_army_list_path(@event, @army_list),
                notice: "Lista zgłoszona! Twoje modele zostały zarezerwowane."
  rescue ArmyList::LockConflictError, ArmyList::PointCapExceededError => e
    redirect_to event_army_list_path(@event, @army_list), alert: e.message
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_army_list
    @army_list = @event.army_lists.find(params[:id])
  end

  def remove_mismatched_items!
    remaining_faction_ids = @army_list.army_list_factions.reload.pluck(:faction_mul_id)
    return if remaining_faction_ids.empty?

    @army_list.army_list_items.includes(variant: :variant_factions).each do |item|
      item_faction_ids = item.variant.variant_factions.pluck(:faction_id)
      item.destroy! unless (item_faction_ids & remaining_faction_ids).any?
    end
  end

  def army_list_params
    params.require(:army_list).permit(:player_name, :tech_base)
  end
end
