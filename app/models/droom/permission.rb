module Droom
  class Permission < Droom::DroomRecord
    belongs_to :service
    has_many :group_permissions, :dependent => :destroy
    has_many :user_permissions, :dependent => :destroy
    acts_as_list :scope => :service_id
    before_save :set_slug

    validates :slug, :uniqueness => true

    def get_read_permission
      self.class.find_by(name: "#{self.name}.read")
    end

    def get_read_event_documents_permission
      self.class.find_by(name: "#{self.name}.read_event_documents")
    end

    def define_permission_color(group_permission, group, read_permission, read_event_documents_permission)
      group_read_permission = Droom::GroupPermission.find_by(group_id: group.id, permission_id: read_permission&.id)
      group_read_event_documents_permission = Droom::GroupPermission.find_by(group_id: group.id, permission_id: read_event_documents_permission&.id)
      color = 'no'
      color = 'read' if group_read_permission && !group_read_permission.destroyed?
      color = 'read-documents' if group_read_event_documents_permission && !group_read_event_documents_permission.destroyed?
      color = 'yes' if group_permission && !group_permission.destroyed?

      color
    end

  protected

    def set_slug
      self.slug = [service.slug, self.name].join('.')
    end
  end
end
