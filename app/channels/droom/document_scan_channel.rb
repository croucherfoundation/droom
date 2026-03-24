module Droom
  class DocumentScanChannel < Channel

    def subscribed
      if params[:document_id].present?
        stream_from "document_scan_#{params[:document_id]}"
        Rails.logger.info "[DocumentScanChannel] Subscribed to document_scan_#{params[:document_id]}"
      elsif params[:folder_id].present?
        stream_from "document_scan_folder_#{params[:folder_id]}"
        Rails.logger.info "[DocumentScanChannel] Subscribed to document_scan_folder_#{params[:folder_id]}"
      else
        reject
      end
    end

    def unsubscribed
      Rails.logger.info "[DocumentScanChannel] Unsubscribed"
    end

  end
end
