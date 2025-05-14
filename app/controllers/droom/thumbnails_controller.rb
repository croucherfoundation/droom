module Droom
  class ThumbnailsController < Droom::DroomController
    respond_to :html, :js, :json

    load_resource :event, class: 'Droom::Event'
    load_and_authorize_resource :thumbnail, class: 'Droom::Thumbnail', through: :event, :shallow => true

    def reposition
      reordered_items = reposition_params
      return head :bad_request if reordered_items.blank?

      ActiveRecord::Base.transaction do
        reordered_items.each do |item|
          id = item[:id]
          position = item[:position]

          thumb = @event.thumbnails.find(id)

          thumb.single_document&.update!(position: position)
          thumb.update!(position: position)
        end
      end

      head :ok

    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      Rails.logger.error "Reposition failed: #{e.message}"
      head :unprocessable_entity
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

    private

    def reposition_params
      params[:reordered_items].map do |item|
        item.permit(:id, :position)
      end
    end
  end
end
