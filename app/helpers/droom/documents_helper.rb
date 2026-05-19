module Droom
  module DocumentsHelper
    DOCUMENT_VIEW_CONFIGS = {
      'google_doc' => { name_key: 'google_doc_name', link_field: :google_doc_link, link_key: 'google_doc_link', extension: 'gdoc', symbol: 'google_doc_symbol' },
      'memo_page' => { name_key: 'memo_page_name', link_field: :memo_page_link, link_key: 'memo_page_link', extension: 'memo', symbol: 'memo_symbol' },
      'notion_page' => { name_key: 'notion_page_name', link_field: :notion_page_link, link_key: 'notion_page_link', extension: 'notion', symbol: 'notion_symbol' }
    }.freeze

    def document_link_view?(view)
      DOCUMENT_VIEW_CONFIGS.key?(view)
    end

    def document_view_config(view)
      DOCUMENT_VIEW_CONFIGS[view]
    end

    def document_has_external_link?(document)
      document.google_doc_link.present? || document.notion_page_link.present? || document.memo_page_link.present?
    end

    def document_external_link_info(document)
      DOCUMENT_VIEW_CONFIGS.each do |view, config|
        link_value = document.send(config[:link_field])
        return { url: link_value, extension: config[:extension], symbol: config[:symbol], view: view } if link_value.present?
      end
      nil
    end
  end
end
