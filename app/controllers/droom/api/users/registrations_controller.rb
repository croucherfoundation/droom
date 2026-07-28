module Droom::Api
  class Users::RegistrationsController < Devise::RegistrationsController
    include Droom::Concerns::ApiResponseHelper

    respond_to :json

    skip_before_action :verify_authenticity_token, raise: false

    def create
      if spam_request?
        return head :ok
      end

      return render_api_error(errors: [I18n.t('validations.email.taken')], status: :unprocessable_entity) if Droom::User.find_by_any_email(@hashed_params[:email])

      build_resource(@hashed_params.merge(show_initial_image: true))
      resource.save
      yield resource if block_given?
      if resource.persisted?
        correspondence_address_type = Droom::AddressType.find_by_name("Correspondence")
        resource.emails.each do |email|
          email.address_type = correspondence_address_type
        end
        # resource.groups << Droom::Group.find_by_slug(params[:group]) if params[:group].present?
        resource.save
        send_confirmation_instructions(resource)

        resource.sync_attendee
        render_api_success(message: t('notifications.authentication.signup_success_confirm_email'), status: :created)
      else
        clean_up_passwords resource
        set_minimum_password_length
        render_api_error(errors: resource.errors, status: :unprocessable_entity, meta: { error_message: resource.errors.full_messages })
      end
    end

    private

    def spam_request?
      return true if sign_up_params[:password].nil? || sign_up_params[:email].nil?

      @hashed_params = sign_up_params
      @hashed_params[:ip_address] ||= request.ip
      @hashed_params[:browser_agent] ||= request.user_agent

      browser = Browser.new(@hashed_params[:browser_agent])
      if browser.known?
        # the browser been successfully detected.
        false
      else
        # Log the rejected account details
        allowed_attrs = %i[given_name family_name email password ip_address browser_agent]
        RejectedAccountLog.create(@hashed_params.slice(*allowed_attrs))
        true
      end
    end

    def sign_up_params
      params.require(:user).permit(:given_name, :family_name, :email, :password, :ip_address, :browser_agent, :after_confirmed_url)
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
