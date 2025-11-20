module Droom
  class Email < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty
    include Syncable

    before_validation :mark_for_destruction_if_blank
    validate :email_must_be_valid
    after_commit :sync_email

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

    private
    def sync_email
      return unless default?                      
      return unless previous_changes.key?("email")

      new_email = email # the new email value
      contact = user.contact
      # Call SyncJob exactly the same way Droom::User would
      SyncJob.perform_later(
        "Contact",
        contact.id,
        { "email" => [previous_changes["email"]&.first, new_email] }
      )
    end
  end
end
