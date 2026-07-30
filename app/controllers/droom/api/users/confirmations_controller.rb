module Droom::Api
  class Users::ConfirmationsController < Devise::ConfirmationsController
    include Droom::Concerns::ApiResponseHelper
    include Droom::Concerns::LocaleDetection

    skip_before_action :verify_authenticity_token, raise: false
    respond_to :json
    def show
      @resource = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if @resource.errors.empty?
        @resource.confirm_attendee
        Droom::SubscribeToMailchimpJob.perform_later(@resource.email, @resource.given_name, @resource.family_name) if Rails.env.production?
        user = sign_in(@resource)
        user_data = get_auth_cookie_for(user)
        render_api_success(user: @resource, user_data: user_data.as_json, message: t('notifications.authentication.email_confirmed'), status: :ok)
      else
        render_api_error(errors: @resource.errors, status: :unprocessable_entity, user: @resource, message: @resource.errors.full_messages, user_data: nil)
      end
    end

    def create
      @resource = Droom::Email.find_by(email: params[:email]).try(:user)
      return render_api_error(errors: [t('notifications.authentication.user_not_found')], message: [t('notifications.authentication.user_not_found')], status: :not_found) unless @resource

      if @resource
        if @resource.confirmed?
          return render_api_error(errors: [t('notifications.authentication.user_already_confirmed')], message: [t('notifications.authentication.user_already_confirmed')], status: :unprocessable_entity)
        end
        send_confirmation_instructions(@resource)
        render_api_success(message: t('notifications.authentication.confirmation_email_sent'), status: :ok)
      else
        render_api_error(errors: @resource.errors, message: @resource.errors.full_messages, status: :unprocessable_entity)
      end
    end

    private

    def send_confirmation_instructions(resource)
      generate_confirmation_token!(resource)
      Droom::Mailer.confirmation_instructions(resource, resource.confirmation_token).deliver_later
    end

    def generate_confirmation_token!(resource)
      resource.confirmation_token = resource.generate_authentication_token
      resource.confirmation_sent_at = Time.current
      resource.save(validate: false)
    end

    def get_auth_cookie_for(user)
      return nil if user.nil?
    
      RequestStore.store[:current_user] = user
      Droom::AuthCookie.new(cookies).set(user)
    
      cookie_name = ENV['DROOM_AUTH_COOKIE'] || Settings.auth.cookie_name
      sign_in_cookie = cookies[cookie_name]
    
      return nil unless sign_in_cookie
    
      parsed_cookie = JSON.parse(sign_in_cookie)
      {
        _s: parsed_cookie[0],
        _k: parsed_cookie[1][0],
        _d: parsed_cookie[1][1]
      }
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse sign-in cookie: #{e.message}"
      nil
    end
  end
end