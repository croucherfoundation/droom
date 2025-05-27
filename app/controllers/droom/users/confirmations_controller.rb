module Droom::Users
  class ConfirmationsController < Devise::ConfirmationsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :check_user_is_confirmed
    skip_before_action :check_user_setup
    skip_before_action :check_user_has_organisation
    layout :default_layout

    # We used to take people through a process here but by encrypting the stored token
    # devise has made confirmation a bit of a black box. These days we just redirect
    # to the dashboard, which will be interrupted with a password-setting form and
    # possibly also an organisation-joining form.
    #
    def show
      @resource = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if @resource
        sign_in(resource_name, @resource)
        if params[:destination].present?
          redirect_to droom.dashboard_url(destination: params[:destination], send_invitation_memo: params[:send_invitation_memo])
        else
          redirect_to droom.dashboard_url
        end
      else
        render :template => "droom/users/confirmations/failure"
      end
    end

    def default_layout
      Droom.layout
    end

  end
end