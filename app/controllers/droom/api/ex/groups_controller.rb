module Droom::Api::Ex
  class GroupsController < Droom::Api::Ex::ApiController
    load_and_authorize_resource class: "Droom::Group"

    before_action :get_groups, only: [:index]

    def index
      render_api_success(resource: @groups, each_serializer: Droom::Api::Ex::GroupSerializer)
    end

    private

    def get_groups
      @groups = Droom::Group.shown_in_directory.reorder(:name)
    end

  end
end
