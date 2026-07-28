module Droom::Api
  class ImagesController < Droom::Api::ApiAssetsController

    before_action :get_images, only: [:index]
    before_action :build_user_image, only: [:new, :create]
    load_and_authorize_resource class: "Droom::Image", except: [:index, :new, :create]

    def index
      render_api_success(resource: @images, each_serializer: Droom::ImageSerializer)
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
      if @image.destroy
        render_api_success
      else
        return_errors
      end
    end

    def return_image
      render_api_success(resource: @image, serializer: Droom::ImageSerializer)
    end

    def return_errors
      render_api_error(errors: @image.errors, status: :unprocessable_entity)
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