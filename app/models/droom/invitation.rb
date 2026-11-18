module Droom
  class Invitation < Droom::DroomRecord
        
    belongs_to :user
    belongs_to :event, touch: true
    belongs_to :group_invitation
    belongs_to :created_by, :class_name => "User"

    after_create :link_folder
    after_destroy :unlink_folder

    validates_uniqueness_of :user_id, :scope => [:event_id, :group_invitation_id]

    scope :to_event, -> event {
      where(["event_id = ?", event.id])
    }
    
    scope :for_user, -> user {
      where("droom_invitations.user_id = ?", user.id)
    }
    
    scope :future, -> {
      select('droom_invitations.*')
        .joins('inner join droom_events as de on droom_invitations.event_id = de.id')
        .where(['de.start > :now', :now => Time.now])
        .group('droom_invitations.id')
    }
    
    scope :refused, -> { where("response < 1") }
    scope :accepted, -> { where("response > 1") }
    scope :not_refused, -> { where("response > 0") }
    scope :not_accepted, -> { where("response < 2") }
    scope :responded, -> { where("response <> 1") }
    scope :not_responded,-> {  where("response == 1") }
  
    def link_folder
      user.add_personal_folders(event.folder)
    end
    
    def unlink_folder
      user.remove_personal_folders(event.folder) if user
    end
    
    def status
      if response < 1
        "refused"
      elsif response == 1
        "maybe"
      else
        "accepted"
      end
    end
    
    def accepted?
      response && response > 1
    end

    def refused?
      response && response < 1
    end
  
  end
end