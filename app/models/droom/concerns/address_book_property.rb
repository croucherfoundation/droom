module Droom::Concerns::AddressBookProperty
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    belongs_to :address_type
    after_save :undefault_others

    scope :preferred, -> {
      order(default: :desc).limit(1)
    }

    scope :by_preference, -> {
      order(default: :desc)
    }

    scope :default, -> {
      where(default: true)
    }

    scope :other_than, -> thing {
      where.not(id: thing.id)
    }

    scope :of_type, -> name {
      joins(:address_type).where(droom_address_types: {name: name})
    }

  end

  def undefault_others
    if user && self.default?
      self.class.where(user_id: user.id).other_than(self).update_all(default: false)
    end
  end

end
