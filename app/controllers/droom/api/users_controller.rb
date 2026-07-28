module Droom::Api
  class UsersController < Droom::Api::ApiController
    before_action :authenticate_user, unless: :local_request?, only: [:update, :upload_profile_image, :remove_profile]

    before_action :get_users, only: [:index]
    before_action :search_users, only: [:accounts]
    before_action :find_or_create_user, only: [:create]
    skip_before_action :assert_local_request!, only: [:update_timezone, :update, :upload_profile_image, :remove_profile]
    load_resource find_by: :uid, class: "Droom::User"


    def index
      render json: @users
    end

    def accounts
      render json: @users, each_serializer: Droom::UserMinimalSerializer
    end

    def show
      if params[:type].present? && params[:type] == 'minimal'
        render json: @user, serializer: Droom::UserMinimalSerializer
      else
        render json: @user
      end
    end

    # This would usually be a session-init call from a front end SPA
    #
    def whoami
      render json: current_user
    end

    # This is a background call to request the user information necessary for session creation.
    # It usually happens on acceptable of an invitation, or some other situation where
    # a remote object is triggering user confirmation or automatic login.
    #
    def authenticable
      @user.ensure_unique_session_id!
      render json: @user, serializer: Droom::UserAuthSerializer
    end

    def update_contact
      @user.assign_nested_emails(contact_params[:emails]) if contact_params[:emails].present?
      @user.assign_nested_phones(contact_params[:phones]) if contact_params[:phones].present?
      @user.assign_nested_addresses(contact_params[:addresses]) if contact_params[:addresses].present?
      render json: @user, serializer: Droom::UserMinimalSerializer
    end

    def account_update
      @user.assign_nested_emails(account_params[:emails]) if account_params[:emails].present?
      @user.assign_nested_addresses(account_params[:addresses]) if account_params[:addresses].present?
      @user.assign_attributes(timezone: account_params[:timezone]) if account_params[:timezone].present?
      @user.assign_attributes(password: account_params[:password], password_confirmation: account_params[:password_confirmation]) if account_params[:password].present?

      if @user.save
        @user.update_password_attendee(password: account_params[:password]) if account_params[:password].present?
      end

      render json: @user, serializer: Droom::UserMinimalSerializer
    end

    def account_setting_update
      service = EmailVerificationService.new(@user)

      # Handle primary email change (requires verification)
      new_email = account_params[:email]
      destination = account_params[:destination]
      if new_email.present? && new_email != @user.email
        unless service.request_verification(new_email, destination)
          return render json: { errors: service.errors }, status: :unprocessable_entity
        end

        unless has_other_setting_updates?
          return render json: { message: "Verification email sent to #{new_email}" }, status: :ok
        end
      end

      # Handle backup_email update (update 2nd email in list, add, or remove if blank)
      if account_params.key?(:backup_email)
        backup_email = account_params[:backup_email]
        emails = @user.emails.not_pending.to_a

        if backup_email.blank?
          emails[1].destroy if emails.size >= 2
        elsif emails.size >= 2
          emails[1].email = backup_email
          emails[1].save if emails[1].changed?
        else
          @user.emails.build(email: backup_email)
        end
      end

      @user.assign_attributes(timezone: account_params[:timezone]) if account_params[:timezone].present?
      @user.assign_attributes(given_name: account_params[:first_name]) if account_params[:first_name].present?
      @user.assign_attributes(family_name: account_params[:last_name]) if account_params[:last_name].present?
      @user.assign_attributes(password: account_params[:new_password]) if account_params[:new_password].present?

      if @user.save
        @user.update_password_attendee(password: account_params[:new_password]) if account_params[:new_password].present?
      end

      render json: @user, serializer: Droom::UserMinimalSerializer
    end

    def check_valid_password
      if @user.valid_password?(params[:user][:current_password])
        head :ok
      else
        render json: { error: "current_password is incorrect" }, status: :unprocessable_entity
      end
    end

    def send_otp
      VerificationService.new(@user).send_otp
      head :ok
    end

    def verify_otp
      otp = params[:user][:otp].to_i
      if VerificationService.new(@user,otp).verify_otp
        render json: @user, serializer: Droom::UserMinimalSerializer
      end
    end

    def update
      @user.class.sync_in_progress = params[:user]['skip_person_sync'] == true

      profile_image = user_params[:image] if user_params[:image].present?
      attach_base64_image(@user, :image, profile_image) if profile_image.present?
      @user.show_initial_image = true if params[:user][:remove_image] == true || params[:user][:remove_image] == "true"

      if @user.update(user_params.except(:image))
        @user.class.sync_in_progress = false
        render json: @user.reload
      else
        render json: @user, serializer: Droom::UserSerializer, meta: {error: @user.errors.full_messages}
      end
    end

    def upload_profile_image
      return render_image_validation_error unless user_params[:image].present?

      profile_image = user_params[:image]

      # Validate format and size before attaching
      validation_error = validate_image_data(profile_image)
      return render_image_validation_error(validation_error) if validation_error.present?

      attach_base64_image(@user, :image, profile_image)

      if @user.save
        render json: {
          success: true,
          photo_url: profile_image_url(@user.reload)
        }
      else
        render json: {
          success: false,
          error: @user.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def create
      if @user && @user.persisted?
        render json: @user
      else
        render json: { errors: @user.errors.to_a }
      end
    end

    def destroy
      @user.destroy
      head :ok
    end

    def remove_profile
      @user.update(show_initial_image: true)
      render json: @user.reload
    end

    def sync_profile_image
      @user.sync_profile_from_external(params[:image_url]) if params[:image_url].present?
      render json: @user
    end

    def reindex
      @user.reindex_async
      head :ok
    end

    def update_timezone
      if params[:timezone]
        timezone = Timezones.find_by_key(params[:timezone])
        current_user.update(timezone: timezone)
        # return current_user.timezone
        respond_to do |format|
          format.json { render json: { notice: "The timezone of your profile has been updated to #{params[:timezone]}." }, status: :ok }
        end
      end
    end

    def validate_email
      @email = Droom::Email.find_by(email: @user.email)
      return render json: { valid: false } unless @email.present?

      render json:  @user, serializer: Droom::UserMinimalSerializer, meta: { valid: ZerobounceService.new(record: @email).call }
    end

    def remove_reviewer_group
      @group_id = Droom::Group.find_by(name: 'Reviewer')&.id
      @user.memberships.find_by(group_id: @group_id)&.destroy if @group_id.present?
    end

    def eligible_event_admins
      users = Droom::User.admins
      render json: users
    end

  protected

    # Handle primary and backup email updates differently
    # Primary email (index 0 or address_type_id 1) → requires verification
    # Backup email (index 1 or address_type_id 4) → direct update
    def handle_email_updates(params_hash)
      emails_attrs = params_hash[:emails_attributes]
      return params_hash unless emails_attrs.present?

      emails_attrs = emails_attrs.to_h if emails_attrs.respond_to?(:to_h)
      modified_emails_attrs = {}

      emails_attrs.each do |index, email_data|
        email_data = email_data.to_h.with_indifferent_access
        is_primary = index.to_s == "0" || email_data[:address_type_id].to_s == "1"

        if is_primary && email_data[:email].present?
          # Check if primary email actually changed
          current_primary = @user.emails.find_by(address_type_id: 1) || @user.emails.first
          new_email = email_data[:email]

          if current_primary.nil? || current_primary.email != new_email
            # Primary email changed - trigger verification
            verification_service = EmailVerificationService.new(@user)
            if verification_service.request_verification(new_email)
              # Don't include primary email in the update - it will be updated after verification
              # But we still need to process other updates
              render json: {
                message: "Verification email sent to #{new_email}. Please check your inbox.",
                verification_required: true
              }, status: :ok
              return params_hash.except(:emails_attributes) # Remove all emails, continue with other updates
            else
              render json: { errors: verification_service.errors }, status: :unprocessable_entity
              return params_hash
            end
          else
            # Primary email not changed, include it
            modified_emails_attrs[index] = email_data
          end
        else
          # Backup email - include for direct update
          modified_emails_attrs[index] = email_data
        end
      end

      params_hash[:emails_attributes] = modified_emails_attrs.presence
      params_hash
    end

    def find_or_create_user
      if params[:user]
        if params[:user][:uid].present?
          @user = Droom::User.where(uid: params[:user][:uid]).first
        end
        if params[:user][:email].present?
          @user ||= Droom::User.where(email: params[:user][:email]).first
          unless @user
            @user ||= Droom::Email.where(email: params[:user][:email]).first.try(:user)
          end
        end
      end
      params = user_params.merge(show_initial_image: true)
      # remotely created users are not usually meant to access the data room, but can set send_confirmation if that's what they want.
      params[:defer_confirmation] = true
      if @user.present? && user_params[:user_group].present?
        @user.user_group = user_params[:user_group]
        @user.save
      end
      @user ||= Droom::User.create(params)
    end

    def get_users
      @users = Droom::User.in_name_order
      @users = @users.where(person_uid: params[:person_uid]) if params[:person_uid].present?
      @users = @users.where(uid: params[:user_uids]) if params[:user_uids].present?
      @users = @users.matching_name(params[:name_q]) if params[:name_q].present?
      @users = @users.matching_email(params[:email_q]) if params[:email_q].present?
      @users = @users.from_email(params[:email]) unless params[:email].blank?
      @users = @users.matching(params[:q]) if params[:q].present?
      @users = @users.limit(params[:limit]) if params[:limit].present?
      @users
    end

    def search_users
      group_slugs = if params[:group_ids].present?
        Droom::Group.shown_in_directory.where(id: params[:group_ids]).pluck(:slug)
      else
        []
      end

      filters = {}
      filters[:groups] = group_slugs if group_slugs.present?
      filters[:uid] = params[:user_uids] if params[:user_uids].present?

      query = params[:q].presence || '*'
      arguments = {
        where: filters,
        order: {name: :asc},
        page: 1,
        per_page: 1000
      }

      @users = Droom::User.search query, **arguments
    end

    def user_params
      params.require(:user).permit(:uid, :person_uid, :title, :family_name, :given_name, :chinese_name, :honours, :affiliation,
          :email, :phone, :mobile, :description, :address, :post_code, :correspondence_address, :country_code, :organisation_id,
          :female, :defer_confirmation, :send_confirmation, :password, :password_confirmation, :confirmed, :confirmed_at, :image_data, :image,
          :image_name, :last_request_at, :preferred_pronoun, :preferred_professional_name, :preferred_name, :hkid, :dob, :pob, :nationality, :gender,
          :timezone, :organisation_admin, :admin, :gatekeeper, :user_group, :confirmation_token,
          emails_attributes: [:id, :_destroy, :email, :address_type_id, :default], addresses_attributes: [:id, :_destroy, :address, :address_type_id, :default])
    end

    def contact_params
      params.require(:user).permit(
        emails: [:id, :email, :email_type],
        phones: [:id, :phone, :phone_type],
        addresses: [:id, :address, :address_type]
      )
    end

    def account_params
      params.require(:user).permit(
       :password, :password_confirmation, :current_password, :new_password, :timezone,
       :first_name, :last_name, :email, :backup_email, :destination,
        emails: [:id, :email, :email_type],
        addresses: [:id, :address, :address_type]
      )
    end

    def has_other_setting_updates?
      account_params[:timezone].present? || account_params[:password].present?
    end

    def profile_image_url(user)
      user.image.attached? ? user.image.url : ""
    end

    def validate_image_data(base64_data)
      return "No image data provided" unless base64_data.present?

      begin
        content_type, encoded_image = base64_data.split(',')
        return "Invalid base64 image format" unless encoded_image.present?

        decoded_image = Base64.decode64(encoded_image)
        mime_type = content_type.split(':')[1].split(';')[0]

        # Validate format
        allowed_formats = ['image/jpeg', 'image/png']
        unless allowed_formats.include?(mime_type)
          return "Invalid image format. Accepted formats: JPG, PNG"
        end

        # Validate size (5MB = 5242880 bytes)
        max_size_bytes = 5 * 1024 * 1024
        if decoded_image.bytesize > max_size_bytes
          size_mb = (decoded_image.bytesize.to_f / 1024 / 1024).round(2)
          return "Image too large (#{size_mb}MB). Maximum size: 5MB"
        end

        nil  # No error
      rescue => e
        "Error validating image: #{e.message}"
      end
    end

    def render_image_validation_error(error_msg = nil)
      render json: {
        success: false,
        photo_url: "",
        error: [error_msg || "Image is required and must be JPG or PNG, maximum 5MB"]
      }, status: :unprocessable_entity
    end

  end
end
