module Droom
  class FavouritesController < Droom::DroomController
    before_action :authenticate_user!

    def create
      klass = params[:favouritable_type].safe_constantize
      raise ActiveRecord::RecordNotFound unless klass && %w[Droom::Document Droom::Folder].include?(klass.to_s)
      record = klass.find(params[:favouritable_id])
      authorize! :read, record

      favourite = current_user.favourites.find_or_initialize_by(
        favouritable_type: klass.to_s,
        favouritable_id: record.id
      )
      favourite.save if favourite.new_record?

      render json: { id: favourite.id, favourited: true }
    end

    def destroy
      favourite = current_user.favourites.find(params[:id])
      favourite.destroy
      render json: { favourited: false }
    end
  end
end
