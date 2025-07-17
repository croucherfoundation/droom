# This is used in the organisations controller and made available to non-droom classes.

module Droom::Concerns::Searchable
  extend ActiveSupport::Concern

  included do
    before_action :init_pagination, only: [:index], if: :paginated?
    before_action :search_and_sort, only: [:index], if: :searchable?
  end

  protected

  def search_and_sort(preset_options={})
    fields = search_fields
    aggregations = aggregated? ? search_aggregations : []
    @sort ||= params[:sort].presence || search_default_sort

    if @q = preset_options[:q].presence
      preset_options.delete(:q)
      @sort = '_score'
      @searching = false
    elsif @q = params[:q].presence
      @sort = '_score'
      @searching = true
    else
      @q = "*"
      @sort = nil if @sort == '_score'
      @searching = false
    end

    @sort = search_default_sort unless search_permitted_sorts.include?(@sort)
    @order = params[:order].presence || search_descending_sort_defaults.include?(@sort) ? :desc : :asc
    sort_order = [{@sort => {order: @order}}]

    criteria = search_criterion_params.each_with_object({}) do |p, h|
      h[p] = params[p] if params[p].present?
      h[p] = true if h[p] == "true"
      h[p] = false if h[p] == "false"
    end

    criteria.merge!(non_admin_filter) unless admin?

    options = {
      where: criteria,
      order: sort_order
    }
    options.merge!({ per_page: @show, page: @page }) if paginated?
    options[:fields] = fields if fields.any?
    options[:aggs] = aggregations if aggregations.any?
    options[:match] = search_match if search_match
    options[:highlight] = search_highlights if search_highlights
    options[:includes] = search_includes if search_includes
    options[:misspellings] = search_misspellings if search_misspellings
    options.deep_merge!(preset_options)

    klass = controller_path.classify.constantize
    search_results = klass.search @q, **options
    instance_variable_set("@#{controller_name}", search_results)

    if paginated?
      @total = search_results.total_count
    end

    if aggregated?
      @aggs = search_results.aggs
    end
  end

  def search_fields
    []
  end

  def search_highlights
    false
  end

  def search_match
    nil
  end

  def search_misspellings
    {edit_distance: 1}
  end

  def non_admin_filter
    {}
  end

  def search_aggregations
    []
  end

  def search_criterion_params
    []
  end

  def search_permitted_sorts
    ["_score", "name", "title", "created_at"]
  end

  def search_default_sort
    "name"
  end

  def search_descending_sort_defaults
    ["_score", "date", "created_at"]
  end

  def search_includes
    []
  end

  def init_pagination
    @page = (params[:page].presence || 1).to_i
    @show = (params[:per_page].presence || default_per_page).to_i
  end

  def default_per_page
    Settings.defaults.per_page
  end

  def paginated?
    true
  end

  def searchable?
    true
  end

  def aggregated?
    true
  end
end
