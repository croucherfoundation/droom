module Droom::Concerns::ScanAttachment
  extend ActiveSupport::Concern

  class_methods do
    def scan_attachment(name)
      before_validation do
        attachment_change = attachment_changes[name.to_s]

        if attachment_change&.attachable.is_a?(ActionDispatch::Http::UploadedFile)
          scan_uploaded_file(name, attachment_change.attachable)
        end
      end
    end
  end

  private

  def scan_uploaded_file(name, uploaded_file)
    result = ClamavServices.scan_file(uploaded_file.tempfile.path)
    case result[:status]
    when :infected
      errors.add(name, "contains malware: #{result[:message]}")
    when :error
      errors.add(name, "could not be scanned: #{result[:message]}")
    end
  end
end
