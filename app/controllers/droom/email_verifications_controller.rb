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
        return redirect_to redirect_destination(err_msg: err_msg)
      end
      result = EmailVerificationService.verify_by_token(params[:token])
      if result[:success] && user
        unless user_signed_in?
          sign_in(user)
          Droom::AuthCookie.new(cookies).set(user)
        end
        msg = "Email verified successfully."
        write_verification_cache(success_message: msg)
        redirect_to redirect_destination(msg: msg)
      else
        err_msg = "Invalid or expired verification link."
        write_verification_cache(error_message: err_msg)
        redirect_to redirect_destination(err_msg: err_msg)
      end
    end

    private

    def skip_session_limitable_for_verification
      RequestStore.store[:skip_session_limitable] = true
    end

    def redirect_destination(msg: nil, err_msg: nil)
      return root_path unless params[:destination].present?
      base = params[:destination].presence
      uri = URI.parse(base)
      query_params = URI.decode_www_form(uri.query || "")
      query_params << ["msg", msg] if msg
      query_params << ["err_msg", err_msg] if err_msg
      uri.query = URI.encode_www_form(query_params)
      uri.to_s
    end

    def write_verification_cache(error_message: nil, success_message: nil)
      Rails.cache.write("email_verification_cache", {
        error_message: error_message,
        success_message: success_message,
      }, expires_in: 2.minutes)
    end
  end
end
