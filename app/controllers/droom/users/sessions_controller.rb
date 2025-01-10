require 'droom/auth_cookie'

module Droom::Users
  class SessionsController < Devise::SessionsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    layout 'droom/sign_in'

    def new
      cookie = Droom::AuthCookie.new(cookies)
      @not_confirmed_message = "We haven't received your confirmation. Please check your email." if params[:not_confirmed]
      if cookie.valid? && cookie.fresh? && session['warden.user.user.key'].present?
        @user = Droom::User.find_by(unique_session_id: cookie.token)
        sign_in(@user)
        session['flash']['flashes']['alert'] = 'You are already signed in!' if session['flash'] && session['flash']['flashes']
        redirect_to '/'
      else
        current_user.clear_session_ids! if current_user
        Droom::AuthCookie.new(warden.cookies).unset
        if @page = Droom::Page.published.find_by(slug: "_welcome")
          render template: "droom/pages/published", layout: Droom.page_layout
        else
          super
        end
      end
    end

    def create
      if self.resource = warden.authenticate(auth_options)
        if resource.respond_to?(:confirmed?) && !resource.confirmed?
          Rails.logger.info "User #{resource.email} not confirmed"
          current_user.clear_session_ids! if current_user
          Droom::AuthCookie.new(warden.cookies).unset
          redirect_to new_user_session_url(not_confirmed: true)
          return
        end
        sign_in(resource_name, resource)
        if !session[:return_to].blank?
          redirect_to session[:return_to]
          session[:return_to] = nil
        else
          respond_with resource, :location => after_sign_in_path_for(resource)
        end

      else
        redirect_to new_user_session_url(failed: true)
      end
    end

    def destroy
      current_user.clear_session_ids! if current_user
      Droom::AuthCookie.new(warden.cookies).unset
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
