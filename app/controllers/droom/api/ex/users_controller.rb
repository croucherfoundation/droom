module Droom::Api::Ex
  class UsersController < Droom::Api::Ex::ApiController
    load_and_authorize_resource class: "Droom::User"

    before_action :search_users, only: [:suggest]

    def suggest
      render json: @users, each_serializer: Droom::Api::Ex::UserSerializer
    end

    private

    def search_users
      return unless params[:q]

      @users = Droom::User.search params[:q],
                                  page: 1,
                                  per_page: 10,
                                  order: {_score: :desc}, load: false
    end

  end
end
