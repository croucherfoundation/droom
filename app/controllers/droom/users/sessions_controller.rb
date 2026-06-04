require 'droom/auth_cookie'

module Droom::Users
  class SessionsController < Devise::SessionsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    layout 'droom/sign_in'

    def new
      # Devise stores the location in session via store_location_for during authenticate_user!
      # Capture it and store in cookie to preserve across session resets
      stored_location = session[:user_return_to]

      if stored_location.present? && stored_location != "/" && stored_location != request.url
        cookies[:return_to] = stored_location
      elsif request.referrer.present? && request.referrer != request.url
        referred_path = URI.parse(request.referrer).path
        # Don't store if it's already a sign-in/out page
        unless referred_path.match?(%r{/users/(sign_in|sign_out|password)})
          cookies[:return_to] = referred_path
        end
      end

      cookie = Droom::AuthCookie.new(cookies)
      @not_confirmed_message = "We haven't received your confirmation. Please check your email." if params[:not_confirmed]
      @unlock_message = "Your account is unlocked. Please sign in." if params[:locked]
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
        # flag_backup_email_sign_in(resource)

        # Redirect to the originally requested page, or use fallback
        redirect_path = determine_redirect_path
        redirect_to redirect_path
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

    def determine_redirect_path
      # Priority order for redirect destination
      # 1. Check params[:backto] first (from hidden field in form)
      if params[:backto].present?
        path = CGI.unescape(params[:backto])
        cookies.delete(:return_to)  # Clean up the cookie
        return path if path != '/'
      end

      # 2. Check cookies[:return_to] (stored before sign-in redirect)
      if cookies[:return_to].present?
        path = cookies.delete(:return_to)
        return path if path != '/'
      end

      # 3. Fall back to default sign-in path
      after_sign_in_path_for(resource)
    end

    def all_signed_out?
      !user_signed_in?
    end

    private

    def flag_backup_email_sign_in(user)
      submitted = params.dig(resource_name, :email).to_s.strip.downcase
      primary = user.try(:primary_email).to_s.strip.downcase
      if submitted.present? && primary.present? && submitted != primary
        session[:show_backup_email_banner] = true
      else
        session.delete(:show_backup_email_banner)
      end
    end
  end
end
