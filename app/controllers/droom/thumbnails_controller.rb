module Droom
  class ThumbnailsController < Droom::DroomController
    respond_to :html, :js, :json

    before_action :get_event
    load_and_authorize_resource :thumbnail, :class => Droom::Thumbnail, :through => :event, :shallow => true

    def reposition
      @single_document = @event.single_documents.find_by(position: @thumbnail.position)
      @single_document.update(reposition_params) if @single_document
      @thumbnail.update(reposition_params)
      head :ok
    end

    def destroy
      @thumbnail.destroy
      @event.single_documents.find_by(position: @thumbnail.position).try(:destroy)
      head :ok
    end

  protected

    def reposition_params
      if params[:thumbnail]
        params.require(:thumbnail).permit(:position, :event_id)
      else
        {}
      end
    end

    def get_event
      @event = Droom::Event.find(params[:event_id])
    end

  end
end
