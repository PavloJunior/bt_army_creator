module SharedParticipantAuth
  extend ActiveSupport::Concern

  MAX_STORED_TOKENS = 30

  private

  def current_participant(army_list)
    return @current_participant_cache[army_list.id] if defined?(@current_participant_cache) && @current_participant_cache.key?(army_list.id)

    @current_participant_cache ||= {}

    tokens = shared_participant_tokens_from_cookie
    return @current_participant_cache[army_list.id] = nil if tokens.empty?

    @current_participant_cache[army_list.id] =
      army_list.shared_participants.active.where(token: tokens).first
  end

  def require_participant!
    return if current_participant(@army_list).present?
    return if admin_signed_in?

    redirect_to event_path(@event),
                alert: "Dołącz do listy, aby móc ją edytować."
  end

  def shared_participant_tokens_from_cookie
    Array(cookies.signed[:shared_participant_tokens])
  end

  def store_participant_token(participant)
    tokens = shared_participant_tokens_from_cookie
    tokens << participant.token unless tokens.include?(participant.token)
    tokens = tokens.last(MAX_STORED_TOKENS)

    cookies.signed[:shared_participant_tokens] = {
      value: tokens,
      expires: max_expiry_for_tokens(tokens, include_participant: participant),
      httponly: true
    }
  end

  def remove_participant_token(participant)
    tokens = shared_participant_tokens_from_cookie - [ participant.token ]

    if tokens.empty?
      cookies.delete(:shared_participant_tokens)
    else
      cookies.signed[:shared_participant_tokens] = {
        value: tokens,
        expires: max_expiry_for_tokens(tokens),
        httponly: true
      }
    end
  end

  # Expiry must be the latest event-date across every token in the cookie —
  # otherwise adding a ticket for an earlier-dated event would shorten the
  # cookie and invalidate tokens for later events.
  def max_expiry_for_tokens(tokens, include_participant: nil)
    participants = SharedArmyListParticipant
                     .where(token: tokens)
                     .includes(army_list: :event)
                     .to_a
    participants << include_participant if include_participant && participants.none? { |p| p.id == include_participant.id }

    expiries = participants.filter_map { |p| participant_expiry(p) }
    expiries.max || 1.day.from_now.end_of_day
  end

  def participant_expiry(participant)
    event = participant&.army_list&.event
    return nil unless event&.date
    (event.date + 1.day).end_of_day
  end

  def admin_signed_in?
    Current.session.present?
  rescue
    false
  end
end
