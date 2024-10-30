module Droom::Api
  class AddressesController < Droom::Api::ApiController
    load_resource class: "Droom::Address"

    def index
      if params[:email]
        @addresses = Droom::Address.where(email: params[:email])
      else
        @addresses = Droom::Address.all
      end
      render json: @addresses, each_serializer: Droom::AddressSerializer
    end

    def show
      render json: @address, serializer: Droom::AddressSerializer
    end

  end
end