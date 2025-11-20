module Droom
  class Address < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

    before_validation :mark_for_destruction_if_blank
    after_commit :sync_address

    scope :populated, -> {
      where('address <> "" and address IS NOT NULL')
    }

    def mark_for_destruction_if_blank
      # Only for existing records (not new ones), and only if email is now blank
      if persisted? && address.blank?
        mark_for_destruction
      end
    end

    private

    def sync_address
      return unless default?

      old_address, new_address = previous_changes["address"]
      contact = user.contact
      SyncJob.perform_later(
        "Contact",
        contact.id,
        { "address" => [old_address, new_address] }
      )
    end

  end
end
