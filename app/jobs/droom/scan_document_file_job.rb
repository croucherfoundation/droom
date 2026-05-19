require 'droom'

module Droom
  class ScanDocumentFileJob < ActiveJob::Base
    queue_as :default

    # Custom error for retryable failures
    class ScanRetryError < StandardError; end

    retry_on ScanRetryError, wait: 30.seconds, attempts: 3 do |job, error|
      # All retries exhausted — mark as scan_error
      document = Droom::Document.find_by(id: job.arguments.first)
      if document && document.scan_status == "pending"
        document.update_column(:scan_status, "scan_error")
        job.send(:broadcast_scan_result, document, "scan_error", "Scan failed after multiple attempts")
      end
      Rails.logger.error "[ScanJob] All retries exhausted for document ##{job.arguments.first}: #{error.message}"
    end

    def perform(document_id)
      document = Droom::Document.find_by(id: document_id)
      return unless document
      return unless document.file.attached?
      return unless document.scan_status == "pending"

      Rails.logger.info "[ScanJob] Starting scan for document ##{document_id} (#{document.name})"

      # Download file from S3 to a local tempfile
      tempfile = Tempfile.new(["scan_#{document_id}_", File.extname(document.name.to_s)], binmode: true)
      begin
        # Stream download from S3 in chunks to handle large files
        document.file.download do |chunk|
          tempfile.write(chunk)
        end
        tempfile.flush
        tempfile.close

        # Verify the downloaded file is not empty
        downloaded_size = File.size(tempfile.path)
        if downloaded_size == 0
          raise ScanRetryError, "Downloaded file is empty (0 bytes) - S3 download may have failed"
        end

        Rails.logger.info "[ScanJob] Downloaded #{(downloaded_size / 1.megabyte.to_f).round(2)}MB for document ##{document_id}"

        # Scan with ClamAV
        result = ClamavServices.scan_file(tempfile.path)

        case result[:status]
        when :clean
          document.update_column(:scan_status, "clean")
          Rails.logger.info "[ScanJob] Document ##{document_id} is clean"
          broadcast_scan_result(document, "clean")
        when :infected
          Rails.logger.warn "[ScanJob] Document ##{document_id} is INFECTED: #{result[:message]}"
          document.update_column(:scan_status, "infected")
          document.file.purge
          Rails.logger.warn "[ScanJob] Purged infected file for document ##{document_id}"
          broadcast_scan_result(document, "infected", result[:message])
        when :error
          Rails.logger.error "[ScanJob] ClamAV error for document ##{document_id}: #{result[:message]}"
          document.update_column(:scan_status, "scan_error")
          broadcast_scan_result(document, "scan_error", result[:message])
        end
      ensure
        tempfile.unlink if tempfile
      end
    rescue ScanRetryError
      raise # Let retry_on handle it
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "[ScanJob] Document ##{document_id} not found"
    rescue => e
      Rails.logger.error "[ScanJob] Failed for document ##{document_id}: #{e.class} - #{e.message}"
      # Wrap unexpected errors as retryable
      raise ScanRetryError, "#{e.class}: #{e.message}"
    end

    private

    def broadcast_scan_result(document, status, message = nil)
      payload = {
        event: "scan_complete",
        document_id: document.id,
        scan_status: status,
        document_name: document.name,
        message: message
      }

      # Broadcast to document-specific channel
      ActionCable.server.broadcast("document_scan_#{document.id}", payload)

      # Broadcast to folder-specific channel so all viewers of the folder get notified
      if document.folder_id.present?
        ActionCable.server.broadcast("document_scan_folder_#{document.folder_id}", payload)
      end

      Rails.logger.info "[ScanJob] Broadcast scan result for document ##{document.id}: #{status}"
    rescue => e
      Rails.logger.error "[ScanJob] Failed to broadcast for document ##{document.id}: #{e.message}"
    end
  end
end
