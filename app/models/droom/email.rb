module Droom
  class Email < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

    before_validation :mark_for_destruction_if_blank
    validate :email_must_be_valid

    scope :populated, -> {
      where('email <> "" and email IS NOT NULL')
    }
    def check_user_exist
      value= []
      if self.user.present?
        value.push(self.user_id)
        value.push(true)
        return value
      else
        value.push(self.user_id)
        value.push(false)
        return value
      end
    end

    def email_must_be_valid
      if email_changed? && self.email.present?
        status = ZerobounceService.new(record: self, save_immediate: false).call
        self.user.errors.add(:base, 'Email address provided is invalid') unless status
      end
    end

    def mark_for_destruction_if_blank
      # Only for existing records (not new ones), and only if email is now blank
      if persisted? && email.blank?
        mark_for_destruction
      end
    end

    # Check if email can receive email based on latest SES webhook status
    #
    def can_receive_email?
      email.present? && (ses_status.nil? || ses_status == "delivered")
    end
  end
end
