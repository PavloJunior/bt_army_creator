module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :visitor_id

    def connect
      self.visitor_id = find_or_create_visitor_id
    end

    private

    def find_or_create_visitor_id
      # Allow both authenticated admin and anonymous players
      if session = Session.find_by(id: cookies.signed[:session_id])
        "user_#{session.user_id}"
      else
        # Anonymous visitor — use a random ID stored in cookies
        cookies.signed[:visitor_id] ||= SecureRandom.hex(16)
        "visitor_#{cookies.signed[:visitor_id]}"
      end
    end
  end
end
