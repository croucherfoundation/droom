module Droom
  class Ability
    include CanCan::Ability

    def initialize(user)
      user ||= Droom::User.new

      can :create, Droom::Enquiry
      can :read, Droom::Page
      can :read, Droom::Tag

      if user.persisted?
        if user.admin?
          can :manage, :all

        else
          can :update, Droom::User, :id => user.id
          can :new, [Droom::Email, Droom::Phone, Droom::Address], :user_id => user.id
          can :read, :dashboard

          if user.organisation && user.organisation_admin?
            can :manage, Droom::Organisation, id: user.organisation_id
            can :manage, Droom::User, organisation_id: user.organisation_id
          end

          if !Droom.require_internal_organisation? || user.internal?

            if user.data_room_user?
              can :read, :dashboard
              can :index, :suggestions

              # If someone has been allowed to create something, they are generally allowed to edit or remove it.
              # This rule must sit after the user rules because users have no created_by_id column.
              #
              # can :manage, [Droom::Event, Droom::Document, Droom::Scrap], :created_by_id => user.id

              # Then other abilities are determined by permissions. Our permissions are relatively abstract and
              # not closely coupled to Cancan abilities. Here we map them onto more concrete operations.
              #
              if user.permitted?('droom.calendar')
                can :manage, Droom::Event
                can :manage, Droom::EventType
                can :manage, Droom::EventSet
                can :manage, Droom::Venue
                can :manage, Droom::Invitation
                can :manage, Droom::GroupInvitation
                can :manage, Droom::AgendaCategory
              elsif user.permitted?('droom.calendar.read')
                can :read, Droom::Event
                can :read, Droom::EventType
                can :read, Droom::EventSet
                can :read, Droom::Venue
                can :read, Droom::Invitation
                can :read, Droom::GroupInvitation
                can :read, Droom::AgendaCategory
              end

              if user.permitted?('droom.directory')
                can :manage, Droom::Group
                can :manage, Droom::Organisation
                can :manage, Droom::User
              elsif user.permitted?('droom.directory.read')
                can :read, Droom::Group
                can :read, Droom::Organisation
                can :read, Droom::User
              end

              if user.permitted?('droom.library')
                can :manage, Droom::Folder
                can :manage, Droom::Link
                can :manage, Droom::Document
              elsif user.permitted?('droom.library.read')
                can :read, Droom::Folder
                can :read, Droom::Link
                can :read, Droom::Document
              end

              if user.permitted?('droom.stream')
                can :create, Droom::Scrap
                can :read, Droom::Scrap
              elsif user.permitted?('droom.stream.read')
                can :read, Droom::Scrap
              end

              if user.permitted?('droom.enquiry')
                can :manage, Droom::Enquiry
              end

              # Some models are purely administrative.
              #
              can :create, Droom::MailingListMembership

              # Confidential events are visible internally but their documents are only visible to 'privileged' users.
              #
              unless user.privileged?
                cannot :read, Droom::Folder, private: true
                cannot :read, Droom::Document, private: true
              end
            end

          else
            # What can an external user do? Nothing, by default, but the main app can add permissions.

          end
        end

      elsif Droom::registerable?
        can :create, Droom::User
      end
    end
  end
end
