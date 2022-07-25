module Droom::Api
  class UsersController < Droom::Api::ApiController

    before_action :get_users, only: [:index]
    before_action :find_or_create_user, only: [:create]
    skip_before_action :assert_local_request!, only: [:update_timezone]
    load_resource find_by: :uid, class: "Droom::User"

    def index
      render json: @users
    end

    def show
      render json: @user
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

    def update
      @user.update(user_params)
      render json: @user
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

    def reindex
      @user.reindex_async
      head :ok
    end

    def update_timezone
      if params[:timezone]
        timezone = Timezones.find_by_key(params[:timezone])
        current_user.update(timezone: timezone)
        return current_user.timezone
      end
    end

  protected

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
      params = user_params
      # remotely created users are not usually meant to access the data room, but can set send_confirmation if that's what they want.
      params[:defer_confirmation] = true
      @user ||= Droom::User.create(params)
    end

    def get_users
      @users = Droom::User.in_name_order
      @users = @users.where(person_uid: params[:person_uid]) if params[:person_uid].present?
      @users = @users.matching_name(params[:name_q]) if params[:name_q].present?
      @users = @users.matching_email(params[:email_q]) if params[:email_q].present?
      @users = @users.from_email(params[:email]) unless params[:email].blank?
      @users = @users.matching(params[:q]) if params[:q].present?
      @users = @users.limit(params[:limit]) if params[:limit].present?
      @users
    end

    def user_params
      params.require(:user).permit(:uid, :person_uid, :title, :family_name, :given_name, :chinese_name, :honours, :affiliation, :email, :phone, :mobile, :description, :address, :post_code, :correspondence_address, :country_code, :organisation_id, :female, :defer_confirmation, :send_confirmation, :password, :password_confirmation, :confirmed, :confirmed_at, :image_data, :image_name, :last_request_at, :preferred_pronoun, :preferred_professional_name)
    end

  end
end
