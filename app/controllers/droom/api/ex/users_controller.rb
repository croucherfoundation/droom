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
      query = params[:q].to_s.strip
      @users = Droom::User.none and return if query.blank?

      @users = Droom::User.search query,
                                  page: 1,
                                  per_page: 10,
                                  order: {_score: :desc}
    rescue StandardError => e
      # Keep suggest endpoint responsive when Searchkick/ES is unavailable.
      Rails.logger.warn("[api/ex/users#suggest] search fallback: #{e.class}: #{e.message}")
      @users = Droom::User.matching(query).limit(10)
    end

  end
end
