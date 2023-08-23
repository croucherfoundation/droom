module Droom
  class DeindexWikiDocumentJob < ActiveJob::Base

    def perform(folder_id, document_id)
      url = "#{Settings.url}/folders/#{folder_id}/documents/#{document_id}"
      WikiDocument.deindex_document(url)
    end

  end
end