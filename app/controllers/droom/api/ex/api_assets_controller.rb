module Droom::Api
  module Ex
    class ApiAssetsController < Droom::Api::ApiController
      before_action :set_access_control_headers
      before_action :authenticate_user
    end
  end
end