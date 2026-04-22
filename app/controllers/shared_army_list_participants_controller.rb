class SharedArmyListParticipantsController < ApplicationController
  include SharedParticipantAuth

  before_action :set_event
  before_action :ensure_shared_event!
  before_action :set_army_list
  before_action :set_participant, only: [ :accept, :unaccept, :leave ]
  before_action :require_own_participant!, only: [ :accept, :unaccept, :leave ]

  def create
    if current_participant(@army_list)
      redirect_to event_army_list_path(@event, @army_list) and return
    end

    @participant = @army_list.shared_participants.build(participant_params)

    if @participant.save
      store_participant_token(@participant)
      redirect_to event_army_list_path(@event, @army_list),
                  notice: "Dołączono jako #{@participant.display_name}."
    else
      render plain: @participant.errors.full_messages.join(", "),
             status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # A concurrent join won the race on the (army_list_id, LOWER(display_name))
    # unique index before our validation could catch it.
    redirect_to event_path(@event),
                alert: "Ten pseudonim jest już zajęty. Wybierz inny."
  end

  def accept
    @participant.accept!
    respond_to_acceptance_change
  end

  def unaccept
    @participant.unaccept!
    respond_to_acceptance_change
  end

  def leave
    @participant.leave!
    remove_participant_token(@participant)
    redirect_to event_path(@event), notice: "Opuściłeś wspólną listę."
  end

  private

  def respond_to_acceptance_change
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "shared_self_acceptance_button",
            partial: "shared_army_lists/self_acceptance_button",
            locals: { army_list: @army_list, event: @event, current_participant: @participant }
          ),
          turbo_stream.replace(
            "army_list_actions",
            partial: "army_lists/actions",
            locals: { army_list: @army_list, event: @event, is_owner: true }
          )
        ]
      end
      format.html { redirect_to event_army_list_path(@event, @army_list) }
    end
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  def ensure_shared_event!
    unless @event.shared_army_list?
      redirect_to event_path(@event),
                  alert: "To wydarzenie nie używa wspólnej listy."
    end
  end

  def set_army_list
    @army_list = @event.shared_army_list_record
    unless @army_list
      redirect_to event_path(@event),
                  alert: "Wspólna lista nie istnieje."
    end
  end

  def set_participant
    @participant = @army_list.shared_participants.find(params[:id])
  end

  def require_own_participant!
    return if admin_signed_in?

    viewer = current_participant(@army_list)
    unless viewer && viewer.id == @participant.id
      head :forbidden
    end
  end

  def participant_params
    params.require(:shared_army_list_participant).permit(:display_name)
  end
end
