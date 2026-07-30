module Droom::Api
  class EmailsController < Droom::Api::ApiController
    load_resource class: "Droom::Email", only: [:show, :index, :update, :destroy]

    def index
      if params[:email]
        @emails = Droom::Email.where(email: params[:email])
      elsif params[:email_verification_token]
        @emails = Droom::Email.where(email_verification_token: params[:email_verification_token])
      else
        @emails = Droom::Email.all
      end
      render_api_success(resource: @emails, each_serializer: Droom::EmailSerializer)
    end

    def show
        render_api_success(resource: @email, serializer: Droom::EmailSerializer)
    end

    def create
      @email = Droom::Email.new(email_params)
      if @email.save
        render_api_success(resource: @email, serializer: Droom::EmailSerializer, status: :created)
      else
        render_api_error(errors: @email.errors, status: :unprocessable_entity)
      end
    end

    def update
      if @email.update(email_params)
        render_api_success(resource: @email, serializer: Droom::EmailSerializer)
      else
        render_api_error(errors: @email.errors, status: :unprocessable_entity)
      end
    end

    def destroy
      if @email.destroy
        render_api_success
      else
        render_api_error(errors: @email.errors, status: :unprocessable_entity)
      end
    end

    private

    def email_params
      params.permit(:user_id, :email, :pending_email, :email_verification_token, :email_verification_sent_at, :address_type_id)
    end
  end
end
