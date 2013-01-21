module Droom
  class Invitation < ActiveRecord::Base
    attr_accessible :event_id, :person_id
        
    belongs_to :person
    belongs_to :event
    belongs_to :group_invitation
    belongs_to :created_by, :class_name => "User"

    after_create :link_folder
    after_destroy :unlink_folder

    validates_uniqueness_of :person_id, :scope => [:event_id, :group_invitation_id]

    scope :to_event, lambda { |event|
      where(["event_id = ?", event.id])
    }
  
    def link_folder
      person.add_personal_folders(event.folder)
    end
    
    def unlink_folder
      person.remove_personal_folders(event.folder)
    end

  end
end