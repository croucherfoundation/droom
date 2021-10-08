module Droom::Api
  class ImagesController < Droom::Api::ApiAssetsController

    before_action :get_images, only: [:index]
    before_action :build_user_image, only: [:new, :create]
    load_and_authorize_resource class: "Droom::Image", except: [:index, :new, :create]

    def index
      render json: Droom::ImageSerializer.new(@images)
    end

    def show
      @image = current_user.images.find(params[:id])
      return_image
    end

    def update
      if @image.update(image_params)
        return_image
      else
        return_errors
      end
    end

    def create
      if @image.save
        return_image
      else
        return_errors
      end
    end

    def destroy
      @image.destroy
      head :ok
    end

    def return_image
      render json: Droom::ImageSerializer.new(@image)
    end

    def return_errors
      render json: {
        errors: @image.errors.to_a
      }
    end

    protected

    def get_images
      if current_user.admin?
        @images = paginated(Droom::Image.order(created_at: :desc))
      elsif current_user.organisation
        @images = paginated(current_user.organisation.images.order(created_at: :desc))
      else
        @images = paginated(current_user.images.order(created_at: :desc))
      end
    end

    def build_user_image
      @image = Droom::Image.new image_params.merge(user: current_user, organisation: current_user.organisation)
    end

    def image_params
      params.require(:image).permit(:file_data, :file_name, :remote_url, :caption)
    end

  end
end
