require 'droom/auth_cookie'

module Droom::Users
  class SessionsController < Devise::SessionsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false

    def new
      cookie = Droom::AuthCookie.new(cookies)
      if cookie.valid? && cookie.fresh?
        @user = Droom::User.find_by(unique_session_id: cookie.token)
        sign_in(@user)
        redirect_to '/'
      else
        if @page = Droom::Page.published.find_by(slug: "_welcome")
          render template: "droom/pages/published", layout: Droom.page_layout
        else
          super
        end
      end
    end

    def stored_location_for(resource_or_scope)
      if params[:backto]
        CGI.unescape(params[:backto])
      else
        super
      end
    end

    def all_signed_out?
      !user_signed_in?
    end

  end
end
