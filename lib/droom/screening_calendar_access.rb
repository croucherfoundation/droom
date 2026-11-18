module Droom
  module ScreeningCalendarAccess
    def self.authorized_staff?(user)
      user.admin? || (user.staff? && (user.permitted?('droom.calendar') || user.permitted?('droom.calendar.read')))
    end

    def self.visible_to?(event, user)
      user && user.data_room_user? && (authorized_staff?(user) || user.invited_to?(event))
    end

    def self.apply(ability, user)
      return unless user.persisted? && user.data_room_user?

      type_ids = Droom::EventType.where(slug: "screening").pluck(:id)
      ability.cannot [:create, :update, :destroy], Droom::Event, event_type_id: type_ids
      if authorized_staff?(user)
        ability.can [:read, :past, :calendar, :subscribe], Droom::Event, event_type_id: type_ids
      else
        ability.cannot :manage, Droom::Event, event_type_id: type_ids
        ability.can [:read, :past, :calendar, :subscribe], Droom::Event,
          event_type_id: type_ids, id: user.event_ids
      end
    end
  end
end
