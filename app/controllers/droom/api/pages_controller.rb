module Droom::Api
  class PagesController < Droom::Api::ApiAssetsController
    before_action :set_access_control_headers
    skip_before_action :authenticate_user!

    def index
      @pages = Droom::Page.published
      render_api_success(resource: @pages, each_serializer: Droom::PageSerializer)
    end

    def show
      if @page = Droom::Page.published.find_by(slug: params[:id])
        authenticate_user! unless @page.public?
        return_page
      else
        raise ActiveRecord::RecordNotFound, "No such page."
      end
    end

    def return_page
      render_api_success(resource: @page, serializer: Droom::PageSerializer)
    end

    def return_errors
      render_api_error(errors: @page.errors, status: :unprocessable_entity)
    end

  end
end