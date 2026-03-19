require 'droom'

module Droom
  class ScanDocumentFileJob < ActiveJob::Base
    queue_as :default

    def perform(document_id)
      document = Droom::Document.find_by(id: document_id)
      return unless document
      return unless document.file.attached?
      return unless document.scan_status == "pending"

      Rails.logger.info "🔍 ScanDocumentFileJob: Scanning document ##{document_id} (#{document.name})"

      document.with_local_file do |path|
        result = ClamavServices.scan_file(path)

        case result[:status]
        when :clean
          document.update_column(:scan_status, "clean")
          Rails.logger.info "✅ ScanDocumentFileJob: Document ##{document_id} is clean"
        when :infected
          Rails.logger.warn "🚨 ScanDocumentFileJob: Document ##{document_id} is INFECTED: #{result[:message]}"
          document.update_column(:scan_status, "infected")
          # Purge the infected file and notify
          document.file.purge
          Rails.logger.warn "🗑️ ScanDocumentFileJob: Purged infected file for document ##{document_id}"
        when :error
          Rails.logger.error "❌ ScanDocumentFileJob: Error scanning document ##{document_id}: #{result[:message]}"
          document.update_column(:scan_status, "scan_error")
        end
      end
    rescue => e
      Rails.logger.error "❌ ScanDocumentFileJob: Failed for document ##{document_id}: #{e.message}"
      document&.update_column(:scan_status, "scan_error") if document
    end
  end
end
