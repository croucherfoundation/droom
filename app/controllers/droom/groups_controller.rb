module Droom
  class GroupsController < Droom::DroomController
    respond_to :html, :js
    layout 'centered', only: :index

    before_action :get_groups, :only => [:index, :reposition]
    load_and_authorize_resource

    def index
      respond_with @groups do |format|
        format.js {
          render :partial => 'droom/groups/groups'
        }
      end
    end

    def new
      respond_with @group
    end

    def show
      @users = paginated(@group.users, 20)
      respond_with @group do |format|
        format.js {
          render :partial => 'droom/groups/users'
        }
      end
    end

    def edit
      respond_with @group
    end

    def update
      @group.update(group_params)
      render :partial => 'group'
    end

    def create
      if @group.update(group_params)
        render :partial => "created"
      else
        respond_with @group
      end
    end

    def reposition
      if request.post?
        groups_data = JSON.parse(params[:groups])

        Droom::Group.transaction do
          groups_data.each do |group_data|
            group = Droom::Group.find(group_data['id'])
            group.update_column(:position, group_data['position'])
          end
        end

        head :ok
      end
    end

    def destroy
      @group.destroy
      head :ok
    end

  protected

    def group_params
      params.require(:group).permit(:name, :leader_id, :description, :directory, :privileged)
    end

    def get_groups
      @groups = Droom::Group.shown_in_directory.accessible_by(current_ability).reorder(:position)
    end

  end
end
