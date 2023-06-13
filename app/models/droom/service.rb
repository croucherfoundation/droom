module Droom
  class Service < Droom::DroomRecord
    has_many :permissions, -> {order(:position)}, :dependent => :destroy
    before_save :set_slug
    after_create :create_basic_permissions
    after_save :update_permissions
    validates :slug, :uniqueness => true
    
    def self.for_selection
      self.order("name asc").map{|f| [f.name, f.id] }
    end
    
  protected
  
    def set_slug
      self.slug ||= name.parameterize
    end
    
    def create_basic_permissions
      unless slug == 'event'
        permissions.create(:name => 'login')
        permissions.create(:name => 'admin')
      end
    end
    
    def update_permissions
      permissions.all.each do |p|
        p.send :set_slug
        p.save
      end
    end
  end
end