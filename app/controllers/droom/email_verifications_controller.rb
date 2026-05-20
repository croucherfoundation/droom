module Droom
  class EmailVerificationsController < Droom::DroomController
    skip_before_action :authenticate_user!, only: [:show]
    skip_before_action :check_user_is_confirmed, only: [:show]
    skip_before_action :check_user_setup, only: [:show]
    skip_before_action :check_user_has_organisation, only: [:show]
    skip_before_action :check_data_room_permission, only: [:show]
    prepend_before_action :skip_session_limitable_for_verification, only: [:show]

    def show
      email_record = Droom::Email.find_by(email_verification_token: params[:token])
      user = email_record&.user
      unless user
        err_msg = "Invalid or expired verification link."
        write_verification_cache(error_message: err_msg)
        return redirect_to params[:destination].presence || root_path
      end
      result = EmailVerificationService.verify_by_token(params[:token])
      if result[:success] && user
        unless user_signed_in?
          sign_in(user)
          Droom::AuthCookie.new(cookies).set(user)
        end
        write_verification_cache(success_message: "Email verified successfully.")
      else
        write_verification_cache(error_message: "Invalid or expired verification link.")
      end
      redirect_to params[:destination].presence || root_path
    end

    private

    def skip_session_limitable_for_verification
      RequestStore.store[:skip_session_limitable] = true
    end

    def write_verification_cache(error_message: nil, success_message: nil)
      Rails.cache.write("email_verification_cache", {
        error_message: error_message,
        success_message: success_message,
      }, expires_in: 2.minutes)
    end
  end
end
