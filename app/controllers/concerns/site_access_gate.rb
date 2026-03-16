module SiteAccessGate
  extend ActiveSupport::Concern

  included do
    before_action :require_site_access
  end

  private

  def require_site_access
    return if site_password.blank?
    return if controller_path.start_with?("admin/")
    return if controller_path == "site_access"
    return if valid_site_access_cookie?

    session[:return_to_after_site_access] = request.fullpath
    redirect_to site_access_path
  end

  def valid_site_access_cookie?
    cookie_value = cookies.signed[:site_access_granted]
    return false if cookie_value.blank?

    ActiveSupport::SecurityUtils.secure_compare(cookie_value, site_password_digest)
  end

  def grant_site_access!
    cookies.signed[:site_access_granted] = {
      value: site_password_digest,
      expires: 30.days.from_now,
      httponly: true,
      same_site: :lax
    }
  end

  def site_password
    ENV["SITE_PASSWORD"]
  end

  def site_password_digest
    Digest::SHA256.hexdigest(site_password)
  end
end
