class EmailVerificationService
  VERIFICATION_TOKEN_EXPIRY = 24.hours

  attr_reader :user, :errors

  def initialize(user)
    @user = user
    @errors = {}
  end

  # Request verification for a new primary email.
  # Creates or refreshes a pending email record and stores token.
  def request_verification(new_email, destination)
    return false unless validate_email(new_email)
    return false unless check_uniqueness(new_email)

    token = SecureRandom.hex(12)
    email_record = user.emails.find_or_initialize_by(email: new_email, pending_email: true)

    email_record.assign_attributes(
      email_verification_token: token,
      email_verification_sent_at: Time.zone.now
    )

    unless email_record.save
      @errors = email_record.errors.to_hash.presence || { email: ["could not be saved"] }
      return false
    end

    Droom.mailer.send(:email_verification, user, new_email, token, destination).deliver_later
    true
  end

  # Look up user by token and verify — no login required.
  def self.verify_by_token(token)
    unless token.present?
      return { success: false, errors: { token: ["is required"] } }
    end

    email_record = Droom::Email.find_by(email_verification_token: token)
    unless email_record
      return { success: false, errors: { token: ["is invalid"] } }
    end

    user = email_record.user
    unless user
      return { success: false, errors: { token: ["is invalid"] } }
    end

    service = new(user)
    if service.verify(token, email_record)
      { success: true, user_id: email_record.user_id }
    else
      { success: false, errors: service.errors }
    end
  end

  # Verify a token and promote the pending email to primary.
  def verify(token, email_record = nil)
    unless token.present?
      @errors = { token: ["is required"] }
      return false
    end

    email_record ||= find_pending_email_record
    unless email_record
      @errors = { token: ["no pending email verification"] }
      return false
    end

    unless ActiveSupport::SecurityUtils.secure_compare(email_record.email_verification_token, token)
      @errors = { token: ["is invalid"] }
      return false
    end

    promote_pending_email!(email_record)
    true
  end

  private

  def validate_email(email)
    unless email.present?
      @errors = { email: ["can't be blank"] }
      return false
    end

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      @errors = { email: ["is not a valid email address"] }
      return false
    end
    true
  end

  def check_uniqueness(email)
    existing = Droom::Email.where(email: email).where.not(user_id: user.id)
    if existing.exists?
      @errors = { email: ["is already taken"] }
      return false
    end

    # Check if the same email is already the user's primary email
    if user.email == email
      @errors = { email: ["is already your primary email"] }
      return false
    end

    true
  end

  def find_pending_email_record
    user.emails.find_by(pending_email: true)
  end

  def promote_pending_email!(email_record)
    new_email = email_record.email

    # Update the first email in the user's email list
    primary_email = user.emails.first
    primary_email.update(email: new_email) if primary_email

    # Delete the pending email record
    email_record.destroy
  rescue => e
    @errors = { base: ["Failed to promote email: #{e.message}"] }
    false
  end

  def clear_pending_email!(email_record)
    email_record.destroy
  end
end
