require 'tempfile'

module Droom::Concerns::ScanAttachment
  extend ActiveSupport::Concern

  # Files larger than this threshold (in bytes) will be scanned asynchronously
  # via a background job instead of blocking the HTTP request.
  LARGE_FILE_THRESHOLD = 25.megabytes

  class_methods do
    def scan_attachment(name)
      validate do
        attachment_change = attachment_changes[name.to_s]
        # Exit if there are no changes to the attachment
        next unless attachment_change

        # Only scan if it's a CreateOne change (new attachment), not DeleteOne
        next unless attachment_change.is_a?(ActiveStorage::Attached::Changes::CreateOne)

        attachable = attachment_change.attachable
        next unless attachable

        # For large files, skip synchronous scan and defer to background job.
        # The document model will set scan_status = "pending" and enqueue the job after save.
        file_size = case attachable
                    when ActionDispatch::Http::UploadedFile
                      attachable.size
                    when Hash
                      attachable[:io]&.size
                    else
                      0
                    end

        if file_size && file_size > LARGE_FILE_THRESHOLD && self.respond_to?(:scan_status=)
          self.scan_status = "pending"
          Rails.logger.info "[ScanAttachment] Large file detected (#{(file_size / 1.megabyte.to_f).round(1)}MB), deferring virus scan to background job"
          next
        end

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

      # After committing a record with pending scan, enqueue background scan job
      # Only register once even if scan_attachment is called multiple times
      unless @_scan_job_callback_registered
        after_commit :enqueue_scan_job_if_pending, if: -> { respond_to?(:scan_status) && saved_change_to_attribute?("scan_status") && scan_status == "pending" }
        @_scan_job_callback_registered = true
      end
    end
  end

  def enqueue_scan_job_if_pending
    Droom::ScanDocumentFileJob.perform_later(self.id)
    Rails.logger.info "[ScanAttachment] Enqueued background virus scan for document ##{self.id}"
  rescue => e
    Rails.logger.error "[ScanAttachment] Failed to enqueue scan job for document ##{self.id}: #{e.message}"
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