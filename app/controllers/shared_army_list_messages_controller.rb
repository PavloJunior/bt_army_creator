class SharedArmyListMessagesController < ApplicationController
  include SharedParticipantAuth

  before_action :set_event
  before_action :ensure_shared_event!
  before_action :set_army_list
  before_action :require_participant_or_admin!
  before_action :set_message, only: [ :destroy ]

  def create
    sender = current_participant(@army_list)
    @message = @army_list.shared_messages.build(message_params)
    @message.participant = sender
    @message.sender_name = sender&.display_name || "Admin"

    # The model's after_create_commit broadcasts the new message to every
    # subscriber (including the sender). The controller's job is just to clear
    # the sender's form on success, or re-render it with an inline error.
    if @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "shared_chat_form",
            partial: "shared_army_list_messages/form",
            locals: { event: @event, current_participant: sender }
          )
        end
        format.html { head :no_content }
      end
    else
      error_text = @message.errors.full_messages.to_sentence
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "shared_chat_form",
            partial: "shared_army_list_messages/form",
            locals: { event: @event, current_participant: sender, error: error_text }
          ), status: :unprocessable_entity
        end
        format.html { head :unprocessable_entity }
      end
    end
  end

  def destroy
    unless can_delete_message?(@message)
      head :forbidden and return
    end

    @message.soft_delete!
    # 2xx with no body: Turbo treats 204 as "do nothing" (the model's broadcast
    # updates every viewer including the deleter). Plain HTTP clients just get
    # a 200.
    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html { head :ok }
    end
  end

  private

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

  def set_message
    @message = @army_list.shared_messages.find(params[:id])
  end

  def require_participant_or_admin!
    return if admin_signed_in?
    return if current_participant(@army_list)

    head :forbidden
  end

  def can_delete_message?(message)
    return true if admin_signed_in?
    viewer = current_participant(@army_list)
    viewer && message.participant_id == viewer.id
  end

  def message_params
    params.require(:shared_army_list_message).permit(:body)
  end
end
