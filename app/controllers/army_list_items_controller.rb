class ArmyListItemsController < ApplicationController
  include ArmyListOwnership

  before_action :set_event
  before_action :set_army_list
  before_action :authorize_army_list!

  def create
    @item = @army_list.army_list_items.build(army_list_item_params)

    if @item.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to event_army_list_path(@event, @army_list) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "add_unit_errors",
            partial: "army_list_items/errors",
            locals: { errors: @item.errors.full_messages }
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
    @miniature = @item.miniature
    @item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to event_army_list_path(@event, @army_list) }
    end
  end

  private

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
    params.require(:army_list_item).permit(:miniature_id, :variant_id)
  end

  def skill_params
    params.require(:army_list_item).permit(:skill)
  end
end
