require 'droom'

module Droom
  class IndexWikiDocumentJob < ActiveJob::Base

    def perform(id)
      if doc = Droom::Document.find(id)  
        doc.wiki_reindex  
      end
    end

  end
end