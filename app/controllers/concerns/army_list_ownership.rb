module ArmyListOwnership
  extend ActiveSupport::Concern

  private

  def authorize_army_list!
    unless owner_of_army_list?(@army_list) || admin_signed_in?
      redirect_to event_path(@event), alert: "Nie masz dostępu do tej listy."
    end
  end

  def owner_of_army_list?(army_list)
    army_list_ids_from_cookie.include?(army_list.id)
  end

  def army_list_ids_from_cookie
    Array(cookies.signed[:army_list_ids])
  end

  def store_army_list_in_cookie(army_list)
    ids = army_list_ids_from_cookie
    ids << army_list.id unless ids.include?(army_list.id)
    cookies.signed[:army_list_ids] = {
      value: ids,
      expires: army_list.event.date + 1.day,
      httponly: true
    }
  end

  def admin_signed_in?
    Current.session.present?
  rescue
    false
  end
end
