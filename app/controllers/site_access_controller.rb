class SiteAccessController < ApplicationController
  layout "lockscreen"

  def new
  end

  def create
    if site_password.present? && ActiveSupport::SecurityUtils.secure_compare(params[:password].to_s, site_password)
      grant_site_access!
      redirect_to session.delete(:return_to_after_site_access) || root_path
    else
      @error = true
      flash.now[:alert] = "ACCESS DENIED — INVALID CREDENTIALS"
      render :new, status: :unprocessable_entity
    end
  end
end
