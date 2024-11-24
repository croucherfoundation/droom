module Droom::Api
  class ApiController < Droom::DroomController
    include Droom::Concerns::LocalApi

    respond_to :json
    skip_before_action :verify_authenticity_token, raise: false
    before_action :set_access_control_headers

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from Droom::DroomError, with: :blew_up
    rescue_from Droom::AccessDenied, with: :not_authorized

    protected

    def not_found(exception)
      render json: { errors: exception.message }.to_json, status: :not_found
    end

    def not_authorized(exception)
      render json: { errors: "You do not have permission to access this service" }.to_json, status: :forbidden
    end

    def not_allowed(exception)
      render json: { errors: "You do not have permission to access that resource" }.to_json, status: :forbidden
    end

    def blew_up(exception)
      render json: { errors: exception.message }.to_json, status: :internal_server_error
    end

    def name_from_controller
      params[:controller].sub("Controller", "").underscore.split('/').last
    end

    def api_controller?
      true
    end

    def authenticate_user
      token = retrieve_token
      user = Droom::User.find_by(unique_session_id: token)
      if user
        # ie. if user includes timeoutable...
        if user.respond_to?(:timedout?) && user.last_request_at?
          # here we borrow the devise timeout strategy but cannot refer to the session,
          # so we use a last_request_at column.
          if user.timedout?(user.last_request_at)
            render json: { errors: "Session timed out" }, status: :unauthorized
          else
            bypass_sign_in user
            user.set_last_request_at!
            Droom::AuthCookie.new(cookies).set(user)
          end
        else
          bypass_sign_in user
          Droom::AuthCookie.new(cookies).set(user)
        end
      else
        render json: { errors: "Token not recognised" }, status: :unauthorized
      end
    end

    def set_auth_cookie_for(user)
      Droom::AuthCookie.new(cookies).set(user)
    end

    def retrieve_token
      # Try to get token from headers
      token = token_from_x_api_key ||
              token_from_authorization_header ||
              params[:tok] ||
              token_from_cookie
      token
    end

    def token_from_x_api_key
      if (api_key_header = request.headers["x-api-key"]).present?
        unique_session_id = JSON.parse(api_key_header) rescue nil
        unique_session_id&.dig(1, 0)
      end
    end

    def token_from_authorization_header
      authenticate_with_http_token do |token, _options|
        return token if token.present?
      end
      nil
    end

    def token_from_cookie
      cookie = Droom::AuthCookie.new(cookies)
      cookie.token if cookie.valid? && cookie.fresh?
    end

    def user_session_valid?(user)
      if user.respond_to?(:timedout?) && user.last_request_at?
        !user.timedout?(user.last_request_at)
      else
        true
      end
    end

    def render_unauthorized(message)
      render json: { errors: message }, status: :unauthorized
    end


  end
end
