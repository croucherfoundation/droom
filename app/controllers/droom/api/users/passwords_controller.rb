module Droom::Api
  class Users::PasswordsController < Devise::PasswordsController
    respond_to :json

    prepend_before_action :normalize_reset_password_token_param, only: [:confirm, :update_password]
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :require_no_authentication
    before_action :set_email, only: [:create]

    def create
      unless @email_record&.can_receive_email?
        return render json: { success: false, errors: [I18n.t(:password_reset_instructions_not_delivered)] }
      end

      self.resource = resource_class.send_reset_password_instructions(reset_password_request_params)
      yield resource if block_given?
      render json: { success: true, message: "If the email exists, a password reset email has been sent." }
    end

    def confirm
      self.resource = resource_class.find_by_reset_password_token(params[:reset_password_token])
      if resource.nil?
        render json: { success: false, errors: ["Invalid reset password token"] }
      else
        render json: { user: resource, success: true }
      end
    end

    def update_password
      self.resource = resource_class.find_by_reset_password_token(password_params[:reset_password_token])
      yield resource if block_given?

      return render json: { success: false, errors: ["Invalid reset password token"] } if resource.nil?
      if resource.update(password_params)
        sign_in(resource_name, resource)
        render json: { user: resource, success: true }
      else
        render json: { success: false, errors: resource.errors.full_messages }
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
    end

  end
end
