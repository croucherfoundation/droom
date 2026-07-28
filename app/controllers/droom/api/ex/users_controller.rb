module Droom::Api::Ex
  class UsersController < Droom::Api::Ex::ApiController
    skip_before_action :assert_local_request!
    load_and_authorize_resource class: "Droom::User"

    before_action :search_users, only: [:suggest]

    def suggest
      render_api_success(resource: @users, each_serializer: Droom::Api::Ex::UserSerializer)
    end

    def profile
      render_api_success(resource: current_user, serializer: Droom::Api::Ex::UserSerializer)
    end

    private

    def search_users
      return unless params[:q]

      @users = Droom::User.search params[:q],
                                  page: 1,
                                  per_page: 10,
                                  order: {_score: :desc}
    end

  end
end
