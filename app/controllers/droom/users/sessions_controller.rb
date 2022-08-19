module Droom::Users
  class SessionsController < Devise::SessionsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false

    def new
      if @page = Droom::Page.published.find_by(slug: "_welcome")
        render template: "droom/pages/published", layout: Droom.page_layout
      else
        super
      end
    end

    def create
      session['user_return_to'] = '/' if session['user_return_to'] == '/users/sign_in'
      super
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
