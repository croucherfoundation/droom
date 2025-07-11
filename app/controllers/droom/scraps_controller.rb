module Droom
  class ScrapsController < Droom::DroomController
    respond_to :html, :js, :json, :atom
  
    before_action :get_scraps, :only => [:index]
    before_action :get_scraptype, :only => [:new, :create, :update]
    before_action :build_scrap, :only => [:new, :create]
    load_and_authorize_resource

    def index
      @scraps = paginated(@scraps, 50)
      respond_with(@scraps)
    end
  
    def show
      respond_with(@scrap)
    end

    def new
      respond_with(@scrap)
    end

    def edit
      respond_with(@scrap)
    end

    def update
      if @scrap.update(scrap_params(@scraptype))
        respond_with(@scrap)
      else
        flash[:alert] = @scrap.errors.full_messages.to_sentence
        respond_with(@scrap)
      end
    end

    def create
      if @scrap.update(scrap_params(@scraptype))
        respond_with(@scrap)
      else
        flash[:error] = @scrap.errors.full_messages.to_sentence
        redirect_to droom_scraps_path
      end
    end
  
    def destroy
      @scrap.destroy
      head :ok
    end

  protected

    def get_scraps
      @scraps = paginated(Droom::Scrap.order("created_at DESC") )
    end

    def build_scrap
      @scrap = current_user.scraps.build(scraptype: @scraptype)
    end

    def get_scraptype
      if params[:scrap]
        @scraptype = params[:scrap][:scraptype] if Droom.scrap_types.include?(params[:scrap][:scraptype])
      end
      @scraptype ||= Droom.default_scrap_type
    end

    def scrap_params(scraptype=@scraptype)
      case scraptype.to_sym
      when :image then params.require(:scrap).permit(:name, :image, :body, :note, :url, :scraptype, :size)
      when :video then params.require(:scrap).permit(:name, :youtube_id, :note, :url, :scraptype, :size)
      when :link then params.require(:scrap).permit(:name, :body, :note, :url, :scraptype, :size)
      when :event then params.require(:scrap).permit(:name, :body, :note, :url, :scraptype, :size, :event_attributes => [:id, :calendar_id, :start])
      when :document then params.require(:scrap).permit(:name, :body, :note, :url, :scraptype, :size, :document_attributes => [:id, :file, :folder_id])
      else params.require(:scrap).permit(:name, :body, :note, :url, :scraptype, :size)
      end
    end

  end
end