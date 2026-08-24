module Droom
  class Address < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty
    include Droom::RichText::OptIn

    rich_text_attributes :address
    before_validation :sanitize_rich_text_attributes!, if: -> { address.present? }

    before_validation :mark_for_destruction_if_blank

    scope :populated, -> {
      where('address <> "" and address IS NOT NULL')
    }

    def mark_for_destruction_if_blank
      # Only for existing records (not new ones), and only if email is now blank
      if persisted? && address.blank?
        mark_for_destruction
      end
    end

  end
end
