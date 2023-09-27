module Droom
  class UsersController < Droom::DroomController
    helper Droom::DroomHelper
    respond_to :html, :js
    skip_before_action :check_user_has_organisation, only: [:setup, :set_organisation]
    before_action :set_view, only: [:show, :new, :edit, :update]
    before_action :search_users, only: [:admin]
    # before_action :self_unless_admin, only: [:edit, :update]
    load_and_authorize_resource except: [:setup, :set_organisation]

    # :index is the old user-list view, preserved for historical compatibility but now v. clunky.
    # :admin is the new elasticsearch index. The actual search work is done in `search_users`.
    #
    def index
      params[:q] ||= params[:email]
      @users = @users.in_name_order.includes(:permissions)
      @users = @users.matching(params[:q]) unless params[:q].blank?
      # @users = @users.from_email(params[:email]) unless params[:email].blank?
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
      @user = Droom::User.new(user_params)
      if current_user.organisation_admin? && !current_user.admin?
        @user.organisation = current_user.organisation
      end
      # add marker to block the automatic devise confirmation message
      @user.defer_confirmation!
      # add marker to send confirmation once the user is saved and permissions are known
      @user.send_confirmation!

      if @user.save
        respond_with @user
      end
    end

    def edit
      respond_to do |format|
        format.html {render :edit, locals: {mode: true}}
      end
    end

    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      @user.delete_user_permissions(user_params[:group_ids]) unless user_params[:group_ids].blank?
      if @user.update(user_params)
        respond_with @user, location: user_url(view: @view) do |format|
          format.js { head :no_content }
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
      current_user.assign_attributes(setup_params.merge(confirmed: true))
      if current_user.save
        sign_in current_user, :bypass => true
        if current_user.data_room_user?
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

    def subsume
      user = Droom::User.find(params[:user_id])
      other_user = Droom::User.find(params[:other_id])
      user.subsume(other_user)
      render json: {subsume: "queued"}
    end

    def destroy
      @user.destroy
      head :ok
    end

    def reinvite
      @user.send_confirmation_instructions
      head :ok
    end

  protected

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

      @users = Droom::User.search query, arguments
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
        :image
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
          :defer_confirmation,
          group_ids: []
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

    def setup_params
      params.require(:user).permit(:title, :given_name, :family_name, :chinese_name, :honours, :password, :password_confirmation)
    end

    def set_organisation_params
      params.require(:user).permit(:organisation_id, organisation_attributes: [:name, :chinese_name, :url, :organisation_type_id, :description, :owner_id, tag_ids: []])
    end

    def set_view
      @view = params[:view] if %w{simple listed listed_minimal tabled profile preferences my_profile title contact personal account_info statuses groups biography result}.include?(params[:view])
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
