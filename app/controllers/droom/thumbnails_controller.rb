module Droom
  class ThumbnailsController < Droom::DroomController
    respond_to :html, :js, :json

    load_resource :event, class: 'Droom::Event'
    load_and_authorize_resource :thumbnail, class: 'Droom::Thumbnail', through: :event, :shallow => true

    def reposition
      @single_document = @event.single_documents.find_by(position: @thumbnail.position)
      @single_document.update(reposition_params) if @single_document
      @thumbnail.update(reposition_params)
      head :ok
    end

    def batch_destroy
      ids = params[:image_ids]
      return head :bad_request if ids.blank?

      thumbnails = @event.thumbnails.where(id: ids)
      single_documents = @event.single_documents.where(position: thumbnails.map(&:position))

      return head :not_found if thumbnails.empty?

      thumbnails.destroy_all
      single_documents&.destroy_all

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
  end
end
