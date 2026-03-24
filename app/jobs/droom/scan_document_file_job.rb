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
          broadcast_scan_result(document, "clean")
        when :infected
          Rails.logger.warn "🚨 ScanDocumentFileJob: Document ##{document_id} is INFECTED: #{result[:message]}"
          document.update_column(:scan_status, "infected")
          # Purge the infected file and notify
          document.file.purge
          Rails.logger.warn "🗑️ ScanDocumentFileJob: Purged infected file for document ##{document_id}"
          broadcast_scan_result(document, "infected", result[:message])
        when :error
          Rails.logger.error "❌ ScanDocumentFileJob: Error scanning document ##{document_id}: #{result[:message]}"
          document.update_column(:scan_status, "scan_error")
          broadcast_scan_result(document, "scan_error", result[:message])
        end
      end
    rescue => e
      Rails.logger.error "❌ ScanDocumentFileJob: Failed for document ##{document_id}: #{e.message}"
      if document
        document.update_column(:scan_status, "scan_error")
        broadcast_scan_result(document, "scan_error", e.message)
      end
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

      Rails.logger.info "📡 Broadcast scan result for document ##{document.id}: #{status}"
    rescue => e
      Rails.logger.error "📡 Failed to broadcast scan result for document ##{document.id}: #{e.message}"
    end
  end
end
