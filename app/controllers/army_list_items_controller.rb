class ArmyListItemsController < ApplicationController
  include ArmyListOwnership

  before_action :set_event
  before_action :set_army_list
  before_action :authorize_army_list!
  before_action :require_draft_status!

  def create
    permitted = army_list_item_params
    chassis = Chassis.find(permitted[:chassis_id])

    used_ids = @army_list.army_list_items.pluck(:miniature_id)
    locked_ids = @event.miniature_locks.pluck(:miniature_id)
    miniature = chassis.miniatures_pool
      .where.not(id: used_ids + locked_ids)
      .order(:id).first

    if miniature.nil?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("toast",
            helpers.tag.div(
              helpers.tag.p("Brak dostępnych modeli dla #{chassis.name}"),
              class: "p-4 bg-hud-bg-panel border border-hud-red text-hud-red rounded text-sm shadow-lg shadow-hud-red-glow",
              data: { controller: "auto-dismiss", auto_dismiss_delay_value: "5000" }
            )
          )
        end
        format.html { redirect_to event_army_list_path(@event, @army_list), alert: "Brak dostępnych modeli dla #{chassis.name}" }
      end
      return
    end

    @item = @army_list.army_list_items.build(
      miniature: miniature,
      variant_id: permitted[:variant_id]
    )

    if @item.save
      @chassis = chassis
      compute_chassis_locals(@chassis)
      @over_cap = @item.exceeds_point_cap?

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to event_army_list_path(@event, @army_list) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("toast",
            helpers.tag.div(
              helpers.safe_join(@item.errors.full_messages.map { |msg| helpers.tag.p(msg) }),
              class: "p-4 bg-hud-bg-panel border border-hud-red text-hud-red rounded text-sm shadow-lg shadow-hud-red-glow",
              data: { controller: "auto-dismiss", auto_dismiss_delay_value: "5000" }
            )
          )
        end
        format.html { redirect_to event_army_list_path(@event, @army_list), alert: @item.errors.full_messages.join(", ") }
      end
    end
  end

  def update
    @item = @army_list.army_list_items.find(params[:id])

    if @item.update(skill_params)
      ensure_card_exists(@item)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to event_army_list_path(@event, @army_list) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@item),
            partial: "army_list_items/item",
            locals: { item: @item, event: @event, army_list: @army_list, is_owner: true }
          )
        end
        format.html { redirect_to event_army_list_path(@event, @army_list) }
      end
    end
  end

  def destroy
    @item = @army_list.army_list_items.find(params[:id])
    @chassis = @item.miniature.chassis
    @item.destroy

    compute_chassis_locals(@chassis)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to event_army_list_path(@event, @army_list) }
    end
  end

  private

  def compute_chassis_locals(chassis)
    used_ids = @army_list.army_list_items.reload.pluck(:miniature_id)
    locked_ids = @event.miniature_locks.pluck(:miniature_id)
    excluded_ids = used_ids + locked_ids
    @available_count = chassis.miniatures_pool.where.not(id: excluded_ids).count
    @total_count = chassis.miniatures_pool.count
    faction_filter = @army_list.army_list_factions.pluck(:faction_mul_id).presence
    @variants = @event.available_variants_for_chassis(chassis, tech_base: @army_list.tech_base, faction_mul_ids: faction_filter)
    @chassis = chassis

    @sibling_chassis_data = chassis.sibling_chassis.map do |sibling|
      sibling_variants = @event.available_variants_for_chassis(sibling, tech_base: @army_list.tech_base, faction_mul_ids: faction_filter)
      {
        chassis: sibling,
        available_count: @available_count,
        total_count: @total_count,
        variants: sibling_variants
      }
    end
  end

  def ensure_card_exists(item)
    card = VariantCard.find_by(variant: item.variant, skill: item.skill)
    return if card&.image&.attached?

    FetchVariantCardJob.perform_later(item.variant_id, skill: item.skill)
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_army_list
    @army_list = @event.army_lists.find(params[:army_list_id])
  end

  def army_list_item_params
    params.require(:army_list_item).permit(:chassis_id, :variant_id)
  end

  def skill_params
    params.require(:army_list_item).permit(:skill)
  end

  def require_draft_status!
    unless @army_list.draft?
      redirect_to event_army_list_path(@event, @army_list),
                  alert: "Nie można modyfikować zgłoszonej lub nieaktywnej listy."
    end
  end
end
