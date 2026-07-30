module Droom::Api
  module Ex
    class ApiController < Droom::Api::ApiController
      include Droom::Concerns::ApiResponseHelper
      
      before_action :set_access_control_headers
      before_action :authenticate_user
    end
  end
end
