module Droom
  class GroupPermissionsController < Droom::DroomController
    respond_to :js, :html

    load_and_authorize_resource :group, :class => Droom::Group
    load_and_authorize_resource :group_permission, :through => :group, :class => Droom::GroupPermission

    def create
      @group_permission.save
      render :partial => 'droom/group_permissions/toggle'
    end

    def upsert
      @group_permission = Droom::GroupPermission.find_or_initialize_by(group_permission_params)
      @group_permission.delete_permissions(params[:read_only], params[:read_event_documents_only])
      @group_permission.save

      html_tag = "<a class=#{params[:classname]} id=#{params[:linkid]}></a>"
      render html: html_tag.html_safe
    end

    def delete_by_ids
      get_gp_permissions(group_permission_params)
      @group_permission.try(:destroy_all)
      @read_group_permission.try(:destroy_all)
      @read_event_documents_group_permission.try(:destroy_all)

      html_tag = "<a class=#{params[:classname]} id=#{params[:linkid]}></a>"
      render html: html_tag.html_safe
    end

    def destroy
      @group_permission.destroy
      render :partial => 'droom/group_permissions/toggle'
    end

  protected

    def group_permission_params
      params.require(:group_permission).permit(:permission_id, :group_id)
    end

    def get_gp_permissions(params)
      gp_klass = Droom::GroupPermission
      perm_klass = Droom::Permission

      permission = perm_klass.find(params[:permission_id])
      read_permission = permission.get_read_permission
      read_event_documents_permission = permission.get_read_event_documents_permission

      @group_permission = gp_klass.where(params)
      unless @group_permission.present?
        params[:permission_id] = read_permission.id
        @read_group_permission = gp_klass.where(params)
        @read_event_documents_group_permission = gp_klass.where(permission_id: read_event_documents_permission.id) if read_event_documents_permission
      end
    end

  end
end
