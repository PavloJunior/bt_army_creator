module Admin
  class BaseController < ApplicationController
    before_action :require_authentication
    layout "admin"

    private

    def after_authentication_url
      admin_root_url
    end
  end
end
