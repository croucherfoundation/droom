module Droom
  class PagesController < Droom::DroomController
    respond_to :html
    load_and_authorize_resource except: [:published]
    skip_before_action :authenticate_user!, only: [:published]

    def new
      @page = Droom::Page.new(slug: params[:slug])
      render layout: Droom.page_layout
    end

    def show
      render layout: Droom.page_layout
    end

    def edit
      render layout: Droom.page_layout
    end

    def create
      if @page.update(page_params)
        set_create_notice(@page)
        redirect_to droom.page_url(@page)
      else
        set_alert(@page)
        render action: :new
      end
    end

    def update
      if @page.update(page_params)
        set_update_notice(@page)
        redirect_to droom.page_url(@page)
      else
        set_alert(@page)
        render action: :edit
      end
    end

    def publish
      @page.publish!
      set_update_notice(@page)
      redirect_to droom.published_page_url(@page.slug)
    end

    def destroy
      @page.destroy
      set_delete_notice(@page)
      redirect_to droom.pages_url
    end

    # NB authored page can override built-in page template if it takes that slug.
    #
    def published
      if @page = Droom::Page.published.find_by(slug: params[:slug])
        authenticate_user! unless @page.public?
        render layout: Droom.page_layout

      elsif lookup_context.exists?(params[:slug], 'pages', false)
        render template: "pages/#{params[:slug]}", layout: Droom.page_layout

      elsif can?(:create, Droom::Page)
        redirect_to droom.new_page_url(slug: params[:slug])

      else
        raise ActiveRecord::RecordNotFound, "No such page."
      end
    end

  protected

    def page_params
      params.require(:page).permit(:title, :subtitle, :intro, :content, :public, :slug, :main_image_id, :main_image_caption, :main_image_weighting, :publish_now)
    end

  end
end
