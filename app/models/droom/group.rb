module Droom
  class Group < Droom::DroomRecord
    include Droom::Concerns::Slugged
    include Droom::RichText::OptIn

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :leader, :class_name => 'Droom::User'

    has_folder

    has_many :group_invitations, :dependent => :destroy
    has_many :events, -> { distinct }, :through => :group_invitations

    has_many :memberships, :dependent => :destroy
    has_many :users, -> { distinct.order("family_name ASC, given_name ASC") }, :through => :memberships

    has_many :group_permissions, :dependent => :destroy
    has_many :permissions, -> { distinct }, :through => :group_permissions
    
    rich_text_attributes :description
    before_validation :sanitize_rich_text_attributes!, if: -> { description.present? }

    before_validation :slug_from_name
    before_validation :ensure_mailing_list_name

    validates :slug, :uniqueness => true, :presence => true
    validates :mailing_list_name, :uniqueness => true, :presence => true

    def self.highlight_fields
      [:name, :description]
    end

    scope :all_private, -> { where("private = 1") }
    scope :not_private, -> { where("private <> 1 OR private IS NULL") }
    scope :all_public, -> { where("public = 1 AND private <> 1 OR private IS NULL") }
    scope :not_public, -> { where("public <> 1 OR private = 1)") }

    scope :visible_to, -> user {
      if user
        if user.admin?
          scoped({})
        else
          select('droom_groups.*')
            .joins('INNER JOIN droom_memberships as dm on droom_groups.id = dm.group_id')
            .where(['dm.user_id = ?', user.id])
            .group('droom_groups.id')
        end
      else
        where("1=0")
      end
    }

    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_groups.name like ?', fragment)
    }

    scope :not_shown_in_directory, -> {
      where(directory: false)
    }

    scope :shown_in_directory, -> {
      where(directory: true)
    }

    scope :privileged, -> {
      where(privileged: true)
    }
    
    default_scope -> { order("droom_groups.created_at ASC") }

    def admit(users)
      users = *[users].flatten
      self.users << users
    end

    def attach(doc)
      # self.documents << doc
    end

    def membership_for(user)
      self.memberships.for(user).first
    end

    def invite_to(event)
      group_invitations.where(event_id: event.id).first_or_create
    end

    def uninvite_from(event)
      group_invitation = group_invitations.find_by(event_id: event.id)
      group_invitation.invitations.to_event(event).each do |invitation|
        invitation.destroy!
      end
      group_invitation.destroy!
    end

    def invited_to?(event)
      group_invitations.to_event(event).any?
    end

    def as_suggestion
      {
        :type => 'group',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

  protected

    def ensure_mailing_list_name
      ensure_presence_of_unique(:mailing_list_name, slug)
    end
  end
end
