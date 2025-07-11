require 'tempfile'

module ScanAttachment
  extend ActiveSupport::Concern

  class_methods do
    def scan_attachment(name)
      validate do
        attachment_change = attachment_changes[name.to_s]
        # Exit if there are no changes to the attachment
        next unless attachment_change&.attachable

        attachable = attachment_change.attachable
        file_to_scan = nil
       
        case attachable
        when ActionDispatch::Http::UploadedFile
          # Standard form uploads - tempfile has a path
          if attachable.tempfile&.path
            scan_file_at_path(name, attachable.tempfile.path)
          end
        when Hash
          # Base64 uploads from ActiveStorageSupport gem
          io_object = attachable[:io]
          if io_object
            scan_file_from_io(name, io_object, attachable[:filename])
          end
        end
      end
    end
  end

  # Below methods are used for scanning attachments outside of the model validation context and can be used in controllers or services.
  def scan_attachment(name, file_path)
    result = ClamavServices.scan_file(file_path)
    case result[:status]
    when :infected
      return "#{name} contains malware: #{result[:message]}"
    when :error
      return "#{name} could not be scanned: #{result[:message]}"
    end
  end

  private

  def scan_file_at_path(name, file_path)
    result = ClamavServices.scan_file(file_path)
    case result[:status]
    when :infected
      errors.add(name, "contains malware: #{result[:message]}")
    when :error
      errors.add(name, "could not be scanned: #{result[:message]}")
    end
  end

  def scan_file_from_io(name, io_object, filename = nil)
    temp_file = Tempfile.new(['scan', File.extname(filename.to_s)], binmode: true)
    begin
      io_object.rewind if io_object.respond_to?(:rewind)
      # Read and write in binary mode to handle all file types
      content = io_object.read
      io_object.rewind if io_object.respond_to?(:rewind)
      content = content.force_encoding('BINARY') if content.respond_to?(:force_encoding)
      temp_file.write(content)
      temp_file.flush
      temp_file.close

      # Scan the temporary file
      scan_file_at_path(name, temp_file.path)
    ensure
      # Clean up the temporary file
      temp_file.unlink if temp_file
    end
  end
end