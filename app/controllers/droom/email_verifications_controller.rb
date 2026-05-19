module Droom
  class EmailVerificationsController < ActionController::Base

    def show
      email_record = Droom::Email.find_by(email_verification_token: params[:token])
      Thread.current[:changed_email] = email_record&.email
      user = email_record&.user
      result = EmailVerificationService.verify_by_token(params[:token])
      if result[:success] && user
        unless user_signed_in?
          sign_in user
          Droom::AuthCookie.new(warden.cookies).set(user)
        end
        flash[:notice] = "Email verified successfully."
      else
        flash[:alert] = "Invalid or expired verification link."
      end
      redirect_to params[:destination].presence || root_path
    end
  end
end
