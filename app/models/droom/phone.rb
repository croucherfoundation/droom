module Droom
  class Phone < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty
    after_commit :sync_phone, if: :saved_change_to_phone?

    scope :populated, -> {
      where('phone <> "" and phone IS NOT NULL')
    }

    private

    def sync_phone
      Rails.logger.info("sync phone droom -> contact")
      return unless default?

      old_phone, new_phone = previous_changes["phone"]
      contact = user.contact
      SyncJob.perform_later(
        "Contact",
        contact.id,
        { "phone" => [old_phone, new_phone] }
      )
    end
  end
end
