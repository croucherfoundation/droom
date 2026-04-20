module Droom::Users
  class PasswordsController < Devise::PasswordsController
    respond_to :html, :json
    prepend_before_action :normalize_reset_password_token_param, only: [:edit, :update]
    before_action :set_access_control_headers
    skip_before_action :require_no_authentication, only: [:completed, :edit]
    before_action :remember_original_destination, only: [:new]
    before_action :remember_reset_password_destination, only: [:edit]
    before_action :clear_session, only: [:edit]
    before_action :set_email, only: [:create]
    layout 'droom/sign_in', only: [:edit]

    def show
      render
    end

    def completed
      flash.clear
      redirect_to root_path
    end

    def create
      return head :bad_request unless @email_record&.can_receive_email?

      self.resource = resource_class.send_reset_password_instructions(reset_password_request_params)
      yield resource if block_given?
      head :ok
    end

    def clear_session
      original_token       = params[:reset_password_token]
      reset_password_token = Devise.token_generator.digest(self, :reset_password_token, original_token)
      sign_out(resource_name)
      unless Droom::User.find_by_reset_password_token(reset_password_token)
        redirect_to droom.expired_reset_password_token_url
      end
    end

    def expired_reset_password_token

    end

    def after_resetting_password_path_for(resource)
      reset_password_destination || stored_location_for(:user) || droom.complete_confirmation_url
    end

    def after_sending_reset_password_instructions_path_for(resource_name)
      droom.show_confirmation_url
    end

    def remember_original_destination
      store_full_location_for(:user, params[:backto])
    end

    def remember_reset_password_destination
      store_full_location_for(:user, reset_password_destination)
    end


    # Bypass the usual store_location_for because we need to keep the full URI.
    #
    def store_full_location_for(resource_or_scope, location)
      session_key = stored_location_key_for(resource_or_scope)
      if location
        session[session_key] = location
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

    def set_email
      email_address = resource_params[:email]
      @email_record = Droom::Email.where(email: email_address).first
    end

  end
end
