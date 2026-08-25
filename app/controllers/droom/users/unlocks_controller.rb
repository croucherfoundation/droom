module Droom::Users
  class UnlocksController < Devise::UnlocksController
    include Droom::Concerns::FlashMessageHelper

    layout 'droom/sign_in'

    respond_to :html, :json

    skip_before_action :require_no_authentication

    before_action :set_access_control_headers
    before_action :set_email, only: [:create]

    def show
      self.resource = resource_class.unlock_access_by_token(params[:unlock_token])
      if resource.errors.empty?
        redirect_to new_user_session_url(locked: 'unlocked')
      else
        render :new
      end
    end

    def create
      self.resource = resource_class.send_unlock_instructions(resource_params)
      if resource.errors.empty?
        yield resource if block_given?
        set_notice(I18n.t(:unlock_sent))
        redirect_to new_user_session_url
      else
        set_alert(I18n.t(:unlock_account_insturctions_not_delivered))
        redirect_to new_user_unlock_url
      end
    end

    private

    def set_email
      email_address = resource_params[:email]
      @email_record = Droom::Email.where(email: email_address).first
    end

  end
end
