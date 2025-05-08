module Droom
  class CompileMeetingPdfJob < ActiveJob::Base
    def perform(document_id, event_id)
      return unless document_id && event_id

      event = Droom::Event.find_by(id: event_id)
      return unless event

      event.single_documents.where(document_id: document_id).destroy_all
      event.thumbnails.where(document_id: document_id).destroy_all

      event.process_attached_documents(doc_id: document_id)
    end
  end
end
