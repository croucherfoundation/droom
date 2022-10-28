module Droom
  class Email < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

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
  end
end
