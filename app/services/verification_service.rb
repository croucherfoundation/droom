class VerificationService

  def initialize(user, otp_code=nil)
    @user = user
    @otp_code = otp_code
  end

  def send_otp
    generate_otp
    Droom.mailer.send(:otp_verification, @user).deliver_now
  end

  def verify_otp
    @user.otp_code == @otp_code && @user.otp_expired_at > Time.zone.now
  end

  private

  def generate_otp
    @user.update_columns(otp_code: rand(100000..999999), otp_expired_at: Time.zone.now + 10.minutes)
  end



end
