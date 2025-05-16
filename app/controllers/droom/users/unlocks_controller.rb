module Droom::Users
  class UnlocksController < Devise::UnlocksController
    respond_to :html, :json
    before_action :set_access_control_headers
    skip_before_action :require_no_authentication
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
      yield resource if block_given?
      head :ok
    end
    
  end
end