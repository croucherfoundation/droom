require 'cgi'

module Droom
  module CalendarDescription
    def description_for(user)
      return description unless user && event_type&.slug == "screening" && user.invited_to?(self)

      user.screening_calendar_descriptions.fetch(uuid)
    end

    def plain_description(user: nil)
      CGI.unescapeHTML(strip_tags(description_for(user)).to_s)
    end
  end
end

