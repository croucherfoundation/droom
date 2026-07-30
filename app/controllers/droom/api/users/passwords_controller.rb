module Droom::Api
  class Users::PasswordsController < Devise::PasswordsController
    include Droom::Concerns::ApiResponseHelper
    include Droom::Concerns::LocaleDetection

    respond_to :json

    prepend_before_action :normalize_reset_password_token_param, only: [:confirm, :update_password]
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :require_no_authentication
    before_action :set_email, only: [:create]

    def create
      unless @primary_email&.can_receive_email?
        return render_api_error(errors: [t('notifications.authentication.password_reset_instructions_not_delivered')], status: :unprocessable_entity)
      end

      self.resource = resource_class.send_reset_password_instructions(reset_password_request_params)
      yield resource if block_given?
      render_api_success(message: t('notifications.authentication.password_reset_email_sent'))
    end

    def confirm
      self.resource = resource_class.find_by_reset_password_token(params[:reset_password_token])
      if resource.nil?
        render_api_error(errors: [t('notifications.authentication.invalid_reset_password_token')], status: :unprocessable_entity)
      else
        render_api_success(user: resource)
      end
    end

    def update_password
      self.resource = resource_class.find_by_reset_password_token(password_params[:reset_password_token])
      yield resource if block_given?

      return render_api_error(errors: [t('notifications.authentication.invalid_reset_password_token')], status: :unprocessable_entity) if resource.nil?
      if resource.update(password_params)
        sign_in(resource_name, resource)
        render_api_success(user: resource)
      else
        render_api_error(errors: resource.errors, status: :unprocessable_entity)
      end
    end


    private

    def normalize_reset_password_token_param
      return if params[:reset_password_token].present?

      token = params["amp;reset_password_token"].presence
      return unless token

      params[:reset_password_token] = token
      params.delete("amp;reset_password_token")
    end

    def reset_password_request_params
      {
        email: resource_params[:email],
        primary_email: @primary_email.email,
        destination: reset_password_destination
      }
    end

    def reset_password_destination
      params[:destination].presence ||
        params[:backto].presence ||
        params.dig(resource_name, :destination).presence ||
        params.dig(resource_name, :backto).presence
    end

    def password_params
      params.require(:user).permit(:password, :password_confirmation, :reset_password_token)
    end

    def set_email
      email_address = resource_params[:email]
      @email_record = Droom::Email.where(email: email_address).first
      if @email_record&.user.present?
        @primary_email = @email_record.user.emails.first
      end
    end

  end
end
