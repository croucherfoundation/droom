module Droom
  class CompileMeetingPdfJob < ActiveJob::Base

    def perform(event_id)
      return unless event_id

      @event = Droom::Event.find(event_id)
      @event.process_attached_documents
    end

  end
end
