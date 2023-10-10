module Droom::Users
  class SessionsController < Devise::SessionsController
    respond_to :html, :json
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token
    before_action :payload_decode, only: [:sso_login]

    def stored_location_for(resource_or_scope)
      if params[:backto]
        CGI.unescape(params[:backto])
      else
        super
      end
    end


    def sso_login
      request_email = @decode_hash['email']
      sso_user = Droom::User.find_by(external_id: @decode_hash['external_id'])

      if params[:sig] == @sig && @decode_hash['admin'] 
        if sso_user
          redirect_to dashboard_url if sign_in sso_user
        else
          if current_user.present?
            if current_user.email == request_email
              current_user.external_id = @decode_hash['external_id']
              current_user.save(validate: false)
              redirect_to dashboard_url
            else
              redirect_to new_user_session_url
            end
          else
            user = Droom::User.find_by(email: request_email)
            unless user.present?
              email = Droom::Email.joins("LEFT JOIN droom_users ON droom_emails.user_id = droom_users.id").where("droom_emails.email = ? AND droom_users.admin = true", request_email).order("droom_emails.id DESC").limit(1)
              email.each do |email|
                user = Droom::User.find(email.user_id)
              end
            end
            
            if user.nil?
              set_sso_user
              redirect_to dashboard_url if sign_in @user
            else
              user.external_id = @decode_hash['external_id']
              user.save(validate: false)
              redirect_to dashboard_url if sign_in user
            end
            
          end
        end
      else
        redirect_to new_user_session_url
      end
    end

    private

    def payload_decode
      secret = ENV['SSO_SECRET']
      decoded = Base64.decode64(params[:sso])
      @decode_hash = Rack::Utils.parse_query(decoded)
      payload = Base64.strict_encode64(decoded)
      @sig = OpenSSL::HMAC.hexdigest("sha256", secret, payload)
    end

    def set_sso_user
      @user = Droom::User.new(given_name: @decode_hash['given_name'], family_name: @decode_hash['family_name'], email: @decode_hash['email'], external_id: @decode_hash['external_id'], admin: true, organisation_id: 146 ,password: SecureRandom.hex(8))
      @user.title = @decode_hash['title'] if @decode_hash['title']
      @user.chinese_name = @decode_hash['chinese_name'] if @decode_hash['chinese_name']
      @user.skip_confirmation!
      @user.save(validate: false)
    end

  end
end