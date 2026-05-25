module Droom
  class UsersController < Droom::DroomController
    helper Droom::DroomHelper
    respond_to :html, :js, :json
    skip_before_action :check_user_has_organisation, only: [:setup, :set_organisation]
    before_action :set_view, only: [:show, :new, :edit, :update, :account_setting_update]
    # before_action :search_users, only: [:admin]
    # before_action :self_unless_admin, only: [:edit, :update]
    load_and_authorize_resource except: [:setup, :set_organisation]

    # :index is the old user-list view, preserved for historical compatibility but now v. clunky.
    # :admin is the new elasticsearch index. The actual search work is done in `search_users`.
    #
    def index
      @users = @users.in_name_order.includes(:permissions)
      @users = @users.matching(params[:q]) unless params[:q].blank?
      @users = @users.from_email(params[:email]) unless params[:email].blank?
      @users = paginated(@users, params[:pp].presence || 24)
      respond_with @users do |format|
        format.js { render :partial => 'droom/users/users' }
      end
    end

    def download
      @users = @users.internal.in_name_order.includes(:emails, :phones, :addresses)
      @users = @users.matching(params[:q]) unless params[:q].blank?
      render :vcf => @users.map(&:to_vcf)
    end

    def search
      q = params[:q].to_s.strip
      query = q.present? ? q : "*"
      results = Droom::User.search(query, where: { deleted: false }, order: { name: :asc }, limit: 10)
      render json: results.map { |u|
        {
          id: u.id,
          name: u.formal_name,
          email: u.email,
          avatar_url: u.image.url
        }
      }
    end

    def show
      respond_with @user
    end

    def new
      if params[:group_id].present?
        @user.groups << Droom::Group.find(params[:group_id])
      end
      if params[:organisation_id].present? && Droom.use_organisations?
        @user.organisation = Droom::Organisation.find(params[:organisation_id])
      end
      respond_with @user
    end

    def create
      hashed_params = user_params
      hashed_params[:show_initial_image] = !hashed_params[:image].present?

      @user = Droom::User.new(hashed_params)
      if current_user.organisation_admin? && !current_user.admin?
        @user.organisation = current_user.organisation
      end
      # add marker to block the automatic devise confirmation message
      @user.defer_confirmation!
      # add marker to send confirmation once the user is saved and permissions are known
      @user.send_confirmation!

      if @user.save
        respond_with @user
      else
        email_error = @user.errors.full_messages.find do |msg|
          msg.end_with?("Email address provided is invalid")
        end
        if email_error
          if request.xhr?
            render json: { errors: ["Email address provided is invalid"] }, status: :unprocessable_entity
          else
            flash[:alert] = "Email address provided is invalid"
            redirect_to request.referer
          end
        end
      end
    end

    def edit
      respond_to do |format|
        format.html {render :edit, locals: {mode: true}}
      end
    end

    def account_setting_update
      return if password_change_invalid?(user_params)
      permitted = user_params
      permitted.delete(:current_password)
      permitted.delete(:password_confirmation)
      new_password = permitted.delete(:password)

      @user.show_initial_image = false if permitted[:image].present?
      @user.show_initial_image = true if params[:remove_image] == "true"

      modified_params, verification_email = handle_email_updates(permitted)
      modified_params[:password] = new_password if new_password.present?

      if @user.update(modified_params)
        if verification_email
          message = "Verification email sent to #{verification_email}. Please check your inbox."
          if request.xhr?
            render json: { message: message, verification_required: true }, status: :ok
          else
            flash[:notice] = message
            redirect_to request.referrer || user_url(@user)
          end
        else
          respond_with @user, location: user_url(view: @view) do |format|
            format.js { head :no_content }
          end
        end
      else
        email_error = @user.errors.full_messages.find do |msg|
          msg.end_with?("Email address provided is invalid")
        end
        if email_error
          if request.xhr?
            render json: { errors: ["Email address provided is invalid"] }, status: :unprocessable_entity
          else
            flash[:alert] = "Email address provided is invalid"
            redirect_to request.referer
          end
        end
      end
    rescue ActiveModel::UnknownAttributeError => e
      render json: { error_message: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error_message: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
    end

    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      @user.delete_user_permissions(user_params[:group_ids]) unless user_params[:group_ids].blank?
      @user.show_initial_image = false if user_params[:image].present?
      @user.show_initial_image = true if params[:remove_image] == "true"
      if user_params[:timezone] == "null"
        params[:user][:timezone] = nil
      end
      if @user.update(user_params)
        if params[:emergency_contact].present?
          Person.update_personal_info(@user.person.id, {
            emergency_contact: params[:emergency_contact]
          })
        end
        if params[:reload] == "true"
          redirect_to request.referrer
        else
          respond_with @user, location: user_url(view: @view) do |format|
            format.js { head :no_content }
          end
        end
      else
        email_error = @user.errors.full_messages.find do |msg|
          msg.end_with?("Email address provided is invalid")
        end
        if email_error
          if request.xhr?
            render json: { errors: ["Email address provided is invalid"] }, status: :unprocessable_entity
          else
            flash[:alert] = "Email address provided is invalid"
            redirect_to request.referer
          end
        end
      end
    end

    def activity
      find_user_by_user_id
    end

    ## Confirmation
    #
    # This is the destination of the password-setting form that intervenes when a new user arrives who has not yet
    # set a password. Normally this would only happen when they hit the confirmation link, which checks the account
    # then redirects to the dashboard.
    #
    def setup
      if setup_params[:timezone] == "null"
        params[:user][:timezone] = nil
      end
      current_user.assign_attributes(setup_params.merge(confirmed: true))
      if current_user.save
        sign_in current_user
        if current_user.data_room_user? || params[:send_invitation_memo].present?
          flash[:notice] = t(:password_set)
          redirect_to params[:destination].presence || droom.dashboard_url
        else
          raise Droom::AccessDenied
        end
      else
        render template: "/droom/users/request_password"
      end
    end

    def set_organisation
      if current_user.update(set_organisation_params)
        redirect_to params[:destination].presence || droom.dashboard_url
      else
        render template: "/droom/users/setup_organisation"
      end
    end

    def merge
      @other_user = Droom::User.find(merge_params[:other_id])
      @other_user.subsume(@user)
      head :no_content
    end

    def destroy
      Csw::Attendee.find_by_email(@user.email).try(:destroy)
      @user.destroy
      redirect_to droom.admin_users_url
    end

    def reinvite
      @user.send_confirmation_instructions
      head :ok
    end

    def check_email
      message = 'whoops'
      user_ids = []
      if params[:email].present?
        emails = Droom::Email.where(email: params[:email])
        emails = emails.where.not(user_id: params[:user_id]) if params[:user_id].present?
        user_ids = emails.map(&:check_user_exist)
      end
      user_ids = user_ids.select{|id| id[1] == true }
      unless user_ids.empty?
        message = 'oops'
      end
      render json: {message: message, user_ids: user_ids.to_s}
    end

    def suggest
      limit = (params[:limit].presence || 10).to_i
      query = params[:name].presence || params[:email].presence || params[:q].presence
      if query.present?
        @users = Droom::User.search(query, page: 1, per_page: limit, order: { _score: :desc })
      else
        @users = []
      end

      render json: format_users(@users)
    end

  protected

    def password_change_invalid?(user_params)
      current_password = user_params[:current_password]
      new_password = user_params[:password]

      return false if current_password.blank? && new_password.blank?

      if current_password.blank?
        return render_update_error("Current password is required to set a new password.")
      end

      unless @user.valid_password?(current_password)
        return render_update_error("Current password is incorrect.")
      end

      if new_password.blank?
        return render_update_error("New password cannot be blank.")
      end

      if new_password == current_password
        return render_update_error("New password must be different from current password.")
      end

      false
    end

    def render_update_error(message, status = :unprocessable_entity)
      if request.xhr?
        render json: { error_message: message }, status: status
      else
        flash[:alert] = message
        redirect_to request.referer
      end

      true
    end

    def format_users(users)
      users.map do |user|
        {
          uid: user.id,
          title: user.title,
          name: "#{user.given_name} #{user.family_name}".strip,
          given_name: user.given_name,
          family_name: user.family_name,
          chinese_name: user.chinese_name,
          email: user.email,
          phone: user.phone,
          mobile: user.mobile,
          address: user.address,
          correspondence_address: user.correspondence_address,
          prompt: user.email,
          avatar_url: user.thumbnail
        }
      end
    end

    def search_users
      filters = {}
      filters[:groups] = params[:account_group] if params[:account_group].present?
      filters[:account_confirmation] = params[:account_confirmed] if params[:account_confirmed].present?
      filters[:organisation] = params[:organisation] if params[:organisation].present?

      query = params[:q].presence || '*'
      arguments = {
        where: filters,
        aggs: [:groups, :account_confirmation, :organisation],
        order: {name: :asc}
      }

      if params[:show] == "all"
        arguments[:limit] = 1000
      else
        arguments[:per_page] = (params[:show].presence || 50).to_i
        arguments[:page] = (params[:page].presence || 1).to_i
      end

      @users = Droom::User.search query, **arguments
    end

    # Handle primary and backup email updates differently.
    # Returns [modified_params, verification_email_or_nil]
    #
    # Primary email (index 0) → requires verification; excluded from update params.
    # Backup email (index 1) → direct update, no verification needed.
    def handle_email_updates(params_hash)
      emails_attrs = params_hash[:emails_attributes]
      return [params_hash, nil] unless emails_attrs.present?

      emails_attrs = emails_attrs.to_h if emails_attrs.respond_to?(:to_h)
      modified_emails_attrs = {}
      verification_email = nil

      emails_attrs.each do |index, email_data|
        email_data = email_data.to_h.with_indifferent_access
        is_primary = index.to_s == "0"

        if is_primary && email_data[:email].present?
          current_primary = @user.emails.first
          new_email = email_data[:email]

          if current_primary.nil? || current_primary.email != new_email
            # Primary email changed — send verification, exclude from update
            verification_service = EmailVerificationService.new(@user)
            unless verification_service.request_verification(new_email, nil)
              render_update_error(verification_service.errors.join(", "))
              return [params_hash, nil]
            end
            verification_email = new_email
          else
            # Primary email unchanged — keep it in params
            modified_emails_attrs[index] = email_data
          end
        else
          # Backup email — always include for direct update
          modified_emails_attrs[index] = email_data
        end
      end

      params_hash[:emails_attributes] = modified_emails_attrs.presence
      [params_hash, verification_email]
    end

    def user_params
      permitted_params = [
        :title,
        :family_name,
        :given_name,
        :chinese_name,
        :honours,
        :organisation_id,
        :affiliation,
        :email,
        :current_password,
        :password,
        :password_confirmation,
        :phone,
        :description,
        :admin,
        :gender,
        :dob,
        :confirm,
        :old_id,
        :address,
        :post_code,
        :country_code,
        :mobile,
        :female,
        :image,
        :show_initial_image,
        :timezone,
        :preferred_professional_name,
        :preferred_name,
        :preferred_pronoun,
        :hkid,
        :pob,
        :nationality,
        group_ids: []
      ]

      if current_user.organisation_admin?
        permitted_params += [
          :organisation_admin,
          :send_confirmation
        ]
      elsif current_user.admin?
        permitted_params += [
          :admin,
          :gatekeeper,
          :organisation_id,
          :organisation_admin,
          :send_confirmation,
          :defer_confirmation
        ]
      end

      permitted_params += [
        emails_attributes: [:id, :_destroy, :email, :address_type_id, :default],
        phones_attributes: [:id, :_destroy, :phone, :address_type_id, :default],
        addresses_attributes: [:id, :_destroy, :address, :address_type_id, :default],
        preferences_attributes: [:id, :_destroy, :uuid, :key, :value]
      ]

      if params[:user]
        params.require(:user).permit(*permitted_params)
      else
        {}
      end
    end

    def merge_params
      params.require(:user).permit(:other_id)
    end

    def setup_params
      params.require(:user).permit(:title, :given_name, :family_name, :chinese_name, :honours, :password, :password_confirmation, :timezone)
    end

    def set_organisation_params
      params.require(:user).permit(:organisation_id, organisation_attributes: [:name, :chinese_name, :url, :organisation_type_id, :description, :tags, :owner_id])
    end

    def set_view
      @view = params[:view] if %w{simple listed listed_minimal tabled profile preferences my_profile title contact personal account_info statuses groups biography result subsume}.include?(params[:view])
      #@view ||= 'profile'
    end

    def self_unless_admin
      @user = current_user unless @user && current_user.admin?
    end

    def find_user_by_user_id
      @user ||= Droom::User.find_by_id(params[:user_id])
    end
  end
end
