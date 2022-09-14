module Droom::Concerns::Key
  extend ActiveSupport::Concern

  included do
    after_save :generate_key
  end

  def generate_key
    attachment_name = attachment_changes.keys.first
    if attachment_name
      attachment = self.send(attachment_name)

      if attachment.attached? && attachment.new_record?

        klass = self.class.table_name.gsub('_', '/')

        filename = attachment.filename.to_s.gsub(' ', '_')

        key = "#{Settings.activestorage.folder}/#{klass}/#{attachment_name.pluralize}/#{id}/original/#{filename}"

        addendum = 1
        while ActiveStorage::Blob.find_by_key(key)
          key = key.gsub('.', "(#{addendum}).")
          addendum += 1
        end

        attachment.key = key
      end
    end
  end

end
