module Droom::Api
  class Users::PasswordsController < Devise::PasswordsController
    respond_to :json

    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :require_no_authentication
    before_action :set_email, only: [:create]

    def create
      unless @email_record&.can_receive_email?
        return render json: { success: false, errors: [I18n.t(:password_reset_instructions_not_delivered)] }
      end

      self.resource = resource_class.send_reset_password_instructions(resource_params)
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

    def password_params
      params.require(:user).permit(:password, :password_confirmation, :reset_password_token)
    end

    def set_email
      email_address = resource_params[:email]
      @email_record = Droom::Email.where(email: email_address).first
    end

  end
end
