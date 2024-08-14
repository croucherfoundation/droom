module Droom::Api
  class EmailsController < Droom::Api::ApiController

    before_action :get_emails, only: [:index]
    before_action :find_or_create_email, only: [:create]
    load_and_authorize_resource find_by: :uuid, class: "Droom::Email"
    
    def index
      render json: @emails
    end

    def show
      render json: @email
    end

    def update
      @email.update(email_params)
      render json: @email
    end

    def create
      if @email && @email.persisted?
        render json: @email
      else
        render json: {
          errors: @email.errors.to_a
        }
      end
    end

    def destroy
      @email.destroy
      head :ok
    end

  protected

    def find_or_create_email
      if params[:email]
        if params[:email][:uid].present?
          @email = Droom::Email.where(uid: params[:email][:uid]).first
        end
      end
      @email ||= Droom::Email.create(email_params)
    end

    def get_emails
      emails = Droom::Email.in_name_order
      if params[:q].present?
        @fragments = params[:q].split(/\s+/)
        @fragments.each { |frag| emails = emails.matching(frag) }
      end
      @emails = emails
    end

    def email_params
      params.require(:email).permit(:name, :description, :email_set_id, :calendar_id, :all_day, :url, :start, :finish, :timezone, :venue_id, :venue_name)
    end

  end
end