module Droom
  class GroupPermission < Droom::DroomRecord
    belongs_to :group
    belongs_to :permission
    has_many :user_permissions, :dependent => :destroy
    after_save :create_user_permissions

    # This is set up such that a personal permission created by group membership can be deleted
    # while still leaving in place a personal permission that was granted separately.
    #
    def create_user_permissions
      group.users.each do |user|
        create_permission_for(user)
      end
    end

    def delete_permissions(read_only=false, read_event_documents_only=false)
      read_permission = self.permission.get_read_permission
      read_event_documents_permission = self.permission.get_read_event_documents_permission

      read_gp_permissions = self.class.find_by(group_id: self.group_id, permission_id: read_permission.try(:id))
      self.permission_id = read_permission.try(:id) if read_only == 'true'

      read_event_gp_permissions = self.class.find_by(group_id: self.group_id, permission_id: read_event_documents_permission.try(:id))
      self.permission_id = read_event_documents_permission.try(:id) if read_event_documents_only == 'true'

      # delete users permissions
      self.user_permissions.destroy_all
      read_gp_permissions.user_permissions.destroy_all if read_gp_permissions.present?
      read_event_gp_permissions.user_permissions.destroy_all if read_event_gp_permissions.present?
    end

    def create_permission_for(user)
      user_permissions.where(:user_id => user.id, :permission_id => permission.id).first_or_create
    end

    def self.by_group_id
      all.each_with_object({}) do |gp, hash|
        hash[gp.group_id] ||= {}
        hash[gp.group_id][gp.permission.id] = gp
      end
    end

  end
end
