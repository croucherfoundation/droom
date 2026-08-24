module Droom
  class Address < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty
    include Droom::RichText::OptIn

    rich_text_attributes :address
    before_validation :sanitize_rich_text_attributes!, if: -> { address.present? }

    scope :populated, -> {
      where('address <> "" and address IS NOT NULL')
    }

  end
end
