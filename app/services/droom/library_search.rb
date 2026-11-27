module Droom
  class LibrarySearch
    PAGE_SIZES = [10, 20, 50, 100].freeze
    TYPES = {'folders' => 'Folders', 'documents' => 'Documents', 'spreadsheets' => 'Spreadsheets', 'images' => 'Images'}.freeze
    PERIODS = {'7d' => 'Last 7 days', '30d' => 'Last 30 days', '365d' => 'Last 12 months'}.freeze

    FILTERS = [[:type, 'Type', TYPES], [:modified, 'Modified', PERIODS]].freeze
    # Elasticsearch defaults to at most 65,536 values per terms clause.
    ID_CHUNK_SIZE = 16_384

    attr_reader :page_size

    def initialize(user:, folders:, documents:, params:)
      @params = params
      @page_size = PAGE_SIZES.find { |size| size.to_s == params[:show] } || 20
      # IDs in the two tables are independent. Keep their type attached in
      # every search, including the aggregations that power People suggestions.
      allowed = {'folder' => folders, 'document' => documents}.flat_map do |kind, scope|
        ids(scope).each_slice(ID_CHUNK_SIZE).map { |chunk| {item_type: kind, id: chunk} }
      end
      @scope = allowed.empty? ? {id: []} : {_or: allowed}
      @scope[:confidential] = false unless user.privileged?
      @since = Time.current
    end

    def results(browsing: false)
      aggs = {type: counts(:type, TYPES.keys), modified: counts(:modified, PERIODS.keys)}
      query(
        page: browsing ? 1 : [@params[:page].to_i, 1].max,
        per_page: browsing ? 0 : page_size,
        body_options: {track_total_hits: true, post_filter: selected_filters, aggs: aggs}
      )
    end

    def filter_fields(results)
      FILTERS.map do |field, title, labels|
        buckets = results.aggs.fetch(field.to_s).fetch('buckets')
        [field, title, labels.map { |value, label| ["#{label} (#{buckets.fetch(value).fetch('doc_count')})", value] }]
      end
    end

    def uploader_visible?(id)
      query(term: '*', per_page: 0, body_options: {post_filter: condition(:user_id, id), track_total_hits: true}).total_count.positive?
    end

    def matching_uploaders(term)
      candidates = User.undeleted.matching(ActiveRecord::Base.sanitize_sql_like(term))
      ids = candidates.pluck(:id)
      return [] if ids.empty?

      chunks = ids.each_slice(ID_CHUNK_SIZE).map { |chunk| {terms: {created_by_id: chunk}} }
      candidates_filter = {bool: {should: chunks}}
      options = {field: 'created_by_id', size: 10, order: {_key: :asc}}
      filters = {bool: {filter: [selected_filters(except: :user_id), candidates_filter]}}
      aggs = {people: {filter: filters, aggs: {uploaders: {terms: options}}}}
      buckets = query(per_page: 0, body_options: {aggs: aggs}).aggs.fetch('people').fetch('uploaders').fetch('buckets')
      candidates.where(id: buckets.pluck('key')).sort_by(&:formal_name)
    end

    private

    def ids(scope)
      scope.except(:includes, :order).distinct.pluck(scope.klass.arel_table[:id])
    end

    def query(term: @params[:q].to_s.strip.presence || '*', **options)
      Searchkick.search(term, models: [Folder, Document],
                        fields: ['name^10', 'filename^5'], where: @scope, order: {_score: :desc}, **options)
    end

    def counts(field, values)
      buckets = values.index_with do |value|
        {bool: {filter: [selected_filters(except: field), condition(field, value)]}}
      end
      {filters: {filters: buckets}}
    end

    def selected_filters(except: nil)
      filters = %i[type modified user_id].filter_map do |field|
        condition(field, @params[field]) if field != except && @params[field].present?
      end
      filters.empty? ? {match_all: {}} : {bool: {filter: filters}}
    end

    def condition(field, value)
      case field
      when :type
        return {term: {item_type: 'folder'}} if value == 'folders'
        types = Document::CONTENT_TYPE_GROUPS[value]
        types ? {terms: {file_content_type: types}} : {match_none: {}}
      when :modified
        return {match_none: {}} unless PERIODS.key?(value)
        {range: {modified_at: {gte: value.to_i.days.ago(@since).iso8601(6)}}}
      when :user_id
        {term: {created_by_id: value.to_i}}
      end
    end
  end
end
