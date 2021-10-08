module Droom::Api
  class SessionsController < Devise::SessionsController
    include Droom::Concerns::LocalApi

    respond_to :json
    # skip_before_action :authenticate_user!, raise: false
    skip_before_action :verify_authenticity_token, raise: false
    before_action :set_access_control_headers

    # POST /api/users/sign_in
    #
    # Called in sign-in to a remote service.
    #
    def create
      self.resource = warden.authenticate(auth_options)
      if resource
        sign_in(resource_name, resource)
        yield resource if block_given?
        render json: Droom::UserAuthSerializer.new(resource)
      else
        head :unauthorized
      end
    end

    # This is called on every request by a remote service.
    # Care has to be taken here, to respond quickly but lapse correctly,
    # and never to set up a cascade of mutual enquiry.
    # also must make sure that we check, *not sign in*, as signing in would create a new session id.
    #
    def authenticate
      token = params[:tok]
      @user = Droom::User.find_by(unique_session_id: token)
      if @user
        # ie. if user includes timeoutable...
        if @user.respond_to?(:timedout?) && @user.last_request_at?
          # here we borrow the devise timeout strategy but cannot refer to the session,
          # so we use a last_request_at column.
          if @user.timedout?(@user.last_request_at)
            render json: { errors: "Session timed out" }, status: :unauthorized
          else
            bypass_sign_in @user
            @user.set_last_request_at!
          end
        else
          bypass_sign_in @user
        end
        render json: Droom::UserAuthSerializer.new(@user)
      else
        render json: { errors: "Token not recognised" }, status: :unauthorized
      end
    end

    # Deauth is used to achieve single-sign-out. It changes the auth token and session id
    # so that neither the data room session cookie nor the domain auth cookie can identify a user.
    #
    def deauthenticate
      token = params[:tok]
      if @user = Droom::User.find_by(unique_session_id: token)
        @user.reset_session_ids! 
        render json: Droom::UserAuthSerializer.new(@user)
      else
        head :unauthorized
      end
    end

    def api_controller?
      true
    end

    def devise_controller?
      true
    end
  end
end
