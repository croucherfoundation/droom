module Droom
  class Email < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

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
        errors.add(:base, 'Email address provided is invalid') unless status 
      end
    end

  end
end
