module Droom
  class LinksController < Droom::DroomController
    respond_to :html, :json, :js
    load_and_authorize_resource

    def index
      @links = Link.all
      render :partial => 'droom/folders/links'
    end

    def show
      respond_with @link do |format|
        format.js {
          render :partial => 'droom/links/link'
        }
      end
    end

    def new
      respond_with @link
    end

    def create
      @link.update(link_params)
      respond_with @link do |format|
        format.js { render :partial => "droom/links/link" }
      end
    end

    def edit
      respond_with @link
    end

    def update
      @link.assign_attributes(link_params)
      @link.save
      respond_with @link do |format|
        format.js { render :partial => "droom/links/link" }
      end
    end

    def destroy
      @link.destroy
      head :ok
    end

  protected

    def link_params
      params.require(:link).permit(:name, :url)
    end
  end
end
