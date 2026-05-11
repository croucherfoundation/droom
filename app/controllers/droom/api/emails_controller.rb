module Droom::Api
  class EmailsController < Droom::Api::ApiController
    load_resource class: "Droom::Email", only: [:show, :index]

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

    def create
      @email = Droom::Email.new(email_params)
      if @email.save
        render json: @email, serializer: Droom::EmailSerializer, status: :created
      else
        render json: { errors: @email.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def email_params
      params.permit(:user_id, :email, :pending_email, :email_verification_token, :email_verification_sent_at, :address_type_id)
    end
  end
end
