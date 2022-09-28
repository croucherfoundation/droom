module Droom::Api
  class ApiController < Droom::DroomController
    include Droom::Concerns::LocalApi

    respond_to :json
    skip_before_action :verify_authenticity_token, raise: false
    before_action :set_access_control_headers

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from Droom::DroomError, with: :blew_up

    protected
    
    def api_controller?
      true
    end

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
  end
end