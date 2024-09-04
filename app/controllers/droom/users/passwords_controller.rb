module Droom::Users
  class PasswordsController < Devise::PasswordsController
    respond_to :html, :json
    before_action :set_access_control_headers
    skip_before_action :require_no_authentication, only: [:completed, :edit]
    before_action :remember_original_destination, only: [:new]
    before_action :clear_session, only: [:edit]

    def show
      render
    end

    def completed
      render
    end

    def create
      self.resource = resource_class.send_reset_password_instructions(resource_params)
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
      droom.complete_confirmation_url
    end

    def after_sending_reset_password_instructions_path_for(resource_name)
      droom.show_confirmation_url
    end

    def remember_original_destination
      store_full_location_for(:user, params[:backto])
    end


    # Bypass the usual store_location_for because we need to keep the full URI. 
    #
    def store_full_location_for(resource_or_scope, location)
      session_key = stored_location_key_for(resource_or_scope)
      if location
        session[session_key] = location
      end
    end
    
  end
end