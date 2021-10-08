module Droom::Api
  class TagsController < Droom::Api::ApiController
    skip_before_action :authenticate_user!
    skip_before_action :check_user_has_organisation
    before_action :search_tags, only: [:index]
    load_resource class: "Droom::Tag"

    def index
      render json: Droom::TagSerializer.new(@tags)
    end

    protected

    def search_tags
      criteria = {}

      if params[:tag_type].present?
        criteria[:tag_type] = params[:tag_type]
      end

      if params[:q].present?
        terms = params[:q]
        order = {_score: :desc}
      else
        terms = "*"
        order = {name: :asc}
      end

      arguments = {
        fields: ["name^5", "synonyms"],
        where: criteria,
        order: order,
        match: :word_start,
        load: false
      }

      if params[:show] != "all"
        arguments[:per_page] = (params[:show].presence || 10).to_i
        arguments[:page] = (params[:page].presence || 1).to_i
      end

      @tags = Droom::Tag.search terms, arguments
    end

  end
end
