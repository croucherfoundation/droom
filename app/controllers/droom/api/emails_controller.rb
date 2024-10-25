module Droom::Api
  class EmailsController < Droom::Api::ApiController
    load_resource class: "Droom::Email"

    def index
      if params[:email]
        @emails = Droom::Email.where(email: params[:email])
      else
        @emails = Droom::Email.all
      end
      render json: @emails, each_serializer: Droom::EmailSerializer
    end

    def show
      render json: @email, serializer: Droom::EmailSerializer
    end

  end
end