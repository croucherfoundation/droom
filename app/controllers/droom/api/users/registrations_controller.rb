module Droom::Api
  class Users::RegistrationsController < Devise::RegistrationsController
    skip_before_action :verify_authenticity_token, raise: false
    respond_to :json, 

    def create
      return render json: { errors: ["Email has already been taken."] }, status: :unprocessable_entity if Droom::User.find_by_any_email(params[:user][:email])

      build_resource(sign_up_params)
      resource.save
      yield resource if block_given?
      if resource.persisted?
        correspondence_address_type = Droom::AddressType.find_by_name("Correspondence")
        resource.emails.each do |email|
          email.address_type = correspondence_address_type
        end
        resource.groups << Droom::Group.find_by_slug(params[:group]) if params[:group].present?
        resource.save
        send_confirmation_instructions(resource)
        
        resource.sync_attendee
        render json: { message: "Signed up successfully. Please confirm your email." }, status: :created
      else
        clean_up_passwords resource
        set_minimum_password_length
        render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def sign_up_params
      params.require(:user).permit(:given_name, :family_name, :email , :password)
    end

    def send_confirmation_instructions(resource)
      generate_confirmation_token!(resource)
      Droom::Mailer.confirmation_instructions(resource, resource.confirmation_token).deliver_later
    end

    def generate_confirmation_token!(resource)
      resource.confirmation_token = resource.generate_authentication_token
      resource.confirmation_sent_at = Time.current
      resource.save(validate: false)
    end

  end
end