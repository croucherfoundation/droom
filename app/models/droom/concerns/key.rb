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
        filename = self.name.gsub(' ', '_')
        original_key = "#{Settings.activestorage.folder}/#{klass}/#{attachment_name.pluralize}/#{id}/original/#{filename}"
        
        new_key, new_filename = self.check_file_already_exist(original_key)
        attachment.key = new_key.presence || original_key
        attachment.filename = new_filename.present? ? new_filename.gsub(' ', '_') : filename
      end
    end
  end
  
  def check_file_already_exist(original_key)
    key = original_key
    addendum = 1
    
    while ActiveStorage::Blob.find_by_key(key)
      key_array = original_key.split('/')
      filename_array = key_array.pop.split('.') # "test.sample.pdf" => ["test", "sample", "pdf"]
      extension = filename_array.pop # pdf
      lastfilename = filename_array.pop # sample
      
      filename_array << "#{lastfilename}(#{addendum})"
      filename_array << "#{extension}"
      filename = filename_array.join(".")
      
      key_array << filename
      key = key_array.join("/")
      
      addendum += 1
    end
    
    return key, filename
  end

end
