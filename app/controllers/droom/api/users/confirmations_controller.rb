module Droom::Api
  class Users::ConfirmationsController < Devise::ConfirmationsController
    # before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    # skip_before_action :authenticate_user
    # skip_before_action :verify_authenticity_token, raise: false
    respond_to :json
    #
    def show
      @resource = self.resource = resource_class.confirm_by_token(params[:confirmation_token])

      if @resource.errors.empty?
        @resource.confirm_attendee
        sign_in(@resource)
        render json: {user: @resource, message: "Email confirmed."}, status: :ok
      else
        render json: { user: @resource, message: @resource.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def create
      @resource = Droom::Email.find_by(email: params[:email]).try(:user)
      return render json: { message: ["User not found."] }, status: :not_found unless @resource

      if @resource
        if @resource.confirmed?
          return render json: { message: ["User already confirmed."] }, status: :unprocessable_entity
        end
        send_confirmation_instructions(@resource)
        render json: { message: "Confirmation email sent." }, status: :ok
      else
        render json: { message: @resource.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def send_confirmation_instructions(resource)
      generate_confirmation_token!(resource)
      Droom::Mailer.confirmation_instructions(resource, resource.confirmation_token).deliver_now
    end

    def generate_confirmation_token!(resource)
      resource.confirmation_token = resource.generate_authentication_token
      resource.confirmation_sent_at = Time.current
      resource.save(validate: false)
    end
  end
end