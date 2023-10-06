module Droom::Users
  class SessionsController < Devise::SessionsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    before_action :payload_decode, only: [:sso_login]

    def new
      if @page = Droom::Page.published.find_by(slug: "_welcome")
        render template: "droom/pages/published", layout: Droom.page_layout
      else
        super
      end
    end

    def sso_login
      request_email = @decode_hash['email']
      if params[:sig] == @sig
        if current_user.present?
          if current_user.email == request_email
            redirect_to root_url
          else
            redirect_to new_user_session_url
          end
        else
          user = Droom::User.find_by(email: request_email)
          unless user.present?
            email = Droom::Email.joins("LEFT JOIN droom_users ON droom_emails.user_id = droom_users.id").where("droom_emails.email = ? AND droom_users.admin = true", request_email).order("droom_users.last_request_at DESC").limit(1)
            email.each do |email|
              user = Droom::User.find(email.user_id)
            end
          end
          
          if user.nil?
            redirect_to new_user_session_url
          else
            redirect_to root_url if sign_in user
          end
          
        end
      else
        redirect_to new_user_session_url
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

    private

    def payload_decode
      secret = ENV['HKFX_SSO_SECRET']
      decoded = Base64.decode64(params[:sso])
      @decode_hash = Rack::Utils.parse_query(decoded)
      payload = Base64.strict_encode64(decoded)
      @sig = OpenSSL::HMAC.hexdigest("sha256", secret, payload)
    end
  end
end