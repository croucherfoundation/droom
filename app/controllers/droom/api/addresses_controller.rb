module Droom::Api
  class AddressesController < Droom::Api::ApiController
    load_resource class: "Droom::Address"

    def index
      if params[:email]
        @addresses = Droom::Address.where(email: params[:email])
      else
        @addresses = Droom::Address.all
      end

      render_api_success(resource: @addresses, each_serializer: Droom::AddressSerializer)
    end

    def show
      render_api_success(resource: @address, serializer: Droom::AddressSerializer)
    end

  end
end