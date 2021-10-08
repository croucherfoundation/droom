module Droom::Api
  class VideosController < Droom::Api::ApiAssetsController

    before_action :get_videos, only: [:index]
    before_action :build_user_video, only: [:new, :create]
    load_and_authorize_resource class: "Droom::Video", except: [:index, :new, :create]

    def index
      render json: Droom::VideoSerializer.new(@videos)
    end

    def show
      return_video
    end

    def update
      if @video.update(video_params)
        return_video
      else
        return_errors
      end
    end

    def create
      if @video.save
        return_video
      else
        return_errors
      end
    end

    def destroy
      @video.destroy
      head :ok
    end

    def return_video
      render json: Droom::VideoSerializer.new(@video)
    end

    def return_errors
      render json: {
        errors: @video.errors.to_a
      }
    end

  protected

    def get_videos
      if current_user.admin?
        @videos = Droom::Video.order(created_at: :desc)
      elsif current_user.organisation
        @videos = paginated(current_user.organisation.videos.order(created_at: :desc))
      else
        @videos = paginated(current_user.videos.order(created_at: :desc))
      end
    end

    def build_user_video
      @video = Droom::Video.new video_params.merge(user: current_user, organisation: current_user.organisation)
    end


    def video_params
      params.require(:video).permit(:file, :file_name, :remote_url, :caption)
    end

  end
end
